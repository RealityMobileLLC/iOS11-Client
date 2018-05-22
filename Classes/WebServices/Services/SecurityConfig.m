//
//  SecurityConfig.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SecurityConfig.h"
#import "XmlFactory.h"
#import "QueryString.h"
#import "RequireSslForCredentialsHandler.h"


@implementation SecurityConfig
{
	id <WebServiceResponseHandler> responseHandler;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithSecurityConfigUrl:(NSURL *)securityConfigUrl 
					   delegate:(id <SecurityConfigDelegate>)securityConfigDelegate
{
	self = [super initService:@"SecurityConfig" withUrl:securityConfigUrl];
	if (self != nil)
	{
		delegate = securityConfigDelegate;
        self.sendDeviceId = NO;
	}
	return self;
}


#pragma mark - Public methods

- (void)getRequireSslForCredentials;
{
	responseHandler = [[RequireSslForCredentialsHandler alloc] init];
	[super getFromMethod:@"GetRequireSslForCredentials" query:nil];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	if ([responseHandler isKindOfClass:[RequireSslForCredentialsHandler class]])
	{
		BOOL requireSslForCredentials = YES;
		
		if (error == nil)
		{
			NSNumber * requireSslForCredentialsValue = [responseHandler parseResponse:data];
			requireSslForCredentials = [requireSslForCredentialsValue boolValue];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGotRequireSslForCredentials:requireSslForCredentials error:error];
					    });
	}
}

@end
