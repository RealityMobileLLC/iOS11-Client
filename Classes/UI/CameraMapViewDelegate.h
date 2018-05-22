//
//  CameraMapViewDelegate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CameraInfoWrapper;


/**
 *  An MKMapViewDelegate used to show camera locations on a map.
 */
@interface CameraMapViewDelegate : NSObject <MKMapViewDelegate>

/**
 *  Indicates whether the map should remain centered on the user's location.
 */
@property (nonatomic) BOOL centerOnUserLocation;

/**
 *  Indicates whether the map should remain centered on the currently displayed cameras.
 */
@property (nonatomic) BOOL centerOnCameras;

/**
 *  Specifies a delegate to forward mapView:regionDidChangeAnimated: messages.
 *  
 *  @todo probably not the best way to do this but it works for now (use eventing?)
 */
@property (nonatomic,weak) id <MKMapViewDelegate> mapViewRegionDidChangeDelegate;

/**
 *  Places any cameras that have a location on the map view.
 *
 *  @param cameras Array of cameras to place on map.
 *  @param mapView Map view on which to place the camera locations.
 *  @return YES if any of the cameras had a location
 */
- (BOOL)addCameras:(NSArray *)cameras toMap:(MKMapView *)mapView;

/**
 *  Removes the cameras from the map view.
 *  
 *  @param cameras Array of cameras to remove.
 *  @param mapView Map view that is showing the cameras.
 */
- (void)removeCameras:(NSArray *)cameras fromMap:(MKMapView *)mapView;

/**
 *  Updates changed cameras on the map view.
 *  
 *  @param cameras Array of cameras to update.
 *  @param mapView Map view that is showing the cameras.
 */
- (void)updateCameras:(NSArray *)cameras onMap:(MKMapView *)mapView;

/**
 *  Centers the map on all currently displayed cameras.
 */
- (void)zoomToCamerasOnMap:(MKMapView *)mapView;

/**
 *  Centers the map on the given location.
 */
- (void)zoomToLocation:(CLLocation *)location onMap:(MKMapView *)mapView;

/**
 *  Returns a View Controller to show details for the given camera.
 */
- (UIViewController *)detailViewControllerForCamera:(CameraInfoWrapper *)camera;

@end
