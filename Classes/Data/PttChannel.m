//
//  PttChannel.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/27/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import "PttChannel.h"


@implementation PttChannel

@synthesize name;
@synthesize sipUri;
@synthesize codec;
@synthesize pin;

- (id)initWithName:(NSString *)cname 
		   address:(NSString *)curi 
			 codec:(NSString *)ccodec 
			   pin:(NSString *)cpin
{
	self = [super init];
	if (self != nil)
	{
		name = cname;
		sipUri = curi;
		codec = ccodec;
		pin = cpin;
	}
	return self;
}

@end
