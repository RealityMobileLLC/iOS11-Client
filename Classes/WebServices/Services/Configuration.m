//
//  ConfigurationService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "Configuration.h"
#import "XmlFactory.h"
#import "QueryString.h"
#import "ClientServiceInfo.h"
#import "ClientServiceInfoHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation Configuration
{
	id <WebServiceResponseHandler> responseHandler;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithConfigurationUrl:(NSURL *)configurationUrl 
					  delegate:(id <ConnectDelegate>)connectDelegate
{
	self = [super initService:@"Configuration" withUrl:configurationUrl];
	if (self != nil)
	{
		self.delegate = connectDelegate;
        self.sendDeviceId = NO;
	}
	return self;
}


#pragma mark - Public methods

- (void)connect:(NSString *)deviceId 
   capabilities:(NSDictionary *)deviceCapabilities
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId" stringValue:deviceId];
	[query append:@"deviceCapabilities" stringValue:@""];
	
	NSData * data = [XmlFactory dataWithArrayOfNameValueElementNamed:@"deviceCapabilities" dictionary:deviceCapabilities];
	
	responseHandler = [[ClientServiceInfoHandler alloc] init];
	[super postToMethod:@"Connect" query:query.query data:data];
}

- (void)disconnect:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId" stringValue:deviceId];
	
	responseHandler = nil;
	[super getFromMethod:@"Disconnect" query:query.query];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	if (responseHandler == nil)
	{
		// disconnect doesn't provide a response so just log error, if any, and let delegate know we finished
		if (error != nil)
		{
			DDLogWarn(@"Configuration error response: %@", error);
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onDisconnect];
					    });
	}
	else if ([responseHandler isKindOfClass:[ClientServiceInfoHandler class]])
	{
		ClientServiceInfo * clientInfo = nil;
		
		if (error == nil)
		{
			clientInfo = [responseHandler parseResponse:data];
		}
		
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onConnect:clientInfo error:error];
					    });
	}
}

@end
