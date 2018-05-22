//
//  MapObject.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/22/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class CameraInfoWrapper;


/**
 *  A RealityVision object that can be displayed on a map and/or have an associated video feed.
 *  This includes both cameras and user devices.
 */
@protocol MapObject <NSObject, MKAnnotation>

/**
 *  Indicates whether the object has a valid location.
 */
@property (nonatomic,readonly) BOOL hasLocation;

/**
 *  A CameraInfoWrapper that can be used to access the object's video feed.  If the object
 *  does not have an associated video feed (i.e., a user that is not transmitting), this
 *  returns nil.
 */
@property (nonatomic,readonly) CameraInfoWrapper * camera;

/**
 *  A reference to a camera viewer that can be used to determine if this object's video feed 
 *  is being watched within the client and, if so, to interact with that viewer.
 */
@property (nonatomic,assign) id cameraViewer;

@end
