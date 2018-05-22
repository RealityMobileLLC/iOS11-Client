//
//  DetailArchiveDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/4/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetailDataSource.h"
#import "EnterCommentViewController.h"


/**
 *  Provides details for an archived user feed for displaying in a table view.  Also provides
 *  a means for adding new session and frame comments to the archived feed.
 */
@interface DetailArchiveDataSource : DetailDataSource <EnterCommentDelegate>

/**
 *  Initializes a DetailArchiveDataSource for an archived user feed.
 *  
 *  @param camera A CameraInfoWrapper that must represent an archived user feed (i.e., isArchivedSession must be YES).
 */
- (id)initWithCameraDetails:(CameraInfoWrapper *)camera;

@end
