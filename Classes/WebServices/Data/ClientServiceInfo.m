//
//  ClientServiceInfo.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ClientServiceInfo.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ClientServiceInfo

@synthesize deviceId;
@synthesize newHistoryCount;
@synthesize systemUris;
@synthesize externalSystemUris;
@synthesize clientConfiguration;


- (id)initDevice:(NSString *)devId 
 newHistoryCount:(UInt32)histCount 
	  systemUris:(NSDictionary *)sysUris 
	externalUris:(NSDictionary *)extUris 
   configuration:(NSDictionary *)config
{
	self = [super init];
	if (self != nil)
	{
		deviceId = devId;
		newHistoryCount = histCount;
		systemUris = sysUris;
		externalSystemUris = extUris;
		clientConfiguration = config;
	}
	return self;
}


- (void)log
{
	DDLogVerbose(@"ClientServiceInfo object");
	
	DDLogVerbose(@"  Device ID=%@",deviceId);
	DDLogVerbose(@"  New History Count=%lu",newHistoryCount);
	
	DDLogVerbose(@"  System URIs=");
	NSString * systemUriKey;
	for (systemUriKey in systemUris) 
	{
		NSString *value = [systemUris valueForKey:systemUriKey];
		DDLogVerbose(@"    %@=%@",systemUriKey,value);
	}
	
	DDLogVerbose(@"  External URIs=");
	NSString * extUriKey;
	for (extUriKey in externalSystemUris) 
	{
		NSString *value = [externalSystemUris valueForKey:extUriKey];
		DDLogVerbose(@"    %@=%@",extUriKey,value);
	}
	
	DDLogVerbose(@"  Client Configuration=");
	NSString * configKey;
	for (configKey in clientConfiguration) 
	{
		NSString *value = [clientConfiguration valueForKey:configKey];
		DDLogVerbose(@"    %@=%@",configKey,value);
	}
}


- (void)augmentExternalUrisHostWith:(NSString *) connectionProfileName
{
	static NSString * searchString = @"//-:";
	NSString * replacementString = [NSString stringWithFormat:@"//%@:", connectionProfileName];
	NSDictionary * newUris = [[NSMutableDictionary alloc] init ];
	BOOL isChanged = NO;
	
	NSString * newUri;
	NSString * extUriKey;
	for (extUriKey in externalSystemUris)
	{
		NSString * original = [externalSystemUris valueForKey:extUriKey];
		newUri = [original stringByReplacingOccurrencesOfString:searchString withString:replacementString];
		if (![newUri isEqualToString:original])
		{
			isChanged = YES;
			DDLogVerbose(@"Replacing hyphenated relative path name with connection profile name. %@ becomes %@", original, newUri);
		}
		
		[newUris setValue:newUri forKey:extUriKey];
	}
	
	if (isChanged)
		self.externalSystemUris = newUris;
}

@end
