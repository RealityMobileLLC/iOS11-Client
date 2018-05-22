//
//  CommandResponseType.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandResponseType.h"

static NSArray * values;


@implementation CommandResponseType
{
	CommandResponseTypeEnum value;
}

@synthesize value;


+ (void)initialize
{
	if (self == [CommandResponseType class]) 
	{
		values = [[NSArray alloc] initWithObjects:@"None",@"YesNo",nil];
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
			self.value = intValue + 1;
		}
		else
		{
			self = nil;
		}
	}
	return self;
}


- (id)initWithValue:(CommandResponseTypeEnum)commandResponseType
{
	self = [super init];
	if (self != nil)
	{
		self.value = commandResponseType;
	}
	return self;
}


- (NSString *)stringValue
{
	return [CommandResponseType stringValueForEnum:self.value];
}


+ (NSString *)stringValueForEnum:(CommandResponseTypeEnum)commandResponseType
{
	int index = commandResponseType - 1;
	return (index < 0) || (index >= [values count]) ? nil : [values objectAtIndex:index];
}

@end
