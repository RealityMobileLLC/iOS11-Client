//
//  CameraMapViewDelegate.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraMapViewDelegate.h"
#import "CameraInfoWrapper.h"
#import "FavoriteEntry.h"
#import "GpsLockStatus.h"
#import "Session.h"
#import "TransmitterInfo.h"
#import "UserDevice.h"
#import "CameraDetailViewController.h"
#import "CameraMapAnnotationView.h"
#import "UserMapAnnotationView.h"
#import "MapObject.h"
#import "DetailArchiveDataSource.h"
#import "DetailCameraDataSource.h"
#import "DetailTransmitterDataSource.h"
#import "RootViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// defines the minimum zoom region for cameras on a map
// at the equator, one degree is ~ 69 miles
static const CLLocationDegrees MIN_LAT_DELTA = 2.0 / 69.0;
static const CLLocationDegrees MIN_LON_DELTA = 2.0 / 69.0;


@implementation CameraMapViewDelegate
{
	BOOL                   haveLocations;
	CLLocationCoordinate2D minLocation;
	CLLocationCoordinate2D maxLocation;
}

@synthesize centerOnUserLocation;
@synthesize centerOnCameras;
@synthesize mapViewRegionDidChangeDelegate;


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		haveLocations = NO;
		minLocation = kCLLocationCoordinate2DInvalid;
		maxLocation = kCLLocationCoordinate2DInvalid;
	}
	return self;
}


#pragma mark - Public methods

- (void)zoomToCamerasOnMap:(MKMapView *)mapView
{
	if (haveLocations)
	{
		// create region centered at the midpoint of min and max
		CLLocationCoordinate2D center = CLLocationCoordinate2DMake((minLocation.latitude  + maxLocation.latitude)  / 2.0, 
																   (minLocation.longitude + maxLocation.longitude) / 2.0);
		
		CLLocationDegrees latitudeDelta  = maxLocation.latitude  - minLocation.latitude;
		CLLocationDegrees longitudeDelta = maxLocation.longitude - minLocation.longitude;
		
		latitudeDelta  = MAX(latitudeDelta, MIN_LAT_DELTA);
		longitudeDelta = MAX(longitudeDelta, MIN_LON_DELTA);
		
		// set map view to show region
		MKCoordinateSpan   span           = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
		MKCoordinateRegion cameraRegion   = MKCoordinateRegionMake(center, span);
		MKCoordinateRegion regionThatFits = [mapView regionThatFits:cameraRegion];
		
		// @todo BUG-3024 regionThatFits: will sometimes return a longitudeDelta = 360.0
		//                if passed to setRegion:animated:, this causes an NSInvalidArgument exception
		//                Problem ID 9876536 https://bugreport.apple.com
        if (regionThatFits.span.longitudeDelta == 360.0)
        {
            DDLogWarn(@"BUG-3024");
        }
        
		static const CLLocationDegrees MAX_LAT_DELTA = 180.0 - FLT_EPSILON;
		static const CLLocationDegrees MAX_LON_DELTA = 360.0 - FLT_EPSILON;
		
		regionThatFits.span.latitudeDelta  = MIN(regionThatFits.span.latitudeDelta,  MAX_LAT_DELTA);
		regionThatFits.span.longitudeDelta = MIN(regionThatFits.span.longitudeDelta, MAX_LON_DELTA);
        
		[mapView setRegion:regionThatFits animated:YES];
	}
}

- (void)zoomToLocation:(CLLocation *)location onMap:(MKMapView *)mapView
{
	MKCoordinateRegion mapRegion = MKCoordinateRegionMake(location.coordinate, 
														  MKCoordinateSpanMake(MIN_LAT_DELTA, MIN_LON_DELTA));
	[mapView setRegion:mapRegion animated:YES];
}

- (BOOL)addCameras:(NSArray *)cameras toMap:(MKMapView *)mapView;
{
	@synchronized(self)
	{
        // only add cameras that have location
        NSPredicate * hasLocation = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                     {
                                         if (! [evaluatedObject conformsToProtocol:@protocol(MapObject)])
                                             return NO;

                                         id <MapObject> item = evaluatedObject;
                                         return item.hasLocation;
                                     }];
        
        NSArray * camerasToAdd = [cameras filteredArrayUsingPredicate:hasLocation];
        [mapView addAnnotations:camerasToAdd];
		[self computeViewableRegionForMap:mapView];
		
		if (centerOnCameras)
		{
			[self zoomToCamerasOnMap:mapView];
		}
	}
    
    return haveLocations;
}

- (void)removeCameras:(NSArray *)cameras fromMap:(MKMapView *)mapView
{
	@synchronized(self)
	{
        // only remove cameras that are already on the map
        NSPredicate * hasLocation = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                     {
                                         return [mapView.annotations containsObject:evaluatedObject];
                                     }];
        
        NSArray * camerasToRemove = [cameras filteredArrayUsingPredicate:hasLocation];
        [mapView removeAnnotations:camerasToRemove];
		[self computeViewableRegionForMap:mapView];
		
		if (centerOnCameras && mapView.annotations != nil && [mapView.annotations count] > 0)
		{
			[self zoomToCamerasOnMap:mapView];
		}
	}
}

- (void)updateCameras:(NSArray *)cameras onMap:(MKMapView *)mapView
{
    @synchronized(self)
    {
        for (id <MapObject> item in cameras) 
        {
            if (! [mapView.annotations containsObject:item])
            {
                // item wasn't previously on the map so add it if it has a location
                if (item.hasLocation)
                {
                    [mapView addAnnotation:item];
                }
            }
            else if (! item.hasLocation)
            {
                // item was on the map but no longer has location data so remove it
                [mapView removeAnnotation:item];
            }
            else
            {
                // item's annotation view needs to be updated
				id annotationView = [mapView viewForAnnotation:item];
				if ([annotationView isKindOfClass:[RealityVisionMapAnnotationView class]])
				{
					[annotationView update];
				}
				else if ([annotationView isKindOfClass:[MKPinAnnotationView class]])
				{
					DDLogWarn(@"CameraMapViewDelegate updateCameras:onMap: unexpected MKPinAnnotationView on map");
				}
            }
        }
		
		[self computeViewableRegionForMap:mapView];
        
        if (centerOnCameras)
        {
            [self zoomToCamerasOnMap:mapView];
        }
    }
}

- (UIViewController *)detailViewControllerForCamera:(CameraInfoWrapper *)camera
{
	DetailDataSource * detailDataSource = nil;
	id cameraSource = camera.sourceObject;
	
	if ([cameraSource isKindOfClass:[TransmitterInfo class]])
	{
		detailDataSource = [[DetailTransmitterDataSource alloc] initWithCameraDetails:camera];
	}
	else if ([cameraSource isKindOfClass:[Session class]])
	{
		detailDataSource = [[DetailArchiveDataSource alloc] initWithCameraDetails:camera];
	}
	else 
	{
		if ([cameraSource isKindOfClass:[FavoriteEntry class]])
		{
			camera = [[CameraInfoWrapper alloc] initWithCamera:camera.cameraInfo];
		}
		
		detailDataSource = [[DetailCameraDataSource alloc] initWithCameraDetails:camera];
	}
	
	CameraDetailViewController * viewController = 
		[[CameraDetailViewController alloc] initWithNibName:@"CameraDetailViewController" 
													  bundle:nil];
	viewController.detailDataSource = detailDataSource;
	return viewController;
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView * annotationView = nil;
	
    if ([annotation isKindOfClass:[CameraInfoWrapper class]])
	{
        static NSString * CameraAnnotationIdentifier = @"CameraAnnotationIdentifier";
        CameraInfoWrapper * camera = (CameraInfoWrapper *)annotation;
		annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:CameraAnnotationIdentifier];
		
		if (annotationView == nil)
		{
			annotationView = [[CameraMapAnnotationView alloc] initWithCamera:camera 
													   andCalloutAccessories:YES 
															 reuseIdentifier:CameraAnnotationIdentifier];
		}
		else
		{
			annotationView.annotation = annotation;
		}
	}
    else if ([annotation isKindOfClass:[UserDevice class]])
    {
        static NSString * UserAnnotationIdentifier = @"UserAnnotationIdentifier";
        UserDevice * userDevice = (UserDevice *)annotation;
		annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:UserAnnotationIdentifier];
		
		if (annotationView == nil)
		{
			annotationView = [[UserMapAnnotationView alloc] initWithUser:userDevice 
												   andCalloutAccessories:YES 
														 reuseIdentifier:UserAnnotationIdentifier];
		}
		else
		{
			annotationView.annotation = annotation;
		}
    }
	else
	{
		DDLogWarn(@"Unrecognized annotation");
	}
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if (control == view.rightCalloutAccessoryView)
    {
		if ([view isKindOfClass:[CameraMapAnnotationView class]])
		{
			// right callout control displays camera details
			CameraMapAnnotationView * cameraAnnotationView = (CameraMapAnnotationView *)view;
			UIViewController * viewController = [self detailViewControllerForCamera:cameraAnnotationView.camera];
			RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
			[appDelegate.navigationController pushViewController:viewController animated:YES];
		}
		else if ([view isKindOfClass:[UserMapAnnotationView class]])
		{
			// right callout control shows list of viewed video feeds
			RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
			[rootViewController showViewedFeedsForAnnotationView:view];
		}
    }
    else if (control == view.leftCalloutAccessoryView)
    {
        // left callout control plays video
        RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
        [rootViewController showVideoForAnnotationView:view];
    }
	else 
	{
		// believe it or not, this shit actually happened
		DDLogError(@"User tapped an unknown accessory control!");
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [mapView deselectAnnotation:view.annotation animated:NO];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
	if (centerOnUserLocation)
	{
		[self zoomToLocation:userLocation.location onMap:mapView];
	}
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	[self.mapViewRegionDidChangeDelegate mapView:mapView regionDidChangeAnimated:animated];
}


#pragma mark - Private methods

- (void)computeViewableRegionForMap:(MKMapView *)mapView
{
    haveLocations = NO;
    
	for (id <MKAnnotation> annotation in mapView.annotations)
	{
        if (! haveLocations)
        {
            minLocation = maxLocation = annotation.coordinate;
            haveLocations = YES;
        }
        else 
        {
            minLocation.latitude  = MIN(annotation.coordinate.latitude,  minLocation.latitude);
            minLocation.longitude = MIN(annotation.coordinate.longitude, minLocation.longitude);
            maxLocation.latitude  = MAX(annotation.coordinate.latitude,  maxLocation.latitude);
            maxLocation.longitude = MAX(annotation.coordinate.longitude, maxLocation.longitude);
        }
	}
}

@end
