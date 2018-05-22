//
//  ClientStatus.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ClientStatus.h"

static NSDictionary * values;


@implementation ClientStatus
{
	ClientStatusEnum value;
}

@synthesize value;


+ (void)initialize
{
	if (self == [ClientStatus class]) 
	{
		values = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:0x01], @"CONNECTED",
				                                              [NSNumber numberWithInt:0x04], @"WATCHING",
				                                              [NSNumber numberWithInt:0x08], @"ALERT",
															  nil];
	}
}


- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (id)initWithString:(NSString *)stringValue
{
	self = [super init];
	if (self != nil)
	{
		NSNumber * numberValue = [values objectForKey:stringValue];
		self.value = (numberValue != nil) ? [numberValue intValue] : 0;
	}
	return self;
}


- (id)initWithValue:(ClientStatusEnum)clientStatus
{
	self = [super init];
	if (self != nil)
	{
		self.value = clientStatus;
	}
	return self;
}


- (NSString *)stringValue
{
	return [ClientStatus stringValueForEnum:self.value];
}


+ (ClientStatus *)clientStatusWithString:(NSString *)stringValue
{
    return [[ClientStatus alloc] initWithString:stringValue];
}


+ (ClientStatus *)clientStatusWithValue:(ClientStatusEnum)clientStatus
{
    return [[ClientStatus alloc] initWithValue:clientStatus];
}


+ (NSString *)stringValueForEnum:(ClientStatusEnum)clientStatus
{
	NSArray * keys = [values allKeysForObject:[NSNumber numberWithInt:clientStatus]];
	return ((keys == nil) || ([keys count] == 0)) ? @"UNKNOWN" : [keys objectAtIndex:0];
}

@end
