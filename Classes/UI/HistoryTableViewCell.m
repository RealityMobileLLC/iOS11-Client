//
//  HistoryTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/9/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "HistoryTableViewCell.h"


@implementation HistoryTableViewCell

@synthesize iconImageView;
@synthesize titleTextLabel;
@synthesize fromTextLabel;
@synthesize dateTextLabel;

+ (NSString *)reuseIdentifier
{
	return @"HistoryCell";
}

@end
