//
//  RVReleaseGestureRecognizer.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/27/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "RVReleaseGestureRecognizer.h"
#import "RVPressGestureRecognizer.h"
#import "UIKit/UIGestureRecognizerSubclass.h"


@implementation RVReleaseGestureRecognizer

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
	return YES;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
	return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
	return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event];
	self.state = UIGestureRecognizerStateFailed;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	if (self.state == UIGestureRecognizerStatePossible)
	{	
		self.state = UIGestureRecognizerStateRecognized;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
}

- (void)reset
{
	[super reset];
}

@end
