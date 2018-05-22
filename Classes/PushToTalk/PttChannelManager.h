//
//  PttChannelManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/24/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallConfigurationService.h"


/**
 *  Maintains the list of Push-To-Talk channels available to the signed-on user.
 */
@interface PttChannelManager : NSObject <NSCoding, CallConfigurationServiceDelegate>

/**
 *  An array of Channel objects identifying the available Push-To-Talk channels.
 */
@property (nonatomic,readonly,strong) NSArray * channels;

/**
 *  The name of the currently selected channel.  This is the channel most recently selected
 *  by the user during the current sign-on session.  It is nil if the user is not signed on,
 *  if the user has not selected a channel during the current sign-on session, or if the user
 *  last selected the "off" channel.
 */
@property (nonatomic,strong) NSString * selectedChannel;

/**
 *  Retrieves the list of channels available to the current user.  Note that this is an
 *  asynchronous operation.  The channels array will be updated when it has completed.
 */
- (void)updateChannelList;

/**
 *  Invalidates the list of channels by removing all elements from the channels array and
 *  setting the selectedChannel to nil.
 */
- (void)invalidate;

/**
 *  Returns the singleton instance of the PttChannelManager.
 */
+ (PttChannelManager *)instance;

@end
