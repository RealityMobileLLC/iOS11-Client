//
//  SystemUris.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The URIs used to locate RealityVision resources for the current server.
 */
@interface SystemUris : NSObject <NSCoding>

/**
 *  The URI for the Catalog Service's RESTful interface.
 */
@property (strong, nonatomic,readonly) NSURL * catalogServiceRest;

/**
 *  The URI for the Command Notification service.
 */
@property (strong, nonatomic,readonly) NSURL * commandNotificationServer;

/**
 *  The URI for the Configuration Service.
 */
@property (strong, nonatomic,readonly) NSURL * configuration;

/**
 *  The URI for the Configuration Service's RESTful interface.
 */
@property (strong, nonatomic,readonly) NSURL * configurationRest;

/**
 *  The URI used for downloading.
 */
@property (strong, nonatomic,readonly) NSURL * defaultDownloadBase;

/**
 *  The URI for Messaging and Routing's interface.
 */
@property (strong, nonatomic,readonly) NSURL * messagingAndRouting;

/**
 *  The URI for Messaging and Routing's RESTful interface.
 */
@property (strong, nonatomic,readonly) NSURL * messagingAndRoutingRest;

/**
 *  The URI for the Video Streaming service.
 */
@property (strong, nonatomic,readonly) NSURL * videoStreamingBase;

/**
 *  The URI for the Video Server Plug-ins.
 */
@property (strong, nonatomic,readonly) NSURL * videoSourceBase;

/**
 *  The URI for the Video Proxy service.
 */
@property (strong, nonatomic,readonly) NSURL * videoProxy;

/**
 *  The URI for the Video Proxy Viewer service.
 */
@property (strong, nonatomic,readonly) NSURL * videoProxyViewerBase;

/**
 *  The URI for the Video Proxy's Pan-Tilt-Zoom service.
 */
@property (strong, nonatomic,readonly) NSURL * videoProxyPtzBase;

/**
 *  Initializes a SystemUris object from a dictionary of name/value
 *  pairs.
 *
 *  @param uriDictionary Dictionary containing the system URIs.
 *
 *  @return An initialized SystemUris object or nil if the object
 *          could not be initialized.
 */
- (id)initFromUriDictionary:(NSDictionary *)uriDictionary;

@end
