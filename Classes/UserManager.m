//
//  UserManager.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/20/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserManager.h"


@implementation UserManager

@synthesize users;


#pragma mark -
#pragma mark Initialization and cleanup

// Singleton instance
static UserManager * instance = nil;

+ (UserManager *)instance
{
	if (instance == nil) 
	{
		instance = [[UserManager alloc] init];
	}
	return instance;
}

- (id)init
{
	NSAssert(instance==nil,@"UserManager singleton should only be instantiated once");
	self = [super init];
	return self;
}

@end
