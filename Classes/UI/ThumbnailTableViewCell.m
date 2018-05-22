//
//  ThumbnailTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "ThumbnailTableViewCell.h"


@implementation ThumbnailTableViewCell

@synthesize imageView;

+ (NSString *)reuseIdentifier
{
	return @"ThumbnailCell";
}

@end
