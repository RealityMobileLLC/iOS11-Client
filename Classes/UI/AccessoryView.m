//
//  AccessoryView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/7/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "AccessoryView.h"


@implementation AccessoryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
    }
    return self;
}

- (void)layoutSubviews
{
	// fix for BUG-3918
	for (UIView * subview in self.subviews)
	{
		subview.frame = self.bounds;
	}
}

@end
