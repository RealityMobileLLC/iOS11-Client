//
//  MenuItem.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MenuItem.h"


@implementation MenuItem

@synthesize label;
@synthesize image;
@synthesize tag;


- (id)initWithLabel:(NSString *)labelText image:(NSString *)imageName
{
	self = [super init];
	if (self != nil)
	{
		label = labelText;
		image = imageName;
	}
	return self;
}

@end
