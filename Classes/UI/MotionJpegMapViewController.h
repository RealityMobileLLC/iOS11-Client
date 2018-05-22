//
//  MotionJpegMapViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AccessoryViewController.h"
#import "MotionJpegStream.h"
#import "VideoControlsView.h"
#import "PanTiltZoomControlsView.h"
#import "WatchOptionsView.h"
#import "CommentDetailViewController.h"
#import "EnterCommentViewController.h"
#import "RecipientSelectionViewController.h"
#import "ClientTransaction.h"
#import "FavoritesManager.h"

@class CameraInfoWrapper;
@class SelectableBarButtonItem;
@class CameraSideMapViewDelegate;


/**
 *  View Controller used to display a Motion JPEG feed along with a map.
 */
@interface MotionJpegMapViewController : AccessoryViewController < UIAlertViewDelegate, 
                                                                   UIActionSheetDelegate,
                                                                   UITableViewDataSource,
                                                                   UITableViewDelegate,
                                                                   MotionJpegStreamDelegate,
                                                                   VideoControlsDelegate,
                                                                   HideControlsTimer,
                                                                   WatchOptionsDelegate,
                                                                   FrameCommentDelegate,
                                                                   EnterCommentDelegate,
                                                                   VideoSharingDelegate,
                                                                   FavoritesObserver,
                                                                   ClientTransactionDelegate >

/**
 *  The camera to view.
 */
@property (nonatomic,strong) CameraInfoWrapper * camera;


// Interface Builder outlets
@property (nonatomic,weak) IBOutlet UIView                  * watchView;
@property (nonatomic,weak) IBOutlet UIActivityIndicatorView * connectingIndicator;
@property (nonatomic,weak) IBOutlet UIButton                * replayButton;
@property (nonatomic,weak) IBOutlet UILabel                 * endOfVideoLabel;

- (IBAction)replayVideo;

@end
