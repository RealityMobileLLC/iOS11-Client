//
//  PushToTalkControl.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PttChannelInteractions;


/**
 *  A PushToTalkControl is a view that implements the UI for Push-To-Talk functionality on the
 *  iPad.  Unlike the PushToTalkBar class used on the iPhone, the PushToTalkControl only provides
 *  talk and mute functionality.  It does not provide for channel selection.
 */
@interface PushToTalkControl : UIView

/**
 *  The currently joined channel, or nil if no channel has been joined.  When set to nil, the
 *  PushToTalkControl will hide itself.
 */
@property (nonatomic,strong) NSObject <PttChannelInteractions> * channel;

/**
 *  Returns an initialized PushToTalkControl object that has been added as a subview to the given
 *  superview.
 */
- (id)initWithSuperview:(UIView *)superview;

/**
 *  Should be called by the managing view controller to reset the state of the Talk button
 *  if it is actively being pressed in Hold mode.
 */
- (void)resetTalkButton;

@end
