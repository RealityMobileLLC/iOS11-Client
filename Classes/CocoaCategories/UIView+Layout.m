//
//  UIView+Layout.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/27/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "UIView+Layout.h"

@implementation UIView (Layout)

- (void)setOriginX:(CGFloat)newX
{
    CGRect newFrame = self.frame;
    newFrame.origin.x = newX;
    self.frame = newFrame;
}

- (void)setOriginY:(CGFloat)newY
{
    CGRect newFrame = self.frame;
    newFrame.origin.y = newY;
    self.frame = newFrame;
}

- (void)setOrigin:(CGPoint)newOrigin
{
    CGRect newFrame = self.frame;
    newFrame.origin = newOrigin;
    self.frame = newFrame;
}

- (void)setHeight:(CGFloat)newHeight
{
    CGRect newFrame = self.frame;
    newFrame.size.height = newHeight;
    self.frame = newFrame;
}

- (void)setWidth:(CGFloat)newWidth
{
    CGRect newFrame = self.frame;
    newFrame.size.width = newWidth;
    self.frame = newFrame;
}

- (void)setSize:(CGSize)newSize
{
    CGRect newFrame = self.frame;
    newFrame.size = newSize;
    self.frame = newFrame;
}

- (void)moveOriginXBy:(CGFloat)delta
{
    CGRect newFrame = self.frame;
    newFrame.origin.x += delta;
    self.frame = newFrame;
}

- (void)moveOriginYBy:(CGFloat)delta
{
    CGRect newFrame = self.frame;
    newFrame.origin.y += delta;
    self.frame = newFrame;
}

- (void)moveOriginBy:(CGPoint)delta
{
    CGRect newFrame = self.frame;
    newFrame.origin.x += delta.x;
    newFrame.origin.y += delta.y;
    self.frame = newFrame;
}

- (void)increaseHeightBy:(CGFloat)delta
{
    CGRect newFrame = self.frame;
    newFrame.size.height += delta;
    self.frame = newFrame;
}

- (void)increaseWidthBy:(CGFloat)delta
{
    CGRect newFrame = self.frame;
    newFrame.size.width += delta;
    self.frame = newFrame;
}

- (void)increaseSizeBy:(CGSize)delta
{
    CGRect newFrame = self.frame;
    newFrame.size.height += delta.height;
    newFrame.size.width += delta.width;
    self.frame = newFrame;
}

@end
