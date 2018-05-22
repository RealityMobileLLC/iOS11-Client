//
//  UILabel+Layout.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/27/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat DefaultLabelHeight;


/**
 *  The Layout category extends UILabel to provide convenience functions for resizing the label.
 */
@interface UILabel (Layout)

/**
 *  Resizes the label's height to fit the current text using the current font and linebreak mode.
 *  Will never shrink height to less than DefaultLabelHeight. If the text property is nil or 
 *  empty, does nothing.
 *  
 *  @note The current implementation rounds the height up to the next "line" and assumes a line
 *        height of 20 pixels (good for the system font at 14 points).
 *  
 *  @return Change in height in points.
 */
- (CGFloat)resizeHeightToFitText;

/**
 *  Resizes the label's height to fit the current text using the current font and linebreak mode.
 *  Will never shrink height to less than DefaultLabelHeight. If the text property is nil or 
 *  empty, does nothing.
 *  
 *  @note The current implementation rounds the height up to the next "line" and assumes a line
 *        height of 20 pixels (good for the system font at 14 points).
 *  
 *  @param maxHeight The maximum height for the label.
 *  @return Change in height in points.
 */
- (CGFloat)resizeHeightToFitTextWithMaxHeight:(CGFloat)maxHeight;

@end
