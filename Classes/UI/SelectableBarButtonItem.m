//
//  LocationBarButtonItem.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SelectableBarButtonItem.h"


@implementation SelectableBarButtonItem
{
	UIButton * button;
}


- (id)initWithFrame:(CGRect)imageFrame
			 target:(id)target 
			 action:(SEL)action 
		   offImage:(UIImage *)offImage 
			onImage:(UIImage *)onImage
{
	UIButton * customViewButton = (UIButton *)[SelectableBarButtonItem createCustomViewWithFrame:imageFrame 
																						offImage:offImage 
																						 onImage:onImage
                                                                                      buttonType:UIButtonTypeCustom];
	self = [super initWithCustomView:customViewButton];
	if (self != nil)
	{
		button = customViewButton;
		[button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
	}
	return self;
}


- (id)initWithBorderInFrame:(CGRect)imageFrame
                     target:(id)target 
                     action:(SEL)action 
                   offImage:(UIImage *)offImage 
                    onImage:(UIImage *)onImage
{
	UIButton * customViewButton = (UIButton *)[SelectableBarButtonItem createCustomViewWithFrame:imageFrame 
																						offImage:offImage 
																						 onImage:onImage 
                                                                                      buttonType:UIButtonTypeRoundedRect];
	self = [super initWithCustomView:customViewButton];
	if (self != nil)
	{
		button = customViewButton;
		[button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
	}
	return self;
}




- (BOOL)on
{
	return button.selected;
}


- (void)setOn:(BOOL)on
{
	button.selected = on;
}


+ (UIView *)createCustomViewWithFrame:(CGRect)frame 
                             offImage:(UIImage *)offImage
                              onImage:(UIImage *)onImage
                           buttonType:(UIButtonType)buttonType
{
	UIButton * viewButton = [UIButton buttonWithType:buttonType];

	[viewButton setImage:offImage forState:UIControlStateNormal];
	[viewButton setImage:onImage  forState:UIControlStateSelected];
	viewButton.selected = NO;
	viewButton.frame = frame;
	viewButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    viewButton.contentMode = UIViewContentModeCenter;
	
	return viewButton;
}

@end
