//
//  ClientServiceInfo.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A RealityVision ClientServiceInfo object that is returned by the
 *  Connect web service.
 */
@interface ClientServiceInfo : NSObject 

@property (strong, nonatomic) NSString     * deviceId;
@property (nonatomic)         UInt32         newHistoryCount;
@property (strong, nonatomic) NSDictionary * systemUris;
@property (strong, nonatomic) NSDictionary * externalSystemUris;
@property (strong, nonatomic) NSDictionary * clientConfiguration;

/**
 *  Returns an initialized ClientServiceInfo object.
 *  
 *  @param deviceId           The device ID for this client.
 *  @param newHistoryCount    The number of pending commands for this client.
 *  @param systemUris         A dictionary of URIs to be used for internal connections.
 *  @param externalSystemUris A dictionary of URIs to be used for external connections.
 *  @param configuration      A dictionary containing the client configuration.
 */
- (id)initDevice:(NSString *)deviceId 
 newHistoryCount:(UInt32)newHistoryCount 
	  systemUris:(NSDictionary *)systemUris 
	externalUris:(NSDictionary *)externalSystemUris 
   configuration:(NSDictionary *)configuration;

/**
 *  Writes the ClientServiceInfo to the debug log.
 */
- (void)log;

/**
 *  Replace "relative" external system URI addresses that contain a hyphen
 *  with a hostname.  
 *  https://-:443/MessagingAndRouting/ becomes https://connectionProfileName:443/MessagingAndRouting/
 *  
 */
- (void)augmentExternalUrisHostWith:(NSString *) connectionProfileName;

@end
