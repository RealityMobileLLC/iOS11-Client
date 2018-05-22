//
//  PushToTalkBar.h
//  Cannonball
//
//  Created by Thomas Aylesworth on 3/23/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PttChannelInteractions;


/**
 *  The PushToTalkBarDelegate protocol is used to notify a delegate when the user wishes to
 *  select a new channel, and to let the PushToTalkBar know about the joined channel.
 */
@protocol PushToTalkBarDelegate

/**
 *  The currently joined channel, or nil if no channel has been joined.
 */
@property (nonatomic,strong,readonly) NSObject <PttChannelInteractions> * channel;

/**
 *  Sent when the user selects the Channel button.
 */
- (void)pttBarChannelButtonPressed;

@end


/**
 *  A PushToTalkBar is a view that implements the UI for Push-To-Talk functionality. It 
 *  observes state changes for the specified channel and will interact with that channel
 *  based on user selections. It will also notify its delegate when the user wants to
 *  select a new channel.
 *  
 *  The Talk button on the PushToTalkBar operates in one of two modes, depending on the
 *  TalkButtonToggles setting. If set to YES (Toggle mode), the user taps the control once
 *  to start talking and taps again to stop talking. If set to NO (Hold mode), the user
 *  must continuously hold down the control to talk.
 *  
 *  Because the control can't recognize when its view controller has disappeared, the
 *  viewWillDisappear: method should be called by any view controller that manage a 
 *  PushToTalkBar. This is used to reset the Talk button if it was actively being pressed
 *  in Hold mode.
 */
@interface PushToTalkBar : UIView

/**
 *  The delegate to notify when the user wants to select a new channel.
 */
@property (nonatomic,weak) NSObject <PushToTalkBarDelegate> * delegate;

/**
 *  Indicates whether the PushToTalkBar is enabled.  This primarily affects the Channel
 *  button which will be enabled or disabled based on this setting.
 */
@property (nonatomic) BOOL enabled;

/**
 *  Returns an initialized PushToTalkBar object with the desired frame.
 */
- (id)initWithFrame:(CGRect)frame;

/**
 *  Updates the frame of the receiver for the desired interface orientation and resizes the
 *  adjacentView.  The receiver is always below adjacentView in portrait orientation and
 *  to the right of adjacentView is landscape orientation.
 *  
 *  Note that both the receiver and the adjacentView must share the same superview.  The
 *  superview's bounds are used to layout both views.
 *  
 *  @param adjacentView View that is adjacent to the receiver.
 *  @param interfaceOrientation New orientation for the receiver.
 */
- (void)layoutPttBarAndResizeView:(UIView *)adjacentView 
		  forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation; 

/**
 *  Hides or shows the receiver and resizes the adjacentView.
 *  
 *  Note that both the receiver and the adjacentView must share the same superview.  The
 *  superview's bounds are used to layout both views.
 *  
 *  @param hidden Indicates whether view is to be hidden or shown.
 *  @param adjacentView View that is adjacent to the receiver.
 *  @param interfaceOrientation Interface orientation for the receiver.
 *  @param animated Indicates whether the transition should be animated.
 */
-         (void)hide:(BOOL)hidden 
       andResizeView:(UIView *)adjacentView 
interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
			animated:(BOOL)animated;

/**
 *  Should be called by the managing view controller to reset the state of the Talk button
 *  if it is actively being pressed in Hold mode.
 */
- (void)resetTalkButton;

@end
