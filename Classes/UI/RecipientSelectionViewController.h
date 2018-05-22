//
//  RecipientSelectionViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/15/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserStatusService.h"

@class CameraInfoWrapper;


/**
 *  Protocol used by the RecipientSelectionViewController to indicate when
 *  the video sharing process has completed.
 */
@protocol VideoSharingDelegate

/**
 *  Indicates that the video sharing process has been completed or cancelled.
 */
- (void)didCompleteVideoSharing;

@end


/**
 *  View Controller used to get a list of recipients to whom a command will be sent.
 *  
 *  This view controller is intended to always be displayed in a UINavigationController.  If
 *  presented modally or in a popover, it should first be wrapped in a UINavigationController.
 */
@interface RecipientSelectionViewController : UITableViewController <UserStatusServiceDelegate>

/**
 *  Delegate to notify when video sharing has completed and this view controller can be
 *  dismissed.
 */
@property (nonatomic,weak) id <VideoSharingDelegate> delegate;

/**
 *  Indicates whether RecipientSelectionViewController should put a Cancel button in its
 *  navigationItem's leftBarButtonItem.  Defaults to NO.
 */
@property (nonatomic) BOOL showCancelButton;

/**
 *  Indicates that the view controller will only allow landscape orientation.
 */
@property (nonatomic) BOOL restrictToLandscapeOrientation;

/**
 *  The video feed to share.  This can only be nil if shareCurrentTransmitSession is YES.
 */
@property (strong, nonatomic) CameraInfoWrapper * camera;

/**
 *  The start time of the portion of the video feed to share, or nil to share a live feed
 *  or an entire archive feed.
 */
@property (strong, nonatomic) NSDate * shareVideoStartTime;

/**
 *  Indicates that the video feed to share is this device's current transmit session.
 *  If this is YES, camera must be nil.
 */
@property (nonatomic) BOOL shareCurrentTransmitSession;

/**
 *  If shareCurrentTransmitSession is YES, this indicates whether it's the live feed or the
 *  archive starting from the beginning of the transmit session that is shared.
 */
@property (nonatomic) BOOL shareCurrentTransmitSessionFromBeginning;

/**
 *  An array of Recipient objects containing the selected recipients.
 */
@property (strong, nonatomic,readonly) NSArray * recipients;

/**
 *  Indicates the share video process is complete and the view controller should go away.
 */
- (void)done;

@end
