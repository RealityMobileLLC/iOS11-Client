//
//  CameraSideMapViewDelegate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CameraInfoWrapper;


/**
 *  An MKMapViewDelegate used to show camera and user locations on a side map while watching a 
 *  video feed.  The camera being watched is represented as a pin on the map.  Other cameras and 
 *  users are represented using the standard RealityVision icons.
 */
@interface CameraSideMapViewDelegate : NSObject <MKMapViewDelegate>

/**
 *  Initializes a CameraSideMapViewDelegate with the camera being watched.
 */
- (id)initWithCamera:(CameraInfoWrapper *)camera forMapView:(MKMapView *)mapView;

/**
 *  Places any cameras that have a location on the map view.
 *
 *  @param cameras Array of cameras to place on map.
 */
- (void)addCameras:(NSArray *)cameras;

/**
 *  Removes the cameras from the map view.
 *  
 *  @param cameras Array of cameras to remove.
 */
- (void)removeCameras:(NSArray *)cameras;

/**
 *  Updates changed cameras on the map view.
 *  
 *  @param cameras Array of cameras to update.
 */
- (void)updateCameras:(NSArray *)cameras;

/**
 *  Remove all map annotations except for the one representing the current camera.
 *  (Used when watching a live user feed from an archive position)
 */
- (void)removeAllOtherCameras;

/**
 *  Restore all map annotations that were previously removed.  (Used when switching
 *  back to the live position of a live user feed from an archive position)
 */
- (void)restoreAllOtherCameras;

@end
