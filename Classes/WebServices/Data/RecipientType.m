//
//  RecipientType.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "RecipientType.h"

static NSArray * values;


@implementation RecipientType
{
	RecipientTypeEnum value;
}

@synthesize value;


+ (void)initialize
{
	if (self == [RecipientType class]) 
	{
		values = [[NSArray alloc] initWithObjects:@"GROUP",@"USER",@"USER_DEVICE",nil];
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


- (id)initWithValue:(RecipientTypeEnum)recipientType
{
	self = [super init];
	if (self != nil)
	{
		self.value = recipientType;
	}
	return self;
}


- (NSString *)stringValue
{
	return [RecipientType stringValueForEnum:self.value];
}


+ (NSString *)stringValueForEnum:(RecipientTypeEnum)recipientType
{
	int index = recipientType;
	return (index < 0) || (index >= [values count]) ? nil : [values objectAtIndex:index];
}

@end
