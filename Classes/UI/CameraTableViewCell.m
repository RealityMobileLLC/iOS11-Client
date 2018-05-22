//
//  CameraTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 2/16/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CameraTableViewCell.h"


@implementation CameraTableViewCell

@synthesize thumbnailView;
@synthesize captionLabel;
@synthesize descriptionLabel;
@synthesize ptzIcon;
@synthesize locationIcon;
@synthesize commentsIcon;
@synthesize commentsLabel;
@synthesize lengthLabel;

+ (NSString *)reuseIdentifier
{
	return @"CameraCell";
}

@end
