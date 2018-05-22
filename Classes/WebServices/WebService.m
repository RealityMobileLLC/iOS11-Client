//
//  WebService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "WebService.h"
#import "ConfigurationManager.h"
#import "RealityVisionAppDelegate.h"
#import "AuthenticationHandler.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation WebService
{
	NSString              * name;
	NSURL                 * url;
	NSURLConnection       * connection;
    NSInteger               responseHttpStatus;
	NSMutableData         * responseData;
	NSError               * responseError;
	AuthenticationHandler * authenticationHandler;
}

@synthesize sendDeviceId;


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		name = @"HTTP";
		url = nil;
		connection = nil;
		responseData = nil;
		responseError = nil;
		authenticationHandler = [[AuthenticationHandler alloc] init];
	}
	return self;
}

- (id)initService:(NSString *)service withUrl:(NSURL *)baseUrl
{
	NSAssert(service!=nil,@"service parameter is required");
	NSAssert(baseUrl!=nil,@"baseUrl parameter is required");
	
	self = [super init];
	if (self != nil)
	{
		name = service;
		url = baseUrl;
        sendDeviceId = YES;
		connection = nil;
		responseData = nil;
		responseError = nil;
		authenticationHandler = [[AuthenticationHandler alloc] init];
	}
	return self;
}


#pragma mark - Public methods

- (void)getFromMethod:(NSString *)method 
				query:(NSString *)query
{
	NSURL * getUrl = [self createUrlForMethod:method withQuery:query];
	
	if (getUrl == nil)
	{
		DDLogError(@"WebService getFromMethod:query: has no URL");
		[self didGetResponse:nil orError:[RvError rvErrorWithLocalizedDescription:@"Unable to call web service because URL is not known"]];
		return;
	}
	
	DDLogInfo(@"GET request to %@", [getUrl absoluteString]);
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:getUrl 
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
															 timeoutInterval:60];
    
    if (self.sendDeviceId)
    {
        [request setValue:[ConfigurationManager instance].deviceId forHTTPHeaderField:@"X-RealityMobile-DeviceID"];
    }
    
	[self doHttpRequest:request];
}

- (void)postToMethod:(NSString *)method 
			   query:(NSString *)query  
				data:(NSData *)data
{
	NSURL * postUrl = [self createUrlForMethod:method withQuery:query];
	
	if (postUrl == nil)
	{
		DDLogError(@"WebService postToMethod:query:data: has no URL");
		[self didGetResponse:nil orError:[RvError rvErrorWithLocalizedDescription:@"Unable to call web service because URL is not known"]];
		return;
	}
	
	DDLogInfo(@"POST request to %@", [postUrl absoluteString]);
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:postUrl 
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
															 timeoutInterval:60];
	[request setHTTPMethod:@"POST"];
    
    if (self.sendDeviceId)
    {
        [request setValue:[ConfigurationManager instance].deviceId forHTTPHeaderField:@"X-RealityMobile-DeviceID"];
    }
    
	[request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:data];
	[self doHttpRequest:request];
}

- (void)headRequest
{
	DDLogInfo(@"HEAD request to %@", [url absoluteString]);
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url 
																 cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
															 timeoutInterval:60];
	[request setHTTPMethod:@"HEAD"];
	[self doHttpRequest:request];
}

- (void)doHttpRequest:(NSURLRequest *)request
{
	NSAssert(connection==nil,@"Can't start a new request until the previous one finishes");
	[RealityVisionAppDelegate didStartNetworking];
	
	// create buffer to hold response
	responseData = [NSMutableData dataWithCapacity:1024];
	
	// create connection to send request and manage response
	connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	// child class should override this method, default implementation just logs error
	if (error)
	{
		DDLogError(@"WebService error: %@", [error localizedDescription]);
	}
}

- (void)cancel
{
	DDLogInfo(@"WebService(%@) cancel", name);
	[RealityVisionAppDelegate didStopNetworking];
	[connection cancel];
}


#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    responseHttpStatus = httpResponse.statusCode;
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
 	[self connectionIsComplete];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	DDLogError(@"WebService(%@) didFailWithError: %@", name, error);
	responseData = nil;
	responseError = authenticationHandler.authenticationError ? authenticationHandler.authenticationError : error;
	[self connectionIsComplete];
}

- (void)connectionIsComplete
{
	[RealityVisionAppDelegate didStopNetworking];
	[authenticationHandler connectionIsComplete:connection];
	
    // if the connection didn't fail with error, see if we received an http status error
    // for now, treat all 2xx status codes as OK and all others as errors
    // we may later want to differentiate between the 2xx status codes but it's currently not needed
    if ((responseError == nil) && ((responseHttpStatus < 200) || (responseHttpStatus > 299)))
    {
        // realityvision server returns 403 (forbidden) if device is not signed on
		responseError = (responseHttpStatus == 403) ? [RvError rvNotSignedOn] 
		                                            : [RvError rvErrorWithHttpStatus:responseHttpStatus 
																			 message:[self stringFromResponseData]];
    }
    
	if (responseError != nil)
	{
        // log any response we received before releasing it
        if (! NSStringIsNilOrEmpty(responseData))
        {
            DDLogError(@"WebService error response: %@", [NSString stringWithUTF8String:responseData.bytes]);
        }
        
		responseData = nil;
        
        if ([responseError.domain isEqualToString:RV_DOMAIN] && (responseError.code == RV_NOT_SIGNED_ON))
        {
            [RealityVisionAppDelegate forceSignOff];
        }
	}
	
    
	[self didGetResponse:responseData orError:responseError];
	
	connection = nil;
	responseData = nil;
	responseError = nil;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)conn
{
	return [authenticationHandler connectionShouldUseCredentialStorage:conn];
}

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [authenticationHandler connection:conn canAuthenticateAgainstProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	return [authenticationHandler connection:conn didReceiveAuthenticationChallenge:challenge];
}


#pragma mark - Internal helper methods

- (NSURL *)createUrlForMethod:(NSString *)method withQuery:(NSString *)query
{
	if (url == nil)
		return nil;
	
	NSMutableString * buffer = [NSMutableString stringWithCapacity:4096];
	[buffer appendString:[url absoluteString]];
	[buffer appendString:@"/"];
	[buffer appendString:name];
	[buffer appendString:@"/"];
	[buffer appendString:method];
	
	if (! NSStringIsNilOrEmpty(query))
	{
		[buffer appendString:@"?"];
		[buffer appendString:query];
	}
	
	return [NSURL URLWithString:buffer];
}

- (NSString *)stringFromResponseData
{
    // null-terminate response data before trying to convert to string
    static const char endOfString = '\0';
    [responseData appendBytes:&endOfString length:1];
    return [NSString stringWithUTF8String:responseData.bytes];
}

@end
