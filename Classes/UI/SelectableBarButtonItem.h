//
//  SelectableBarButtonItem.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UIBarButtonItem used to display a custom button.  The button has 
 *  two states, on and off.  Each state has a corresponding image that is 
 *  displayed.
 */
@interface SelectableBarButtonItem : UIBarButtonItem 

/**
 *  The current button state.
 */
@property (nonatomic) BOOL on;

/**
 *  Initializes the SelectableBarButtonItem with a target and action that is
 *  invoked when the button is pressed (UIControlEventTouchDown).  The button
 *  is created with no border.
 *
 *  @param frame The button's frame rectangle.
 *  
 *  @param target The target object, i.e., the object to which the action 
 *                message is sent. If this is nil, the responder chain is 
 *                searched for an object willing to respond to the action 
 *                message.
 *
 *  @param action A selector identifying an action message. It cannot be NULL.
 *
 *  @param offImage The image to use for the UIControlStateNormal state.
 *
 *  @param onImage The image to use for the UIControlStateSelected state.
 *
 *  @return An initialized SelectableBarButtonItem object or nil if the object 
 *           couldn't be created.
 */
- (id)initWithFrame:(CGRect)frame
			 target:(id)target 
			 action:(SEL)action 
		   offImage:(UIImage *)offImage 
			onImage:(UIImage *)onImage;

/**
 *  Initializes the SelectableBarButtonItem with a target and action that is
 *  invoked when the button is pressed (UIControlEventTouchDown).  The button
 *  is created with a rounded rectangle style border.
 *
 *  @param frame The button's frame rectangle.
 *  
 *  @param target The target object, i.e., the object to which the action 
 *                message is sent. If this is nil, the responder chain is 
 *                searched for an object willing to respond to the action 
 *                message.
 *
 *  @param action A selector identifying an action message. It cannot be NULL.
 *
 *  @param offImage The image to use for the UIControlStateNormal state.
 *
 *  @param onImage The image to use for the UIControlStateSelected state.
 *
 *  @return An initialized SelectableBarButtonItem object or nil if the object 
 *           couldn't be created.
 */
- (id)initWithBorderInFrame:(CGRect)frame
                     target:(id)target 
                     action:(SEL)action 
                   offImage:(UIImage *)offImage 
                    onImage:(UIImage *)onImage;

@end
