//
//  ClientConfiguration.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ClientConfiguration.h"

static NSString * const kClientConnectionActiveRate = @"clientConnectionActiveRate";
static NSString * const kCommandDisplayCount        = @"ClientCommandDisplayCount";
static NSString * const kGpsThresholdDistance       = @"GpsThresholdDistance";
static NSString * const kMaxGpsTransmissionRate     = @"MaximumGpsTransmissionRate";
static NSString * const kMaxGpsHdop                 = @"MaximumGpsHdop";
static NSString * const kClientCanStoreUserid       = @"ClientCanStoreUserID";
static NSString * const kClientCameraRefreshPeriod  = @"ClientCameraRefreshPeriod";
static NSString * const kTabletMapUserRefreshPeriod = @"TabletMapUserRefreshPeriod";
static NSString * const kMaxSimultaneousFeeds       = @"MaxSimultaneousFeeds";
static NSString * const kMaximumPushToTalkTime      = @"MaxPushToTalkTimeSeconds";


@implementation ClientConfiguration

@synthesize clientConnectionActiveRate;
@synthesize clientCommandDisplayCount;
@synthesize gpsThresholdDistance;
@synthesize maximumGpsTransmissionRate;
@synthesize maximumGpsHdop;
@synthesize clientCanStoreUserid;
@synthesize clientCameraRefreshPeriod;
@synthesize tabletMapUserRefreshPeriod;
@synthesize maximumSimultaneousFeeds;
@synthesize maximumPushToTalkTimeSeconds;


#pragma mark - Initialization and cleanup

- (void)getValuesFromDictionary:(NSDictionary *)values
{
	clientConnectionActiveRate   = [ClientConfiguration getIntegerFromString:[values objectForKey:kClientConnectionActiveRate] 
																orUseDefault:150];
	
	clientCommandDisplayCount    = [ClientConfiguration getIntegerFromString:[values objectForKey:kCommandDisplayCount]
																orUseDefault:30];
	
	gpsThresholdDistance         = [ClientConfiguration getIntegerFromString:[values objectForKey:kGpsThresholdDistance]
																orUseDefault:20];
	
	maximumGpsTransmissionRate   = [ClientConfiguration getIntegerFromString:[values objectForKey:kMaxGpsTransmissionRate] 
																orUseDefault:10];
	
	maximumGpsHdop               = [ClientConfiguration getFloatFromString:[values objectForKey:kMaxGpsHdop] 
															  orUseDefault:5.0];
	
	clientCanStoreUserid         = [ClientConfiguration getBooleanFromString:[values objectForKey:kClientCanStoreUserid] 
																orUseDefault:YES];
	
	clientCameraRefreshPeriod    = [ClientConfiguration getIntegerFromString:[values objectForKey:kClientCameraRefreshPeriod] 
																orUseDefault:5];
    
    tabletMapUserRefreshPeriod   = [ClientConfiguration getIntegerFromString:[values objectForKey:kTabletMapUserRefreshPeriod] 
																orUseDefault:15];
	
	maximumSimultaneousFeeds     = [ClientConfiguration getIntegerFromString:[values objectForKey:kMaxSimultaneousFeeds] 
																orUseDefault:5];
	
	maximumPushToTalkTimeSeconds = [ClientConfiguration getIntegerFromString:[values objectForKey:kMaximumPushToTalkTime] 
																orUseDefault:20];
}

- (id)initFromDictionary:(NSDictionary *)values
{
	self = [super init];
	if (self != nil)
	{
		[self getValuesFromDictionary:values];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
	clientCommandDisplayCount    = [coder decodeIntForKey:kCommandDisplayCount];
	gpsThresholdDistance         = [coder decodeIntForKey:kGpsThresholdDistance];
	maximumGpsTransmissionRate   = [coder decodeIntForKey:kMaxGpsTransmissionRate];
	maximumGpsHdop               = [coder decodeFloatForKey:kMaxGpsHdop];
	clientCanStoreUserid         = [coder decodeBoolForKey:kClientCanStoreUserid];
	
	clientCameraRefreshPeriod    = [coder containsValueForKey:kClientCameraRefreshPeriod] ? 
	                               [coder decodeIntForKey:kClientCameraRefreshPeriod] : 5;
    
    tabletMapUserRefreshPeriod   = [coder containsValueForKey:kTabletMapUserRefreshPeriod] ?
                                   [coder decodeIntForKey:kTabletMapUserRefreshPeriod] : 15;
	
	maximumSimultaneousFeeds     = [coder containsValueForKey:kMaxSimultaneousFeeds] ? 
	                               [coder decodeIntForKey:kMaxSimultaneousFeeds] : 5;
	
	clientConnectionActiveRate   = [coder containsValueForKey:kClientConnectionActiveRate] ? 
								   [coder decodeIntForKey:kClientConnectionActiveRate] : 150;
	
	maximumPushToTalkTimeSeconds = [coder containsValueForKey:kMaximumPushToTalkTime] ? 
	                               [coder decodeIntForKey:kMaximumPushToTalkTime] : 20;
	
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeInt:clientCommandDisplayCount    forKey:kCommandDisplayCount];
	[coder encodeInt:gpsThresholdDistance         forKey:kGpsThresholdDistance];
	[coder encodeInt:maximumGpsTransmissionRate   forKey:kMaxGpsTransmissionRate];
	[coder encodeFloat:maximumGpsHdop             forKey:kMaxGpsHdop];
	[coder encodeBool:clientCanStoreUserid        forKey:kClientCanStoreUserid];
	[coder encodeInt:clientCameraRefreshPeriod    forKey:kClientCameraRefreshPeriod];
    [coder encodeInt:tabletMapUserRefreshPeriod   forKey:kTabletMapUserRefreshPeriod];
	[coder encodeInt:maximumSimultaneousFeeds     forKey:kMaxSimultaneousFeeds];
	[coder encodeInt:clientConnectionActiveRate   forKey:kClientConnectionActiveRate];
	[coder encodeInt:maximumPushToTalkTimeSeconds forKey:kMaximumPushToTalkTime];
}


#pragma mark - Private methods

+ (int)getIntegerFromString:(NSString*)stringValue orUseDefault:(int)defaultValue
{
	@try 
	{
		if (stringValue != nil)
		{
			return [stringValue intValue];
		}
	}
	@catch (NSException*) 
	{
	}
	
	return defaultValue;
}

+ (float)getFloatFromString:(NSString*)stringValue orUseDefault:(float)defaultValue
{
	@try 
	{
		if (stringValue != nil)
		{
			return [stringValue floatValue];
		}
	}
	@catch (NSException*) 
	{
	}
	
	return defaultValue;
}

+ (BOOL)getBooleanFromString:(NSString*)stringValue orUseDefault:(BOOL)defaultValue
{
	@try 
	{
		if (stringValue != nil)
		{
			if ([stringValue caseInsensitiveCompare:@"true"] == NSOrderedSame) 
			{
				return YES;
			}
			else if ([stringValue isEqualToString:@"false"] == NSOrderedSame)
			{
				return NO;
			}
		}
	}
	@catch (NSException*) 
	{
	}
	
	return defaultValue;
}

@end
