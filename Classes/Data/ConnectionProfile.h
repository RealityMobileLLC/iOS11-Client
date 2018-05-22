//
//  ConnectionProfile.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Defines the connection settings for a RealityVision server.
 */
@interface ConnectionProfile : NSObject <NSCoding>

/**
 *  The fully qualified host name for the server.
 */
@property (strong, nonatomic,readonly) NSString * host;

/**
 *  The path used to address RealityVision web services.
 */
@property (strong, nonatomic,readonly) NSString * path;

/**
 *  Indicates whether the connection should use SSL.
 */
@property (nonatomic,readonly) BOOL useSsl;

/**
 *  Indicates whether the host name is publicly addressable on the internet.
 *  YES indicates a publicly addressable host.  NO indicates a host name on an
 *  internal network.
 */
@property (nonatomic,readonly) BOOL isExternal;

/**
 *  The port to use for RealityVision web services.
 */
@property (nonatomic,readonly) int port;

/**
 *  The URL used to access the RealityVision server.
 */
@property (strong, nonatomic,readonly) NSURL * url;

/**
 *  Initializes a ConnectionProfile object.
 *
 *  @param host       The fully qualified host name for the server.
 *  @param useSsl     YES if the connection should use SSL.
 *  @param isExternal YES if the given host name is publicly addressable on 
 *                    the internet or NO if it indicates a host name on an
 *                    internal network.
 *  @param port       The port number used for RealityVision web services.
 *  @param path       The path used to address RealityVision web services.
 */
- (id)initWithHost:(NSString *)host 
			useSsl:(BOOL)useSsl
		isExternal:(BOOL)isExternal
			  port:(int)port 
			  path:(NSString *)path;

@end
