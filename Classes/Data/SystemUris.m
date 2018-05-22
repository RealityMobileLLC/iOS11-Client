//
//  SystemUris.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SystemUris.h"


static NSString * const KEY_CONFIGURATION_URI = @"ConfigurationURI";
static NSString * const KEY_MESSAGING_URI     = @"MessagingAndRoutingURI";
static NSString * const KEY_CATALOG_URI       = @"CatalogURI";
static NSString * const KEY_CNS_URI           = @"CommandNotificationServer";
static NSString * const KEY_DOWNLOAD_URI      = @"DefaultDownloadBase";
static NSString * const KEY_ROVING_URI        = @"RovingVideoServerURI";
static NSString * const KEY_PROXY_URI         = @"VideoProxyURI";
static NSString * const KEY_SOURCE_URI        = @"VideoSourceBaseURI";

static NSString * const PROXY_JPG = @"stream?uri=";
static NSString * const PROXY_PTZ = @"ptz?uri=";
static NSString * const REST_PATH = @"Rest";


@implementation SystemUris
{
	NSDictionary * uris;
}


#pragma mark - Initialization and cleanup

- (id)initFromUriDictionary:(NSDictionary *)uriDictionary
{
	self = [super init];
	if (self != nil)
	{
		uris = uriDictionary;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
	uris = [coder decodeObjectForKey:@"Values"]; 
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
    [coder encodeObject:uris forKey:@"Values"];
}


#pragma mark - Properties

- (NSURL *)commandNotificationServer
{
	return [NSURL URLWithString:[uris objectForKey:KEY_CNS_URI]];
}

- (NSURL *)configuration
{
	return [NSURL URLWithString:[uris objectForKey:KEY_CONFIGURATION_URI]];
}

- (NSURL *)defaultDownloadBase
{
	return [NSURL URLWithString:[uris objectForKey:KEY_DOWNLOAD_URI]];
}

- (NSURL *)messagingAndRouting
{
	return [NSURL URLWithString:[uris objectForKey:KEY_MESSAGING_URI]];
}

- (NSURL *)videoStreamingBase
{
	return [NSURL URLWithString:[uris objectForKey:KEY_ROVING_URI]];
}

- (NSURL *)videoSourceBase
{
	return [NSURL URLWithString:[uris objectForKey:KEY_SOURCE_URI]];
}

- (NSURL *)videoProxy
{
	return [NSURL URLWithString:[uris objectForKey:KEY_PROXY_URI]];
}

- (NSURL *)videoProxyViewerBase
{
	NSString * baseUri = [uris objectForKey:KEY_PROXY_URI];
	return [SystemUris appendPath:PROXY_JPG toBaseUri:baseUri];
}

- (NSURL *)videoProxyPtzBase
{
	NSString * baseUri = [uris objectForKey:KEY_PROXY_URI];
	return [SystemUris appendPath:PROXY_PTZ toBaseUri:baseUri];
}

- (NSURL *)catalogServiceRest
{
	NSString * baseUri = [uris objectForKey:KEY_CATALOG_URI];
	return [SystemUris appendPath:REST_PATH toBaseUri:baseUri];
}

- (NSURL *)configurationRest
{
	NSString * baseUri = [uris objectForKey:KEY_CONFIGURATION_URI];
	return [SystemUris appendPath:REST_PATH toBaseUri:baseUri];
}

- (NSURL *)messagingAndRoutingRest
{
	NSString * baseUri = [uris objectForKey:KEY_MESSAGING_URI];
	return [SystemUris appendPath:REST_PATH toBaseUri:baseUri];
}


#pragma mark - Private methods

+ (NSURL *)appendPath:(NSString *)path toBaseUri:(NSString *)baseUri
{
	BOOL hasSeparator = ([baseUri characterAtIndex:[baseUri length]-1] == '/');
	NSString * urlBaseString = hasSeparator ? baseUri : [baseUri stringByAppendingString:@"/"];
	return [NSURL URLWithString:[urlBaseString stringByAppendingString:path]];
}

@end
