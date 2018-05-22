//
//  GpsLockStatus.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "GpsLockStatus.h"

static NSArray * values;


@implementation GpsLockStatus

@synthesize value;


+ (void)initialize
{
	if (self == [GpsLockStatus class]) 
	{
		values = [[NSArray alloc] initWithObjects:@"NoLock",
				                                  @"LostLock",
				                                  @"Lock",
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
		int intValue = [values indexOfObject:stringValue];
		if (intValue != NSNotFound)
		{
			self.value = intValue;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}


- (id)initWithValue:(GpsLockStatusEnum)gpsLockStatus
{
	self = [super init];
	if (self != nil)
	{
		self.value = gpsLockStatus;
	}
	return self;
}


- (NSString *)stringValue
{
	return [GpsLockStatus stringValueForEnum:self.value];
}


+ (NSString *)stringValueForEnum:(GpsLockStatusEnum)gpsLockStatus
{
	int index = gpsLockStatus;
	return (index < 0) || (index >= [values count]) ? nil : [values objectAtIndex:index];
}

@end
