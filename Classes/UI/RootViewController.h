//
//  RootViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AddConnectionViewController.h"

@class CameraInfoWrapper;
@class CredentialsViewController;
@class LocationStatusBarButtonItem;
@class SelectableBarButtonItem;
@class ViewerInfo;


/**
 *  Parent class for RealityVision's root view controller.  The specific
 *  view controller used depends on whether the client is running on an
 *  iPhone or an iPad.
 */
@interface RootViewController : UIViewController < UINavigationControllerDelegate,
												   UIAlertViewDelegate,
                                                   AddConnectionDelegate >

/**
 *  Indicates whether the main mapping view is tracking the user's location by keeping the
 *  map centered on the location.
 */
@property (nonatomic) BOOL isTrackingLocation;

/**
 *  Indicates whether the main mapping view is keeping the map centered on the currently
 *  displayed cameras.
 */
@property (nonatomic) BOOL isCenteredOnCameras;

/**
 *  Indicates whether the main mapping view shows labels for users and video sources.
 */
@property (nonatomic) BOOL showLabels;

/**
 *  Indicates whether the sign on/off button is enabled.
 */
@property (nonatomic) BOOL signOnOffEnabled;

/**
 *  Used to indicate that the startup process is complete and the user has been verified
 *  as signed on.  Note that this is only used during initial program launch because in
 *  that case the RealityVisionClient indicates the user is signed on but we don't want
 *  to start making server requests until that has been verified.
 *  
 *  The default implementation of this does nothing.  Subclasses can override it to
 *  start making server requests necessary for their own UI.
 */
- (void)didVerifySignOn;

/**
 *  Toggles the current sign on state.  Before signing off, prompts the user to verify that
 *  s/he really wants to sign off.
 */
- (void)signOnOrOff;

/**
 *  Specifies whether to show the "Connecting" view used while the RealityVisionClient is signing on.
 *
 *  @param connecting Indicates whether the client is signing on.
 */
- (void)showConnecting:(BOOL)connecting;

/**
 *  Specifies whether to adjust the user interface to indicate that there is no available
 *  network connection.
 *  
 *  @param networkDisconnected YES if there is no available network connection.
 */
- (void)showNetworkDisconnected:(BOOL)networkDisconnected;

/**
 *  Updates the view for a change in location awareness.
 *  
 *  @param locationAware Indicates whether the client is tracking the user's location.
 */
- (void)updateLocationAware:(BOOL)locationAware;

/**
 *  Updates the view for a change in the sign on status.
 *
 *  @param signedOn Indicates whether the client is signed on.
 */
- (void)updateSignOnStatus:(BOOL)signedOn;

/**
 *  Shows the credentials view controller.
 */
- (void)showCredentialsViewController:(CredentialsViewController *)viewController;

/**
 *  Dismisses the credentials view controller.
 */
- (void)dismissCredentialsViewController;

/**
 *  Alerts the user that there is no connection profile.
 */
- (void)showNoConfigurationsAlert;

/**
 *  Alerts the user that there are unread commands.
 */
- (void)showNewCommandsAlert;

/**
 *  Alerts the user that the client has reached its maximum allowable video streaming 
 *  time over a cellular network.
 *  
 *  @param delegate The UIAlertViewDelegate to notify when the user selects OK.
 */
- (void)showMaxVideoStreamingAlertWithDelegate:(id)delegate;

/**
 *  Allows the user to add or edit the connection profile.
 */
- (void)showAddConnectionView; 

/**
 *  Prompts the user to verify that they really want to sign off.
 */
- (void)showSignOffAlert;

/**
 *  Displays the command inbox.
 */
- (void)showCommandInbox;

/**
 *  Displays the video feed for the given camera.
 */
- (void)showVideo:(CameraInfoWrapper *)camera;

/**
 *  Displays the video feed for the camera represented by the map annotation view.
 */
- (void)showVideoForAnnotationView:(MKAnnotationView *)view;

/**
 *  Displays the list of video feeds being viewed by the user associated with the map annotation view.
 */
- (void)showViewedFeedsForAnnotationView:(MKAnnotationView *)view;

/**
 *  Starts the share video process.
 */
- (void)shareVideo:(CameraInfoWrapper *)camera fromView:(UIView *)videoView;

/**
 *  Resets the Push-To-Talk Talk button. This should be called whenever a UIAlertView is about
 *  to be displayed since iOS does not deliver a touch up event in that case.
 */
- (void)resetPttTalkButton;

/**
 *  Displays the settings view controller.
 *  
 *  This method must be implemented by a subclass.
 */
- (IBAction)showSettings;

/**
 *  Displays the sign on schedule view controller.
 */
- (IBAction)showSchedule;

/**
 *  Displays the about RealityVision view controller.
 */
- (IBAction)showAboutDialog;

/**
 *  Pops all the view controllers on the navigation controller's stack except the root view 
 *  controller.
 */
- (void)showRootView;


// Interface Builder outlets
@property (strong, nonatomic) IBOutlet UIBarButtonItem             * statusButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem             * settingsButton;
@property (strong, nonatomic) IBOutlet LocationStatusBarButtonItem * locationStatusButton;
@property (strong, nonatomic) IBOutlet SelectableBarButtonItem     * trackLocationButton;
@property (strong, nonatomic) IBOutlet SelectableBarButtonItem     * centerOnButton;
@property (strong, nonatomic) IBOutlet SelectableBarButtonItem     * showLabelsButton;
@property (weak, nonatomic)   IBOutlet UIView                      * disabledOverlay;
@property (weak, nonatomic)   IBOutlet UIView                      * connectingView;
@property (weak, nonatomic)   IBOutlet UIView                      * noNetworkView;

@end
