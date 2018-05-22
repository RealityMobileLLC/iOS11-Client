//
//  PushToTalkCall.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/11/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PttChannelInteractions.h"

@class PttChannel; 


/**
 *  The PushToTalkCallDelegate protocol is used to notify a delegate of PushToTalkCall connection
 *  state changes.
 */
@protocol PushToTalkCallDelegate 

/**
 *  Sent to delegate when a call's connection state has changed.
 *  
 *  @param active Indicates whether the connection is now active.
 */
- (void)pttCallIsActive:(BOOL)active;

/**
 *  Sent to delegate when an attempt to connect has failed.
 *  
 *  @param error An NSError object describing the failure.
 */
- (void)pttCallDidFail:(NSError *)error;

@end


/**
 *  A PushToTalkCall manages a joined Push-To-Talk channel by implementing the 
 *  PttChannelInteractions protocol.
 */
@interface PushToTalkCall : NSObject <PttChannelInteractions>

/**
 *  The delegate to notify when the call's connection state changes or an error occurs.
 */
@property (nonatomic,weak) id <PushToTalkCallDelegate> delegate;

/**
 *  A PttChannel object describing the joined channel.
 */
@property (nonatomic,readonly) PttChannel * channel;

/**
 *  Returns an initialized PushToTalkCall used to manage the given channel.
 *  
 *  @param channel The channel this client will manage.
 */
- (id)initWithChannel:(PttChannel *)channel;

@end
