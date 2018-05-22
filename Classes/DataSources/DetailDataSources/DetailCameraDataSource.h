//
//  DetailCameraDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetailDataSource.h"


/**
 *  Provides details for a fixed camera, screencast, or video file for displaying in a table view.
 */
@interface DetailCameraDataSource : DetailDataSource 

/**
 *  Initializes a DetailArchiveDataSource for video feed from the camera catalog.
 *  
 *  @param camera A CameraInfoWrapper that must represent a fixed camera, screencast, or video file.
 */
- (id)initWithCameraDetails:(CameraInfoWrapper *)camera;

@end
