//
//  Channel.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/24/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "Channel.h"

static NSString * const kChannelName        = @"Name";
static NSString * const kChannelDescription = @"Description";


@implementation Channel

@synthesize name;
@synthesize description;

- (id)initWithCoder:(NSCoder *)decoder
{
	name        = [decoder decodeObjectForKey:kChannelName];
	description = [decoder decodeObjectForKey:kChannelDescription];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:name        forKey:kChannelName];
	[coder encodeObject:description forKey:kChannelDescription];
}

@end
