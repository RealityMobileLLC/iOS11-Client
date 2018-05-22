//
//  EditingTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/21/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "EditingTableViewCell.h"


@implementation EditingTableViewCell

@synthesize label;
@synthesize textField;

+ (NSString *)reuseIdentifier
{
	return @"EditingCell";
}

@end
