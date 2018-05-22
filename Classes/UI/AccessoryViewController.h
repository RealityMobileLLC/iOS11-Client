//
//  AccessoryViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AccessoryView;


/**
 *  A UIViewController that provides a main view and an accessory view. The
 *  accessory view can be hidden, shown as half-screen, or take over the full
 *  screen. The AccessoryViewController manages laying out the two views in 
 *  any orientation.
 *  
 *  There are two mechanisms for showing, hiding, and sizing views. The first 
 *  is to explicitly specify which view to show and at what size. The second
 *  is to toggle the current view and size.
 *  
 *  To explicitly specify which view to show, call 
 *  showAccessoryView:hideAccessoryView:fullScreen:flipDirection. Then to hide
 *  the accessory view, call hideAccessoryView.
 *  
 *  To toggle the current view, use toggleAccessoryView:otherAccessoryView:flipDirection.
 *  To toggle the current view size, use toggleAccessoryViewSize.
 */
@interface AccessoryViewController : UIViewController 

/**
 *  The main view. This property must be set to the view that is displayed when the 
 *  accessory view is hidden.
 */
@property (strong, nonatomic)  UIView * mainView;

/**
 *  The accessory view. This property must be set to the view that can be optionally 
 *  displayed or hidden.
 *
 *  To take advantage of the toggleAccessoryView:otherAccessoryView:flipDirection:
 *  method, two subviews should be added to this view.  The toggleAccessoryView:
 *  method will then show one and hide the other during its flip animation.
 */
@property (strong, nonatomic) AccessoryView * accessoryView;

/**
 *  Indicates whether the accessory view has or is being hidden. This is
 *  set by toggleAccessoryView:otherAccessoryView:flipDirection when it starts
 *  animating the accessory view in or out.
 */
@property (nonatomic,readonly) BOOL accessoryViewHidden;

/**
 *  Indicates whether the accessory view is full screen.
 */
@property (nonatomic,readonly) BOOL accessoryViewFullScreen;

/**
 *  Overrides UIViewController's willAnimateRotationToInterfaceOrientation:duration:
 *  method. This method will change the frames for both the main view and the
 *  accessory view for the new interface orientation.  It also calls layoutMainView
 *  which can be overridden by a subclass to layout other subviews, if desired.
 */
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
										 duration:(NSTimeInterval)duration;

/**
 *  Hides the accessory view by starting a slide animation.
 */
- (void)hideAccessoryView;

/**
 *  Shows the given accessory view in either full or half screen mode.
 *
 *  If accessoryViewHidden is YES, this method will:
 *    <li>show the accessory view at the desired size by starting a slide animation
 *    <li>if thisView is not nil, set its hidden property to NO
 *    <li>if otherView is not nil, set its hidden property to YES
 *
 *  If accessoryViewHidden is NO and thisView is hidden, this method will:
 *    <li>start a flip animation that shows thisView and hides otherView
 */
- (void)showAccessoryView:(UIView *)thisView 
		hideAccessoryView:(UIView *)otherView 
			   fullScreen:(BOOL)fullScreen
			flipDirection:(UIViewAnimationOptions)flipDirection;

/**
 *  Toggles the accessory view between full screen and split screen layout.
 */
- (void)toggleAccessoryViewSize;

/**
 *  Toggles between showing and hiding the accessory view and, optionally, 
 *  two subviews of the accessory view.
 *
 *  If accessoryViewHidden is YES, this method will:
 *    <li>show the accessory view in split screen by starting a slide animation
 *    <li>if thisView is not nil, set its hidden property to NO
 *    <li>if otherView is not nil, set its hidden property to YES
 *
 *  If accessoryViewHidden is NO and thisView is hidden, this method will:
 *    <li>start a flip animation that shows thisView and hides otherView
 *
 *  Otherwise, this method will:
 *    <li>hide the accessory view by starting a slide animation
 *
 *  @param thisView      A subview of the accessory view that is to be shown,
 *                       or nil to show/hide the accessory view without a subview
 *  @param otherView     A subview of the accessory view that is to be hidden,
 *                       or nil to show/hide the accessory view without a subview
 *  @param flipDirection When toggling between thisView and otherView, this
 *                       specifies the direction for the flip animation
 */
- (void)toggleAccessoryView:(UIView *)thisView 
		 otherAccessoryView:(UIView *)otherView 
			  flipDirection:(UIViewAnimationOptions)flipDirection;

/**
 *  Sent to the AccessoryViewController whenever the frame of the main view
 *  changes. Subclasses may override this method to take additional actions
 *  immediately after the change.
 */
- (void)layoutMainView;

@end
