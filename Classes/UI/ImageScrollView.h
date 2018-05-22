//
//  ImageScrollView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  View that displays an image centered inside a UIScrollView.
 */
@interface ImageScrollView : UIScrollView <UIScrollViewDelegate> 

@property (strong, nonatomic) UIImage * image;
@property (strong, nonatomic,readonly) UIGestureRecognizer * doubleTapGesture;

/**
 *  Rotates through the zoom factors.  If the current zoom is < 1, it sets
 *  the new zoom to 1.  If the current zoom is 1, it sets the new zoom to 2.
 *  If the current zoom is >= 2, it sets the zoom to its minimum.
 */
- (void)toggleZoom;

@end
