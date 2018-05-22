//
//  PttChannelInteractions.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/26/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  PttChannelInteractions defines methods and properties for interactions between a user interface 
 *  and a joined Push-To-Talk channel.  It allows the user interface to be updated based on channel
 *  state changes, and allows the user to interact with the channel.
 */
@protocol PttChannelInteractions <NSObject>

/**
 *  PttChannelStatus defines the connection states for a Push-To-Talk channel.
 */
typedef enum
{
	PttChannelDisconnected,   /**< Channel is disconnected */
	PttChannelConnected,      /**< Channel is connected */
	PttChannelConnecting,     /**< Channel is trying to connect */
	PttChannelDisconnecting   /**< Channel is trying to disconnect */
} PttChannelStatus;

/**
 *  The name of the joined Push-To-Talk channel.
 */
@property (nonatomic,readonly) NSString * channelName;

/**
 *  The current connection status for the channel.
 */
@property (nonatomic,readonly) PttChannelStatus connectionStatus;

/**
 *  Indicates whether channel is muted (i.e., not rendering received audio).
 */
@property (nonatomic) BOOL muted;

/**
 *  Indicates whether channel is talking (i.e., recording and transmitting audio).
 */
@property (nonatomic) BOOL talking;

/**
 *  Starts the asynchronous connect process.
 *  
 *  @return YES if able to start connecting; NO if asynchronous connect process not started
 */
- (BOOL)connect;

/**
 *  Starts the asynchronous disconnect process.
 */
- (void)disconnect;

/**
 *  Sends a DTMF event over the channel.
 */
- (void)sendDtmf:(NSUInteger)dtmfCode;

@end
