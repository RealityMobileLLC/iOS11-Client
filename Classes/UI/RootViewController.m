//
//  RootViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import "RootViewController.h"
#import <AudioToolbox/AudioServices.h>
#import "CameraInfoWrapper.h"
#import "RealityVisionClient.h"
#import "LocationStatusBarButtonItem.h"
#import "SelectableBarButtonItem.h"
#import "AboutViewController.h"
#import "CommandInboxViewController.h"
#import "MotionJpegMapViewController.h"
#import "RealityVisionMapAnnotationView.h"
#import "ScheduleViewController.h"
#import "ConnectionDatabase.h"
#import "ScheduleManager.h"
#import "RealityVisionAppDelegate.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


enum 
{
    CONFIGURATION_ALERT_TAG,
    SIGN_OFF_ALERT_TAG,
    COMMANDS_ALERT_TAG
};


@implementation RootViewController

@synthesize statusButton;
@synthesize settingsButton;
@synthesize locationStatusButton;
@synthesize trackLocationButton;
@synthesize centerOnButton;
@synthesize showLabelsButton;
@synthesize disabledOverlay;
@synthesize connectingView;


#pragma mark - Initialization and cleanup

- (NSArray *)createToolbarItems
{
	// subclasses should override this to get a toolbar
    return nil;
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"RootViewController viewDidLoad");
    [super viewDidLoad];
	self.title = [RealityVisionAppDelegate appName];
	self.toolbarItems = [self createToolbarItems];
	self.navigationController.delegate = self;
	
	//if (self.toolbarItems != nil)
	//{
	//	self.navigationController.toolbarHidden = NO;
	//}
	
	// register for new command notifications so we can dismiss modal views that will hide the command
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(willDisplayCommandNotification:) 
												 name:RvWillDisplayCommandNotification 
											   object:nil];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"RootViewController viewDidUnload");
    [super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:RvWillDisplayCommandNotification 
												  object:nil];
	
    statusButton = nil;
	settingsButton = nil;
    locationStatusButton = nil;
    trackLocationButton = nil;
    centerOnButton = nil;
    showLabelsButton = nil;
    disabledOverlay = nil;
    connectingView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    DDLogVerbose(@"RootViewController viewWillAppear");
    [super viewWillAppear:animated];
	
	RealityVisionClient * client = [RealityVisionClient instance];
	[self updateSignOnStatus:client.isSignedOn];
	[self showConnecting:client.isConnecting];
	[self showNetworkDisconnected:(client.networkStatus == NotReachable)];
	
	// register for state changes in realityvision client
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"isConnecting"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"isSignedOn"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"isLocationAware"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"networkStatus"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
}

- (void)viewDidAppear:(BOOL)animated
{
    DDLogVerbose(@"RootViewController viewDidAppear");
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"RootViewController viewWillDisappear");
    [super viewWillDisappear:animated];
    [[RealityVisionClient instance] removeObserver:self forKeyPath:@"isSignedOn"];
    [[RealityVisionClient instance] removeObserver:self forKeyPath:@"isLocationAware"];
}

- (void)viewDidDisappear:(BOOL)animated
{
    DDLogVerbose(@"RootViewController viewDidDisappear");
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - UINavigationControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController 
	  willShowViewController:(UIViewController *)viewController 
					animated:(BOOL)animated
{
	if ((navigationController.toolbarHidden) && (viewController.toolbarItems != nil))
	{
		[navigationController setToolbarHidden:NO animated:animated];
	}
	else if ((! navigationController.toolbarHidden) && (viewController.toolbarItems == nil))
	{
		[navigationController setToolbarHidden:YES animated:animated];
	}
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != 0)
	{
		if (alertView.tag == CONFIGURATION_ALERT_TAG)
		{
			[self showAddConnectionView];
		}
		else if (alertView.tag == SIGN_OFF_ALERT_TAG)
		{
			[[RealityVisionClient instance] signOff];
		}
		else if (alertView.tag == COMMANDS_ALERT_TAG)
		{
			[self showCommandInbox];
		}
	}
	else if (alertView.tag == CONFIGURATION_ALERT_TAG)
	{
		// user cancelled when prompted to enter a new configuration, so reenable sign on button
		self.statusButton.enabled = YES;
	}
}


#pragma mark - Properties

- (LocationStatusBarButtonItem *)locationStatusButton
{
	if (locationStatusButton == nil)
	{
		locationStatusButton = [[LocationStatusBarButtonItem alloc] initWithLocationProvider:[RealityVisionClient instance]];
		locationStatusButton.enabled = NO;
	}
	return locationStatusButton;
}

- (BOOL)isTrackingLocation
{
    return self.trackLocationButton.on;
}

- (void)setIsTrackingLocation:(BOOL)isTrackingLocation
{
    self.trackLocationButton.on = isTrackingLocation;
}

- (BOOL)isCenteredOnCameras
{
    return self.centerOnButton.on;
}

- (void)setIsCenteredOnCameras:(BOOL)isCenteredOnCameras
{
	self.centerOnButton.on = isCenteredOnCameras;
}

- (BOOL)showLabels
{
    return [RealityVisionMapAnnotationView showSourceNames];
}

- (void)setShowLabels:(BOOL)showLabels
{
    self.showLabelsButton.on = showLabels;
    [RealityVisionMapAnnotationView setShowSourceNames:showLabels];
}

- (BOOL)signOnOffEnabled
{
    return self.statusButton.enabled;
}

- (void)setSignOnOffEnabled:(BOOL)signOnOffEnabled
{
    self.statusButton.enabled = signOnOffEnabled;
}


#pragma mark - Button action callbacks

- (void)signOnOrOff
{
	BOOL signOn = ! [RealityVisionClient instance].isSignedOn;
	
	if (signOn)
	{
		[self.statusButton setEnabled:NO];
		[[RealityVisionClient instance] signOn];
	}
	else 
	{
        [self showSignOffAlert];
	}
}

- (IBAction)statusButtonPressed
{
	DDLogInfo(@"Sign on/off pressed");
	[self signOnOrOff];
}

- (IBAction)showSchedule
{
	ScheduleManager * scheduleManager = [ScheduleManager instance];
	ScheduleViewController * viewController = [[ScheduleViewController alloc] initWithNibName:@"ScheduleViewController" 
																					   bundle:nil];
	viewController.scheduleDelegate = scheduleManager;
	viewController.schedule = scheduleManager.schedule;
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
	[rootViewController presentViewController:navigationController animated:YES completion:NULL];
}

- (IBAction)showAboutDialog
{
	AboutViewController * aboutDialog = [[AboutViewController alloc] initWithNibName:@"AboutViewController" 
																			  bundle:nil];
	RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
	[rootViewController presentViewController:aboutDialog animated:YES completion:NULL];
}

- (IBAction)trackLocationButtonPressed
{
	// subclasses can override this to specialize behavior
    [self doesNotRecognizeSelector:_cmd];
}

- (IBAction)centerOnButtonPressed
{
	// subclasses can override this to specialize behavior
    [self doesNotRecognizeSelector:_cmd];
}

- (IBAction)showLabelsButtonPressed
{
	// subclasses can override this to specialize behavior
    [self doesNotRecognizeSelector:_cmd];
}

- (IBAction)showSettings
{
	// subclasses can override this to specialize behavior
    [self doesNotRecognizeSelector:_cmd];
}

- (void)resetPttTalkButton
{
	// subclasses can override this to specialize behavior
}

- (void)showRootView
{
	DDLogInfo(@"RootViewController showRootView");
	[self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Connection profile management

- (void)showNoConfigurationsAlert
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Configuration",@"Configuration alert") 
													 message:NSLocalizedString(@"A configuration entry is required. Without a configuration entry most features of the application will be disabled. Create a configuration?", @"Configuration required text")
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") 
										   otherButtonTitles:NSLocalizedString(@"OK",@"OK"), nil];
	alert.tag = CONFIGURATION_ALERT_TAG;
    [alert show];
}

- (void)showAddConnectionView 
{
	AddConnectionViewController * viewController = 
		[[AddConnectionViewController alloc] initWithNibName:@"AddConnectionViewController" 
													   bundle:nil];
	viewController.addConnectionDelegate = self;
	viewController.connection = [ConnectionDatabase activeProfile];
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	[self presentViewController:navigationController animated:YES completion:NULL];
}

- (void)connectionAdded:(ConnectionProfile *)connection
{
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	if (connection == nil)
	{
		// user cancelled so reenable the sign on button
		self.statusButton.enabled = YES;
	}
	else if (! [RealityVisionClient instance].isSignedOn)
	{
		DDLogInfo(@"Connection Added");
		[[RealityVisionClient instance] signOn];
	}
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"isConnecting"])
	{
		BOOL isConnecting;
		NSValue * isConnectingValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (isConnectingValue != nil)
		{
			[isConnectingValue getValue:&isConnecting];
			[self showConnecting:isConnecting];
		}
    }
    else if ([keyPath isEqual:@"isSignedOn"])
	{
		BOOL isSignedOn;
		NSValue * isSignedOnValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (isSignedOnValue != nil)
		{
			//			BOOL isSignedOn;			// Don't declare here.  Bug in iPad simulator
			[isSignedOnValue getValue:&isSignedOn];
			[self updateSignOnStatus:isSignedOn];
		}
    }
    else if ([keyPath isEqual:@"isLocationAware"])
	{
		// don't change location status unless signed on
		if ([RealityVisionClient instance].isSignedOn)
		{
			NSValue * isLocationAwareValue = [change objectForKey:NSKeyValueChangeNewKey];
			if (isLocationAwareValue != nil)
			{
				BOOL isLocationAware;
				[isLocationAwareValue getValue:&isLocationAware];
				[self updateLocationAware:isLocationAware];
			}
		}
    }
    else if ([keyPath isEqual:@"networkStatus"])
	{
		NSValue * networkStatusValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (networkStatusValue != nil)
		{
			NetworkStatus networkStatus;
			[networkStatusValue getValue:&networkStatus];
			[self showNetworkDisconnected:(networkStatus == NotReachable)];
		}
    }
}


#pragma mark - Other

- (void)didVerifySignOn
{
    // subclasses can override this method to specialize behavior during startup
}

- (void)showConnecting:(BOOL)connecting;
{
	self.connectingView.hidden = self.statusButton.enabled = ! connecting;
}

- (void)showNetworkDisconnected:(BOOL)networkDisconnected
{
	self.disabledOverlay.hidden = (! networkDisconnected) && [RealityVisionClient instance].isSignedOn;
	self.noNetworkView.hidden = ! networkDisconnected;
}

- (void)updateLocationAware:(BOOL)locationAware
{
	self.trackLocationButton.enabled = locationAware;
}

- (void)updateSignOnStatus:(BOOL)signedOn
{
	self.disabledOverlay.hidden = signedOn;
	self.centerOnButton.enabled = signedOn;
    self.trackLocationButton.enabled = signedOn && [RealityVisionClient instance].isLocationAware;
    self.showLabelsButton.enabled = signedOn;
    self.locationStatusButton.enabled = signedOn;
	self.statusButton.title = (signedOn) ? NSLocalizedString(@"Sign off",@"Sign off button") 
                                         : NSLocalizedString(@"Sign on",@"Sign on button");
}

- (void)showCredentialsViewController:(CredentialsViewController *)viewController
{
	// subclasses can override this to specialize behavior
}

- (void)dismissCredentialsViewController
{
	// subclasses can override this to specialize behavior
}

- (void)showNewCommandsAlert
{
	[self resetPttTalkButton];
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Commands",@"Commands alert") 
													 message:NSLocalizedString(@"You have unread commands available.",
																			   @"Unread commands available text")
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Close",@"Close") 
										   otherButtonTitles:NSLocalizedString(@"View",@"View"), nil];
	alert.tag = COMMANDS_ALERT_TAG;
    [alert show];
}

- (void)showSignOffAlert
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign Off",@"Sign off alert") 
													 message:NSLocalizedString(@"Are you sure you want to sign off?",@"Sign off prompt")
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") 
										   otherButtonTitles:NSLocalizedString(@"OK",@"OK"), nil];
    alert.tag = SIGN_OFF_ALERT_TAG;
    [alert show];
}

- (void)showMaxVideoStreamingAlertWithDelegate:(id)delegate
{
	AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
	[self resetPttTalkButton];
	
	UIAlertView * alert = 
		[[UIAlertView alloc] initWithTitle:[RealityVisionAppDelegate appName]
								   message:NSLocalizedString(@"Video streaming over a cellular network is limited to 10 minutes per video session. Your video session has ended.", 
															 @"Video streaming over a cellular network has reached its limit message")
								  delegate:delegate 
						 cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
						 otherButtonTitles:nil];
	[alert show];
}

- (void)showCommandInbox
{
	// notify observers that a new command notification is about to be displayed ...
	// they should dismiss modals (except transmit) and any existing command notifications
	[[NSNotificationCenter defaultCenter] postNotificationName:RvWillDisplayCommandNotification object:self];
	
    CommandInboxViewController * commandInboxViewController = 
        [[CommandInboxViewController alloc] initWithNibName:@"CommandHistoryViewController" 
                                                 bundle:nil];
    [self.navigationController pushViewController:commandInboxViewController animated:YES];
}

- (void)showVideo:(CameraInfoWrapper *)camera
{
	MotionJpegMapViewController * viewController = 
        [[MotionJpegMapViewController alloc] initWithNibName:@"MotionJpegMapViewController" 
                                                       bundle:nil];
	viewController.camera = camera;
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void)showVideoForAnnotationView:(MKAnnotationView *)view
{
    id <MapObject> camera = (id <MapObject>)view.annotation;
	[self showVideo:camera.camera];
}

- (void)showViewedFeedsForAnnotationView:(MKAnnotationView *)view
{
	// subclasses can override this to specialize behavior
}

- (void)shareVideo:(CameraInfoWrapper *)camera fromView:(UIView *)videoView
{
	// subclasses can override this to specialize behavior
}

- (void)willDisplayCommandNotification:(NSNotification *)notification
{
	DDLogInfo(@"RootViewController willDisplayCommandNotification");
	UIViewController * modalViewController = self.navigationController.topViewController.modalViewController;
	
	// dismiss any active modal view controller except those related to transmit
	if (modalViewController && 
		! ([modalViewController isKindOfClass:[TransmitViewController class]] ||
		   [modalViewController isKindOfClass:[EnterCommentViewController class]]))
	{
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

@end
