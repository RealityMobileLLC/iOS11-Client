//
//  MenuTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MenuTableViewCell.h"
#import "UIView+Layout.h"


@implementation MenuTableViewCell

@synthesize imageView;
@synthesize textLabel;
@synthesize badgeImage;
@synthesize badgeLabel;


+ (NSString *)reuseIdentifier
{
	return @"MenuCell";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (imageView.image == nil)
    {
        [textLabel setOriginX:20.0];
        imageView.hidden = YES;
    }
    else
    {
        CGRect imageFrame = imageView.frame;
        [textLabel setOriginX:imageFrame.origin.x + imageFrame.size.width + 8];
        imageView.hidden = NO;
    }
}

- (void)setBadgeCount:(NSUInteger)badgeCount
{
	badgeImage.hidden = badgeLabel.hidden = (badgeCount == 0);
	
	if (badgeCount > 0)
	{
		badgeLabel.text = [NSString stringWithFormat:@"%d",badgeCount];
	}
}

@end
