//
//  NotificationViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/5/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"

@class CommandWrapper;


/**
 *  View Controller used to display information about a RealityVision Command.
 *
 *  The caller must set the command property before displaying this view.
 *
 *  The name of this class is used to indicate that the displayed view is called
 *  a "Command Notification" on other RealityVision client platforms.  On the
 *  iPhone, however, the actual command notification is presented by iOS remote
 *  notification.
 *
 *  The view displayed by this view controller contains the information about
 *  the command but does not require the user to Accept or Dismiss because that
 *  has already been done.
 */
@interface NotificationViewController : UIViewController <DownloadDelegate, UIDocumentInteractionControllerDelegate>

/**
 *  The command to be displayed.
 */
@property (strong, nonatomic) CommandWrapper * command;

// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UIScrollView * scrollView;
@property (weak, nonatomic) IBOutlet UILabel      * toFromLabel;
@property (weak, nonatomic) IBOutlet UILabel      * toFromNamesLabel;
@property (weak, nonatomic) IBOutlet UILabel      * sentLabel;
@property (weak, nonatomic) IBOutlet UILabel      * sentTimeLabel;
@property (weak, nonatomic) IBOutlet UIView       * bodyView;

@end
