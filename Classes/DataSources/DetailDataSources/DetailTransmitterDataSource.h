//
//  DetailTransmitterDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/4/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetailDataSource.h"


/**
 *  Provides details for a live user feed for displaying in a table view.
 */
@interface DetailTransmitterDataSource : DetailDataSource 

/**
 *  Initializes a DetailArchiveDataSource for a live user feed.
 *  
 *  @param camera A CameraInfoWrapper that must represent a live user feed (i.e., isTransmitter must be YES).
 */
- (id)initWithCameraDetails:(CameraInfoWrapper *)camera;

@end
