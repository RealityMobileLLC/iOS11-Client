//
//  SwitchTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/21/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SwitchTableViewCell.h"


@implementation SwitchTableViewCell

@synthesize label;
@synthesize switchField;

+ (NSString *)reuseIdentifier
{
	return @"SwitchCell";
}

@end
