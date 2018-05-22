//
//  TransmitViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/25/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransmitPreferencesViewController.h"
#import "EnterCommentViewController.h"
#import "RecipientSelectionViewController.h"

#if TARGET_OS_EMBEDDED
#import <AVFoundation/AVFoundation.h>
// @todo #import "HeadRequest.h"
#import "MotionJpegTransmitClient.h"
#endif


/**
 *  Protocol used by the TransmitViewController class to notify when transmit
 *  has finished.
 */
@protocol TransmitViewDelegate

/**
 *  Indicates that the TransmitViewController has stopped transmitting.
 */
- (void)didStopTransmitting;

@end


/**
 *  View Controller that manages a video transmit session.
 */
@interface TransmitViewController : UIViewController 
										< TransmitPreferencesDelegate,
                                          EnterCommentDelegate,
                                          VideoSharingDelegate,
                                          UIActionSheetDelegate
#if TARGET_OS_EMBEDDED
                                          , AVCaptureVideoDataOutputSampleBufferDelegate 
                                          // @todo , HeadRequestDelegate 
                                          , TransmitClientDelegate
#endif
                                        >

/**
 *  Delegate to notify when transmit complete.
 */
@property (nonatomic,weak) id <TransmitViewDelegate> delegate;

/**
 *  Stops transmit session in progress and gets comments from the user.
 */
- (void)stopAndGetComments:(BOOL)getComments;

#ifdef RV_TRANSMIT_BACKGROUND
/**
 *  Schedules a local notification to prompt user that a transmit session
 *  is about to end while running in the background.
 */
- (void)scheduleBackgroundNotification;

/**
 *  Cancels the local notification when the app returns to the foreground.
 */
- (void)cancelBackgroundNotification;
#endif

// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UIToolbar   * toolbar;
@property (weak, nonatomic) IBOutlet UIImageView * imageView;
@property (weak, nonatomic) IBOutlet UIView      * statisticsView;
@property (weak, nonatomic) IBOutlet UILabel     * frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel     * bitRateLabel;

- (IBAction)doneButtonPressed;
- (IBAction)shareButtonPressed:(id)sender;
- (IBAction)cameraButtonPressed;
- (IBAction)preferencesButtonPressed;

@end
