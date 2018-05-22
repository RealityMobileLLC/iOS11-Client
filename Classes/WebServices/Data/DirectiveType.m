//
//  DirectiveType.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "DirectiveType.h"

static NSArray * values;


@implementation DirectiveType
{
	DirectiveTypeEnum value;
}

@synthesize value;


+ (void)initialize
{
	if (self == [DirectiveType class]) 
	{
		values = [[NSArray alloc] initWithObjects:@"Error",
										          @"NONE",
										          @"TEXT_MESSAGE",
										          @"TURN_ON_CAMERA",
										          @"PLACE_PHONE_CALL",
										          @"VIEW_VIDEO",
										          @"DOWNLOAD_FILE",
										          @"TURN_OFF_CAMERA",
										          @"KILL_PILL",
										          @"VIEW_CAMERA_URI",
										          @"VIEW_CAMERA_INFO",
										          @"VIEW_URL",
										          @"GO_OFF_DUTY",
										          @"DOWNLOAD_IMAGE",
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
		self.value = (intValue == NSNotFound) ? DT_Error : intValue-1;
	}
	return self;
}


- (id)initWithValue:(DirectiveTypeEnum)directiveType
{
	self = [super init];
	if (self != nil)
	{
		self.value = directiveType;
	}
	return self;
}


- (NSString *)stringValue
{
	return [DirectiveType stringValueForEnum:self.value];
}


+ (NSString *)stringValueForEnum:(DirectiveTypeEnum)directiveType
{
	int index = directiveType + 1;
	if ((index < 0) || (index >= [values count]))
	{
		index = 0;
	}
	return [values objectAtIndex:index];
}

@end
