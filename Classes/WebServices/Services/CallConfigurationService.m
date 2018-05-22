//
//  CallConfigurationService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/23/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "CallConfigurationService.h"
#import "WebServiceResponseHandler.h"
#import "QueryString.h"
#import "ArrayHandler.h"
#import "ChannelHandler.h"
#import "SipEndPointHandler.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CallConfigurationService
{
	id <WebServiceResponseHandler> responseHandler;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)url
{
	self = [super initService:@"CallConfigurationService.svc" withUrl:url];
    if (self != nil)
    {
    }
	return self;
}


#pragma mark - Public methods

- (void)getChannelList
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"Channel" andParserClass:[ChannelHandler class]];
	[super getFromMethod:@"GetChannelList" query:nil];
}

- (void)getSipEndpointForChannel:(NSString *)channelName
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"name" stringValue:channelName];
	responseHandler = [[SipEndPointHandler alloc] init];
	[super getFromMethod:@"GetSipEndpoint" query:query.query];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	if (responseHandler == nil)
	{
		// no response expected so just log error, if any
		if (error != nil)
		{
			DDLogWarn(@"CallConfigurationService error response: %@", error);
		}
	}
	else if ([responseHandler isKindOfClass:[ArrayHandler class]])
	{
		NSArray * channels = nil;
		
		if (error == nil)
		{
			channels = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetChannelListResult:channels error:error];
					    });
	}
	else if ([responseHandler isKindOfClass:[SipEndPointHandler class]])
	{
		SipEndPoint * endpoint = nil;
		
		if (error == nil)
		{
			endpoint = [responseHandler parseResponse:data];
		}
		else if ([[error domain] isEqualToString:RV_DOMAIN] && error.code == RV_HTTP_ERROR)
		{
			RvError * httpError = (RvError *)error;
			if ([httpError.httpStatus integerValue] == 410)
			{
				// treat 410 HTTP status as user not authorized for channel
				error = [RvError rvErrorWithLocalizedDescription:NSLocalizedString(@"Channel not available",
																				   @"Channel not available")];
			}
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetSipEndpointResult:endpoint error:error];
					    });
	}
}

@end
