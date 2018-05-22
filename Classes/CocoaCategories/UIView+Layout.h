//
//  UIView+Layout.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/27/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef CENTER
// centers innerwidth within outerwidth
#define CENTER(outerwidth,innerwidth) (((outerwidth)-(innerwidth))/2)
#endif


/**
 *  The Layout category extends UIView to provide convenience functions for moving and
 *  resizing a view.
 */
@interface UIView (Layout)

/**
 *  Sets the view's frame.origin.x.
 */
- (void)setOriginX:(CGFloat)newX;

/**
 *  Sets the view's frame.origin.y.
 */
- (void)setOriginY:(CGFloat)newY;

/**
 *  Sets the view's frame.origin.
 */
- (void)setOrigin:(CGPoint)newOrigin;

/**
 *  Sets the view's frame.size.height.
 */
- (void)setHeight:(CGFloat)newHeight;

/**
 *  Sets the view's frame.size.width.
 */
- (void)setWidth:(CGFloat)newWidth;

/**
 *  Sets the view's frame.size.
 */
- (void)setSize:(CGSize)newSize;

/**
 *  Moves the view's frame.origin.x.
 */
- (void)moveOriginXBy:(CGFloat)delta;

/**
 *  Moves the view's frame.origin.y.
 */
- (void)moveOriginYBy:(CGFloat)delta;

/**
 *  Moves the view's frame.origin.
 */
- (void)moveOriginBy:(CGPoint)delta;

/**
 *  Increases the view's frame.size.height.
 */
- (void)increaseHeightBy:(CGFloat)delta;

/**
 *  Increases the view's frame.size.width.
 */
- (void)increaseWidthBy:(CGFloat)delta;

/**
 *  Increases the view's frame.sizet.
 */
- (void)increaseSizeBy:(CGSize)delta;

@end
