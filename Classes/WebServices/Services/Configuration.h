//
//  Configuration.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"
#import "WebServiceResponseHandler.h"

@class ClientServiceInfo;


/**
 *  Delegate used by the Configuration class to indicate when web services
 *  respond.
 */
@protocol ConnectDelegate

/**
 *  Called when a Connect call completes.
 *
 *  @param clientInfo The ClientServiceInfo returned by the Connect service.
 *  @param error      An error, if one occurred, or nil if the operation 
 *                    completed successfully.
 */
- (void)onConnect:(ClientServiceInfo *)clientInfo error:(NSError *)error;

/**
 *  Called when a Disconnect call completes.
 */
- (void)onDisconnect;

@end


/**
 *  Responsible for managing RealityVision Configuration web service requests.
 */
@interface Configuration : WebService

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <ConnectDelegate> delegate;

/**
 *  Initializes a Configuration object.
 *
 *  @param url      The base URL for RealityVision web services.
 *  @param delegate The delegate to notify when a web service responds.
 *
 *  @return An initialized Configuration object or nil if the object could
 *           not be initialized.
 */
- (id)initWithConfigurationUrl:(NSURL *)url 
					  delegate:(id <ConnectDelegate>)delegate;

/**
 *  Initiates a Connect request.
 *
 *  @param deviceId     The client's device ID.
 *  @param capabilities The client's device capabilities.
 */
- (void)connect:(NSString *)deviceId 
   capabilities:(NSDictionary *)capabilities;

/**
 *  Initiates a Disconnect request.
 *
 *  @param deviceId The client's device ID.
 */
- (void)disconnect:(NSString *)deviceId;

@end
