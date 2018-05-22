//
//  CallConfigurationService.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/23/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "WebService.h"
#import "SipEndPoint.h"


/**
 *  Delegate used by the CallConfigurationService class to indicate when web services respond.
 */
@protocol CallConfigurationServiceDelegate 

@optional

/**
 *  Called when a GetChannelList call completes.
 *  
 *  @param channels An array of Channel objects returned by GetChannelList.
 *  @param error The error, if one occurred, or nil if successful.
 */
- (void)onGetChannelListResult:(NSArray *)channels error:(NSError *)error;

/**
 *  Called when a GetSipEndpoint call completes.
 *  
 *  @param endpoint The SipEndPoint object returned by GetSipEndpoint.
 *  @param error The error, if one occurred, or nil if successful.
 */
- (void)onGetSipEndpointResult:(SipEndPoint *)endpoint error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision Call Configuration web service requests.
 */
@interface CallConfigurationService : WebService

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <CallConfigurationServiceDelegate> delegate;

/**
 *  Initializes a CallConfigurationService object.
 *
 *  @param url The base URL for RealityVision web services.
 *  @return An initialized CallConfigurationService object or nil if the object could not be 
 *          initialized.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 *  Initiates a GetChannelList request.
 */
- (void)getChannelList;

/**
 *  Initiates a GetSipEndpoint request.
 *  
 *  @param channel The name of the channel whose endpoint is being requested.
 */
- (void)getSipEndpointForChannel:(NSString *)channelName;

@end
