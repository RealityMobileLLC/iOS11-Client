//
//  CameraStatusTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/17/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CameraStatusTableViewCell.h"


@implementation CameraStatusTableViewCell

@synthesize locationImage;
@synthesize locationLabel;
@synthesize ptzImage;
@synthesize ptzLabel;

+ (NSString *)reuseIdentifier
{
	return @"CameraStatusCell";
}

@end
