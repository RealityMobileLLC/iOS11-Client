//
//  RvNotification.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/20/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Notification sent when an asynchronous event (such as a push notification) will cause a
 *  new command notification view controller to be displayed.
 */
extern NSString * const RvWillDisplayCommandNotification;


/**
 *  Notification sent to stop video streaming over a cellular network.
 */
extern NSString * const RvStopVideoStreamingNotification;
