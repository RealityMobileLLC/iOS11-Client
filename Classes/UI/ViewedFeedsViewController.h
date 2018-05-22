//
//  ViewedFeedsViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/1/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserMapAnnotationView;
@class ViewerInfo;
@class CameraTableViewCell;
@class ViewedFeedsViewController;


/**
 *  Protocol used by the ViewedFeedsViewController to notify a delegate when the user selects
 *  a video feed to watch.
 */
@protocol ViewedFeedsDelegate <NSObject>

- (void)showViewedVideo:(ViewerInfo *)camera forAnnotationView:(UserMapAnnotationView *)annotationView;

- (void)dismissViewedFeedsView:(ViewedFeedsViewController *)view;

@end


/**
 *  View Controller responsible for displaying a list of ViewerInfo objects representing
 *  video feeds being watched by a user.
 */
@interface ViewedFeedsViewController : UITableViewController

/**
 *  The map object representing the user watching the video feeds.
 */
@property (nonatomic,strong) UserMapAnnotationView * userMapAnnotationView;

/**
 *  Delegate to notify when the user selects a video feed to watch.
 */
@property (nonatomic,weak) id<ViewedFeedsDelegate> delegate;

/**
 *  Popover Controller that contains this view controller.
 */
@property (nonatomic,weak) UIPopoverController * popoverController;

@end
