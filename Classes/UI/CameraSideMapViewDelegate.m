//
//  CameraSideMapViewDelegate.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "CameraSideMapViewDelegate.h"
#import "CameraInfoWrapper.h"
#import "GpsLockStatus.h"
#import "MapObject.h"
#import "TransmitterInfo.h"
#import "UserDevice.h"
#import "CameraMapAnnotationView.h"
#import "UserMapAnnotationView.h"
#import "RealityVisionMapAnnotationView.h"
#import "Device.h"



@implementation CameraSideMapViewDelegate
{
	CameraInfoWrapper * camera;
	MKMapView * mapView;
	NSArray * removedCameras;
}

- (id)initWithCamera:(CameraInfoWrapper *)theCamera forMapView:(MKMapView *)theMapView
{
    self = [super init];
    if (self != nil)
    {
        camera = theCamera;
        mapView = theMapView;
    }
    return self;
}

- (void)addCameras:(NSArray *)cameras;
{
    NSPredicate * hasLocation = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                                                {
                                                                    if (! [evaluatedObject conformsToProtocol:@protocol(MapObject)])
                                                                        return NO;
                                                                    
                                                                    id <MapObject> item = evaluatedObject;
                                                                    return item.hasLocation && ![self annotationIsCameraBeingViewed:item];
                                                                }];
    
    NSArray * camerasToAdd = [cameras filteredArrayUsingPredicate:hasLocation];
    [mapView addAnnotations:camerasToAdd];
}

- (void)removeCameras:(NSArray *)cameras
{
    NSPredicate * hasLocation = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                 {
                                     return (evaluatedObject != camera) && [mapView.annotations containsObject:evaluatedObject];
                                 }];
    
    NSArray * camerasToRemove = [cameras filteredArrayUsingPredicate:hasLocation];
    [mapView removeAnnotations:camerasToRemove];
}

- (void)removeAllOtherCameras
{
	if (removedCameras == nil && [camera isTransmitter])
	{
		NSPredicate * otherCameras = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings)
									  {
										  return (evaluatedObject != camera);
									  }];
		
		removedCameras = [mapView.annotations filteredArrayUsingPredicate:otherCameras];
		[mapView removeAnnotations:removedCameras];
	}
}

- (void)restoreAllOtherCameras
{
	if (removedCameras)
	{
		[mapView addAnnotations:removedCameras];
		removedCameras = nil;
	}
}

- (void)updateCameras:(NSArray *)cameras
{
	for (id <MapObject> item in cameras)
	{
		if (! [mapView.annotations containsObject:item])
		{
			// item wasn't previously on the map so add it if it has a location
			if ((! [self annotationIsCameraBeingViewed:item]) && item.hasLocation)
			{
				[mapView addAnnotation:item];
			}
		}
		else if (item == camera)
		{
			// the camera being watched has changed state so update its pin color
			[self updatePinColorForAnnotationView:(MKPinAnnotationView *)[mapView viewForAnnotation:camera]];
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
				[self updatePinColorForAnnotationView:annotationView];
			}
		}
	}
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    NSAssert(theMapView==mapView,@"Received map view event for another map");
    
	MKAnnotationView * annotationView = nil;
	
    if (annotation == camera)
	{
        // use a pin for the camera being watched
        static NSString * AnnotationIdentifier = @"CameraPinAnnotationIdentifier";
		annotationView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
		
		if (annotationView == nil)
		{
			annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
															 reuseIdentifier:AnnotationIdentifier];
			annotationView.canShowCallout = YES;
		}
		else
		{
			annotationView.annotation = annotation;
		}
		
		[self updatePinColorForAnnotationView:(MKPinAnnotationView *)annotationView];
	}
    else if ([annotation isKindOfClass:[CameraInfoWrapper class]])
	{
        static NSString * CameraAnnotationIdentifier = @"CameraAnnotationIdentifier";
        CameraInfoWrapper * theCamera = (CameraInfoWrapper *)annotation;
		annotationView = [theMapView dequeueReusableAnnotationViewWithIdentifier:CameraAnnotationIdentifier];
		
		if (annotationView == nil)
		{
			annotationView = [[CameraMapAnnotationView alloc] initWithCamera:theCamera
													   andCalloutAccessories:NO
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
		NSAssert(![camera isTransmitterForUserDevice:userDevice],
				 @"Adding a UserDevice map annotation for the transmitter being viewed. Transmitter is already on map as a pin.");
		
		annotationView = [theMapView dequeueReusableAnnotationViewWithIdentifier:UserAnnotationIdentifier];
		
		if (annotationView == nil)
		{
			annotationView = [[UserMapAnnotationView alloc] initWithUser:userDevice
												   andCalloutAccessories:NO
														 reuseIdentifier:UserAnnotationIdentifier];
		}
		else
		{
			annotationView.annotation = annotation;
		}
		
    }
    
	NSAssert(annotationView,@"Returning a nil annotationview");
    return annotationView;
}

- (void)updatePinColorForAnnotationView:(MKPinAnnotationView *)annotationView
{
    if (camera.isTransmitter)
    {
        TransmitterInfo * transmitter = camera.sourceObject;
        annotationView.pinColor = (transmitter.gpsLockStatus.value == GL_Lock) ? MKPinAnnotationColorGreen : MKPinAnnotationColorPurple;
    }
    else
    {
        annotationView.pinColor = MKPinAnnotationColorGreen;
    }
}

- (BOOL)annotationIsCameraBeingViewed:(id)annotation
{
	if (camera == annotation)
		return YES;
	
	// this assumes that if the annotation is a CameraInfoWrapper, it's only equal if it's the same object
	if (! [annotation isKindOfClass:[UserDevice class]])
		return NO;
	
	return [camera isTransmitterForUserDevice:(UserDevice *)annotation];
}

@end
