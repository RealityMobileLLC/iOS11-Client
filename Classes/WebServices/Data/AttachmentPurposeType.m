//
//  AttachmentPurposeType.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AttachmentPurposeType.h"

static NSArray * values;


@implementation AttachmentPurposeType
{
	AttachmentPurposeTypeEnum value;
}

@synthesize value;


+ (void)initialize
{
	if (self == [AttachmentPurposeType class]) 
	{
		values = [[NSArray alloc] initWithObjects:@"Image",@"AnnotatedImage",nil];
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


- (id)initWithValue:(AttachmentPurposeTypeEnum)attachmentPurposeType
{
	self = [super init];
	if (self != nil)
	{
		self.value = attachmentPurposeType;
	}
	return self;
}


- (NSString *)stringValue
{
	return [AttachmentPurposeType stringValueForEnum:self.value];
}


+ (NSString *)stringValueForEnum:(AttachmentPurposeTypeEnum)attachmentPurposeType
{
	int index = attachmentPurposeType;
	return (index < 0) || (index >= [values count]) ? nil : [values objectAtIndex:index];
}

@end
