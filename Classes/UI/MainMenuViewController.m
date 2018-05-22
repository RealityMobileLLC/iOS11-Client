//
//  MainMenuViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import "MainMenuViewController.h"
#import "MainMenuTableView.h"
#import "MenuTableViewCell.h"
#import "SystemUris.h"
#import "ConfigurationManager.h"
#import "CredentialsViewController.h"
#import "LocationSettingsViewController.h"
#import "SelectableBarButtonItem.h"
#import "UIView+Layout.h"
#import "PttChannelManager.h"
#import "PushToTalkController.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation MainMenuViewController
{
	MainMenuTableView * menu;
	PushToTalkBar     * pttBar;
	BOOL                isSignOnOffAvailable;
}

@synthesize tableView;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"MainMenuViewController viewDidLoad");
    [super viewDidLoad];
	
	UIBarButtonItem * settingsButton = 
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
													  target:self 
													  action:@selector(showSettings)];
	
    self.navigationItem.rightBarButtonItem = settingsButton;
	self.navigationItem.leftBarButtonItem = self.locationStatusButton;
	
	menu = [[MainMenuTableView alloc] init];
	self.tableView.delegate = menu;
	self.tableView.dataSource = menu;
	
	[self.tableView registerNib:[UINib nibWithNibName:@"MenuTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[MenuTableViewCell reuseIdentifier]];
	
	pttBar = [[PushToTalkBar alloc] initWithFrame:CGRectMake(0, 356, 320, 60)];
	pttBar.delegate = [PushToTalkController instance];
	[self.view addSubview:pttBar];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"MainMenuViewController viewDidUnload");
    [super viewDidUnload];
	tableView = nil;
	pttBar = nil;
}

- (void)viewWillAppear:(BOOL)animated 
{
	DDLogVerbose(@"MainMenuViewController viewWillAppear");
    [super viewWillAppear:animated];
	
	// layout ptt view
	pttBar.hidden = (! [RealityVisionClient instance].isSignedOn) || ([[PttChannelManager instance].channels count] == 0);
	[pttBar layoutPttBarAndResizeView:self.tableView forInterfaceOrientation:self.interfaceOrientation];
    
	// register for changes to command count
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"inboxCommandCount"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
	// register for changes to available channels
	[[PttChannelManager instance] addObserver:self 
								   forKeyPath:@"channels" 
									  options:NSKeyValueObservingOptionNew 
									  context:NULL];
	
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"MainMenuViewController viewWillDisappear");
    [super viewWillDisappear:animated];
	[pttBar resetTalkButton];
    [[RealityVisionClient instance] removeObserver:self forKeyPath:@"inboxCommandCount"];
	[[PttChannelManager instance] removeObserver:self forKeyPath:@"channels"];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	if (! pttBar.hidden)
	{
		[pttBar layoutPttBarAndResizeView:self.tableView forInterfaceOrientation:interfaceOrientation];
	}
}


#pragma mark - Button action callbacks

- (IBAction)showSettings
{
	UIActionSheet * actionMenu;
	NSString * scheduleButton = NSLocalizedString(@"Schedule",@"Schedule menu item");
	NSString * locationButton = NSLocalizedString(@"Location",@"Location menu item");
	NSString * aboutButton    = NSLocalizedString(@"About",@"About menu item");
	NSString * cancelButton   = NSLocalizedString(@"Cancel",@"Cancel menu item");
	
	isSignOnOffAvailable = [RealityVisionClient instance].networkStatus != NotReachable;
	
	if (isSignOnOffAvailable)
	{
		BOOL isSignedOn = [RealityVisionClient instance].isSignedOn;
		NSString * signOnOffButton = isSignedOn ? NSLocalizedString(@"Sign Off",@"Sign Off menu item")
		                                        : NSLocalizedString(@"Sign On",@"Sign On menu item");
		
		// note that button order must match order in actionSheet:clickedButtonAtIndex:
		actionMenu = [[UIActionSheet alloc] initWithTitle:nil
												 delegate:self
										cancelButtonTitle:cancelButton
								   destructiveButtonTitle:nil
										otherButtonTitles:signOnOffButton,scheduleButton,
					                                      locationButton,aboutButton,nil];
	}
	else
	{
		actionMenu = [[UIActionSheet alloc] initWithTitle:nil
												 delegate:self
										cancelButtonTitle:cancelButton
								   destructiveButtonTitle:nil
										otherButtonTitles:scheduleButton,locationButton,aboutButton,nil];
	}
	
	[actionMenu showInView:self.view];
}

- (IBAction)showLocationSettings
{
	LocationSettingsViewController * viewController = 
		[[LocationSettingsViewController alloc] initWithNibName:@"LocationSettingsViewController" 
														 bundle:nil];
	viewController.locationAccuracyDelegate = [RealityVisionClient instance];
	
	UINavigationController * navigationController = 
		[[UINavigationController alloc] initWithRootViewController:viewController];
	[self presentViewController:navigationController animated:YES completion:NULL];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        NSInteger theButtonIndex = buttonIndex - actionSheet.firstOtherButtonIndex + (isSignOnOffAvailable ? 0 : 1);
		
		switch (theButtonIndex) 
		{
			case 0:
				[self signOnOrOff];
				break;
				
			case 1:
				[self showSchedule];
				break;
				
			case 2:
				[self showLocationSettings];
				break;
				
			case 3:
				[self showAboutDialog];
				break;
				
			default:
				DDLogWarn(@"MainMenuViewController: unknown action selection");
				break;
		}
    }
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if ([keyPath isEqual:@"inboxCommandCount"]) 
	{
        // update the command count shown in the menu
        [self.tableView reloadData];
    }
	else if ([keyPath isEqualToString:@"channels"])
	{
		BOOL hide = [[PttChannelManager instance].channels count] == 0;
		[pttBar hide:hide andResizeView:self.tableView interfaceOrientation:self.interfaceOrientation animated:YES];
	}
}


#pragma mark - Other

- (void)showCredentialsViewController:(CredentialsViewController *)viewController
{
	[self presentViewController:viewController animated:YES completion:NULL];
}

- (void)dismissCredentialsViewController
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)resetPttTalkButton
{
	[pttBar resetTalkButton];
}

- (void)showNetworkDisconnected:(BOOL)networkDisconnected
{
	[super showNetworkDisconnected:networkDisconnected];
	menu.mainMenuEnabled = (! networkDisconnected) && [RealityVisionClient instance].isSignedOn;
	[self.tableView reloadData];
}

- (void)updateSignOnStatus:(BOOL)signedOn
{
    [super updateSignOnStatus:signedOn];
    menu.mainMenuEnabled = signedOn;
	[self.tableView reloadData];
	
	BOOL hide = (! signedOn) || ([[PttChannelManager instance].channels count] == 0);
	[pttBar hide:hide andResizeView:self.tableView interfaceOrientation:self.interfaceOrientation animated:YES];
}

@end
