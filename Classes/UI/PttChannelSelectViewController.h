//
//  PttChannelSelectViewController.h
//  Cannonball
//
//  Created by Thomas Aylesworth on 3/27/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  The PttChannelSelectionDelegate protocol is used to notify a delegate when the user has
 *  selected a Push-to-Talk channel to join.
 */
@protocol PttChannelSelectionDelegate

/**
 *  Sent to delegate when the user has selected a new Push-to-Talk channel (i.e., one other
 *  than the currently selected channel).
 *  
 *  @param channel Name of Push-to-Talk channel to join, or nil for "Off" channel.
 */
- (void)pttChannelSelected:(NSString *)channel;

/**
 *  Sent to delegate when the user cancels channel selection or selects the currently
 *  selected channel.
 */
- (void)pttChannelSelectionCancelled;

@end


/**
 *  View controller that displays a list of available Push-to-Talk channels, along with an
 *  option for an "Off" channel.
 */
@interface PttChannelSelectViewController : UITableViewController

/**
 *  The delegate to notify when the user selects a channel.
 */
@property (nonatomic,weak) id <PttChannelSelectionDelegate> delegate;

/**
 *  Indicates whether RecipientSelectionViewController should put a Cancel button in its
 *  navigationItem's leftBarButtonItem.  Defaults to NO.
 */
@property (nonatomic) BOOL showCancelButton;

/**
 *  Returns an initialized PttChannelSelectViewController with a list of available channels
 *  and the currently selected channel.
 *  
 *  @param channels        An array of Channel objects corresponding to the available PTT channels.
 *                         There MUST be at least one element in this array.
 *  @param selectedChannel The name of the currently selected PTT channel, or nil to indicate the 
 *                         "Off" channel.
 *  @return an initialized PttChannelSelectViewController
 */
- (id)initWithAvailableChannels:(NSArray *)channels selectedChannel:(NSString *)selectedChannel;

@end
