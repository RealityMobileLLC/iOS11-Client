//
//  UILabel+Layout.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/27/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "UILabel+Layout.h"

// @todo the following values work well for the default system font at 14 points
const CGFloat DefaultLabelHeight = 21;
const CGFloat DefaultLineHeight = 18;


@implementation UILabel (Layout)

- (CGFloat)heightRoundedToNextLine:(CGFloat)height
{
    if (height < DefaultLabelHeight)
    {
        return DefaultLabelHeight;
    }
    
    height -= DefaultLabelHeight;
    CGFloat numLines = ceilf(height / DefaultLineHeight);
    height = numLines * DefaultLineHeight + DefaultLabelHeight;
    
    return  height;
}

- (CGFloat)resizeHeightToFitTextWithMaxHeight:(CGFloat)maxHeight
{
    if (NSStringIsNilOrEmpty(self.text))
    {
        return 0;
    }
    
	CGRect frame = self.frame;
	CGSize size = [self.text sizeWithFont:self.font
                        constrainedToSize:CGSizeMake(frame.size.width, maxHeight)
                            lineBreakMode:self.lineBreakMode];
    
    // @todo rounding to next line should probably be a parameterized option
    size.height = MIN([self heightRoundedToNextLine:size.height],maxHeight);
	CGFloat delta = size.height - frame.size.height;
    
    if (fabs(delta) < 1.0)
    {
        return 0;
    }
    
	frame.size.height = size.height;
	self.frame = frame;
    
	return delta;
}

- (CGFloat)resizeHeightToFitText
{
    return [self resizeHeightToFitTextWithMaxHeight:9999];
}

@end
