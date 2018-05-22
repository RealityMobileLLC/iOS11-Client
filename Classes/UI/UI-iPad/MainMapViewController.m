//
//  MainMapViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MainMapViewController.h"
#import "MapConfiguration.h"
#import "DeviceCapabilities.h"
#import "PttChannelManager.h"
#import "PushToTalkController.h"
#import "CameraInfoWrapper.h"
#import "CameraCatalogDataSource.h"
#import "CameraFavoritesDataSource.h"
#import "CameraFilesDataSource.h"
#import "CameraScreencastsDataSource.h"
#import "CameraTransmittersDataSource.h"
#import "CameraMapViewDelegate.h"
#import "RealityVisionMapAnnotationView.h"
#import "UserMapAnnotationView.h"
#import "CredentialsViewController.h"
#import "MapFilterViewController.h"
#import "MapFindViewController.h"
#import "MotionJpegMapViewController.h"
#import "OptionsMenuPopoverController.h"
#import "RecipientSelectionViewController.h"
#import "CommandHistoryMenuViewController.h"
#import "ViewedFeedsViewController.h"
#import "WatchMenuViewController.h"
#import "SelectableBarButtonItem.h"
#import "PushToTalkControl.h"
#import "ClientConfiguration.h"
#import "ConfigurationManager.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation MainMapViewController
{
    UserDataSource               * users;
    CameraCatalogDataSource      * catalogCameras;
    CameraFavoritesDataSource    * favoriteCameras;
    
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
    CameraTransmittersDataSource * rovingCameras;
#endif
	
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
    CameraFilesDataSource        * fileCameras;
    CameraScreencastsDataSource  * screencastCameras;
#endif
	
	BOOL                           mapIsVisible;
	NSMutableArray               * videoPlayers;
	int                            maxVideoPlayers;
	
	CameraMapViewDelegate        * cameraMapDelegate;
	UIPopoverController          * activePopover;
	NSTimer                      * cameraRefreshTimer;
	NSTimer                      * userRefreshTimer;
	UIView                       * videoViewToShare;
	MKAnnotationView             * activeAnnotationView;
	UIBarButtonItem              * alertButton;
	UIBarButtonItem              * filterButton;
	UIBarButtonItem              * findButton;
	UIBarButtonItem              * pttChannelButton;
	PushToTalkControl            * pttControl;
	BOOL                           showPttControl;
}

@synthesize mapView;
@synthesize auxiliaryMapDelegate;


#pragma mark - Initialization and cleanup

- (void)createDataSources
{
	// only create data sources once and do not release them on unload
	if (users == nil)
	{
		users = [[UserDataSource alloc] init];
		users.delegate = self;
		
		catalogCameras = [[CameraCatalogDataSource alloc] initWithCameraDelegate:self];
		favoriteCameras = [[CameraFavoritesDataSource alloc] initWithCameraDelegate:self];
		
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
		// don't provide a delegate for transmitters because they will be added to the map as users
		rovingCameras = [[CameraTransmittersDataSource alloc] initWithCameraDelegate:nil];
#endif
		
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
		fileCameras = [[CameraFilesDataSource alloc] initWithCameraDelegate:self];
		screencastCameras = [[CameraScreencastsDataSource alloc] initWithCameraDelegate:self];
#endif
	}
}

- (NSArray *)createToolbarItems
{
	NSMutableArray  * items  = [NSMutableArray arrayWithCapacity:10];
    UIBarButtonItem * flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																					target:nil
																					action:NULL];
	
    [items addObject:self.locationStatusButton];
	
	if (self.trackLocationButton == nil)
	{
		self.trackLocationButton = [[SelectableBarButtonItem alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
																		   target:self
																		   action:@selector(trackLocationButtonPressed)
																		 offImage:[UIImage imageNamed:@"track_off"]
																		  onImage:[UIImage imageNamed:@"track_on"]];
		self.trackLocationButton.on = self.isTrackingLocation;
		self.trackLocationButton.enabled = NO;
	}
    [items addObject:self.trackLocationButton];
    
	if (self.centerOnButton == nil)
	{
		self.centerOnButton = [[SelectableBarButtonItem alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
																	  target:self
																	  action:@selector(centerOnButtonPressed)
																	offImage:[UIImage imageNamed:@"center_off"]
																	 onImage:[UIImage imageNamed:@"center_on"]];
		self.centerOnButton.on = self.isCenteredOnCameras;
		self.centerOnButton.enabled = NO;
	}
    [items addObject:self.centerOnButton];
    
	if (self.showLabelsButton == nil)
	{
		self.showLabelsButton = [[SelectableBarButtonItem alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
																		target:self
																		action:@selector(showLabelsButtonPressed)
																	  offImage:[UIImage imageNamed:@"labels_off"]
																	   onImage:[UIImage imageNamed:@"labels_on"]];
		self.showLabelsButton.on = NO;
		self.showLabelsButton.enabled = NO;
	}
    [items addObject:self.showLabelsButton];
	[items addObject:flexibleSpace];
	
	if (self.statusButton == nil)
	{
		self.statusButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Sign on",@"Sign on button")
															 style:UIBarButtonItemStyleBordered
															target:self
															action:@selector(statusButtonPressed)];
	}
	[items addObject:self.statusButton];
	[items addObject:flexibleSpace];
    
	if ([[PttChannelManager instance].channels count] > 0)
	{
		if (pttChannelButton == nil)
		{
			UIButton * pttButton = [UIButton buttonWithType:UIButtonTypeCustom];
			pttButton.frame = CGRectMake(0, 0, 32, 32);
			[pttButton setImage:[UIImage imageNamed:@"ic_call_settings_32px"] forState:UIControlStateNormal];
			[pttButton addTarget:self action:@selector(showChannelSelection) forControlEvents:UIControlEventTouchUpInside];
			pttChannelButton = [[UIBarButtonItem alloc] initWithCustomView:pttButton];
		}
		[items addObject:pttChannelButton];
		
		UIBarButtonItem * fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
																					 target:nil
																					 action:NULL];
		fixedSpace.width = 8;
		[items addObject:fixedSpace];
	}
    
	if (self.settingsButton == nil)
	{
		UIButton * settings = [UIButton buttonWithType:UIButtonTypeCustom];
		settings.frame = CGRectMake(0, 0, 32, 32);
		[settings setImage:[UIImage imageNamed:@"gear"] forState:UIControlStateNormal];
		[settings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
		self.settingsButton = [[UIBarButtonItem alloc] initWithCustomView:settings];
	}
	[items addObject:self.settingsButton];
	
	return items;
}

- (NSArray *)leftNavigationBarButtonItems
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
	
	if (filterButton == nil)
	{
		filterButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Filters",@"Camera filter button text")
														style:UIBarButtonItemStyleBordered
													   target:self
													   action:@selector(showFilter)];
		filterButton.enabled = [RealityVisionClient instance].isSignedOn;
	}
	[items addObject:filterButton];
	
	UIBarButtonItem * fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
																				 target:nil
																				 action:NULL];
	fixedSpace.width = 16;
	[items addObject:fixedSpace];
	
	if (findButton == nil)
	{
		findButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Find",@"Find on map button text")
													  style:UIBarButtonItemStyleBordered
													 target:self
													 action:@selector(showFind)];
		findButton.enabled = [RealityVisionClient instance].isSignedOn;
	}
	[items addObject:findButton];
	
    return items;
}

- (NSArray *)rightNavigationBarButtonItems
{
    RealityVisionClient * rvClient = [RealityVisionClient instance];
    NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
    
	if (alertButton == nil)
	{
		alertButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"alert_button"]
													   style:UIBarButtonItemStyleBordered
													  target:self
													  action:@selector(alertPressed)];
		alertButton.tintColor = [self alertTintColor];
		alertButton.enabled = rvClient.isSignedOn;
	}
    [items addObject:alertButton];
    
    UIBarButtonItem * historyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"history_button"]
																	   style:UIBarButtonItemStyleBordered
																	  target:self
																	  action:@selector(historyPressed)];
    historyButton.enabled = rvClient.isSignedOn;
    [items addObject:historyButton];
    
    UIBarButtonItem * watchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"watch_button"]
																	 style:UIBarButtonItemStyleBordered
																	target:self
																	action:@selector(watchPressed)];
    watchButton.enabled = rvClient.isSignedOn;
    [items addObject:watchButton];
    
    if ([DeviceCapabilities supportsVideo])
    {
        UIBarButtonItem * transmitButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"transmit_button"]
																			style:UIBarButtonItemStyleBordered
																		   target:self
																		   action:@selector(transmitPressed)];
        transmitButton.enabled = rvClient.isSignedOn;
        [items addObject:transmitButton];
    }
    
    return items;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"MainMapViewController viewDidLoad");
    [super viewDidLoad];
	
	// restore configuration from file, if it exists
	NSString * filename = [self getPrefsFilename];
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
	
	MapConfiguration * config = fileExists ? [NSKeyedUnarchiver unarchiveObjectWithFile:filename] 
	                                       : [[MapConfiguration alloc] init];
	
	self.isCenteredOnCameras = config.isCenteredOnCameras;
	self.isTrackingLocation = config.isTrackingLocation;
    self.showLabels = config.showLabels;
	self.navigationItem.leftBarButtonItems = [self leftNavigationBarButtonItems];
    self.navigationItem.rightBarButtonItems = [self rightNavigationBarButtonItems];
    
	maxVideoPlayers = 0;
    cameraMapDelegate = [[CameraMapViewDelegate alloc] init];
	cameraMapDelegate.centerOnCameras = self.isCenteredOnCameras;
	cameraMapDelegate.centerOnUserLocation = self.isTrackingLocation;
	cameraMapDelegate.mapViewRegionDidChangeDelegate = self;
    mapView.delegate = cameraMapDelegate;
	mapView.mapType = [RealityVisionClient instance].mapType;
    
	[self createDataSources];
	
	// set hidden status for each data source
    users.hidden = ! config.showUsers;
	catalogCameras.hidden = ! config.showCameras;
	favoriteCameras.hidden = ! config.showFavorites;
    
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
	rovingCameras.hidden = ! config.showTransmitters;
#endif
	
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
	fileCameras.hidden = ! config.showFiles;
	screencastCameras.hidden = ! config.showScreencasts;
#endif
	
	pttControl = [[PushToTalkControl alloc] initWithSuperview:mapView];
	
	// install gesture recognizers for panning / zooming on map
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self 
																				  action:@selector(handlePanGesture:)];
	panGesture.delegate = self;
    [mapView addGestureRecognizer:panGesture];
	
    UIPinchGestureRecognizer * zoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self 
																					   action:@selector(handleZoomGesture:)];
	zoomGesture.delegate = self;
    [mapView addGestureRecognizer:zoomGesture];
	
	// register for change in map type
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"mapType"
										options:NSKeyValueObservingOptionNew
										context:NULL];
    
    // register for change in alert status
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"isAlerting"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	
	// register to get notifications when app moves to background or foreground
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(applicationWillResignActive)
											     name:UIApplicationWillResignActiveNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(applicationDidBecomeActive)
											     name:UIApplicationDidBecomeActiveNotification 
											   object:nil];
	
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
	// register for stop video streaming notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(stopStreamingVideo:)
											     name:RvStopVideoStreamingNotification 
											   object:nil];
#endif
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"MainMapViewController viewDidUnload");
	[self savePreferences];
    [super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[RealityVisionClient instance] removeObserver:self forKeyPath:@"mapType"];
	[[RealityVisionClient instance] removeObserver:self forKeyPath:@"isAlerting"];
	
	[cameraRefreshTimer invalidate];
	cameraRefreshTimer = nil;
	[userRefreshTimer invalidate];
	userRefreshTimer = nil;
	
	[self dismissAllVideoPlayers];
	[activePopover dismissPopoverAnimated:NO];
	activePopover = nil;
	
	videoViewToShare = nil;
	activeAnnotationView = nil;
	alertButton = nil;
	filterButton = nil;
	findButton = nil;
	pttChannelButton = nil;
	pttControl = nil;
	
	cameraMapDelegate = nil;
	mapView.delegate = nil;
	mapView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"MainMapViewController viewWillAppear");
    [super viewWillAppear:animated];
	[pttControl setNeedsLayout];
	mapIsVisible = YES;
	
	// register for changes to available channels
	[[PttChannelManager instance] addObserver:self 
								   forKeyPath:@"channels" 
									  options:NSKeyValueObservingOptionNew 
									  context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"MainMapViewController viewWillDisappear");
    [super viewWillDisappear:animated];
	mapIsVisible = NO;
    [activePopover dismissPopoverAnimated:animated];
    activePopover = nil;
	
	[[PttChannelManager instance] removeObserver:self forKeyPath:@"channels"];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	showPttControl = ! pttControl.hidden;
	pttControl.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (showPttControl)
	{
		[pttControl setNeedsLayout];
		pttControl.hidden = NO;
	}
	
	if ([[activePopover contentViewController] isKindOfClass:[ViewedFeedsViewController class]])
	{
		UserDevice * userDevice = (UserDevice *)activeAnnotationView.annotation;
		CGPoint userDevicePoint = [mapView convertCoordinate:userDevice.coordinate toPointToView:mapView];
		CGRect annotationFrame = CGRectMake(userDevicePoint.x - activeAnnotationView.frame.size.width / 2.0, 
											userDevicePoint.y - activeAnnotationView.frame.size.height + 6.0, 
											activeAnnotationView.frame.size.width, 
											activeAnnotationView.frame.size.height);
		
		[activePopover dismissPopoverAnimated:NO];
		[activePopover presentPopoverFromRect:annotationFrame 
									   inView:mapView 
					 permittedArrowDirections:UIPopoverArrowDirectionAny 
									 animated:YES];
	}
	else if ([[activePopover contentViewController] isKindOfClass:[UINavigationController class]])
	{
		UINavigationController * popoverNavigationController = (UINavigationController *)activePopover.contentViewController;
		if ([popoverNavigationController.topViewController isKindOfClass:[RecipientSelectionViewController class]])
		{
			[activePopover dismissPopoverAnimated:NO];
			[activePopover presentPopoverFromRect:videoViewToShare.frame 
										   inView:mapView
						 permittedArrowDirections:UIPopoverArrowDirectionAny
										 animated:YES];
		}
	}
}

- (void)applicationWillResignActive
{
	DDLogVerbose(@"MainMapViewController applicationWillResignActive");
	[self stopRefreshTimer];
	[self savePreferences];
}

- (void)applicationDidBecomeActive
{
	DDLogVerbose(@"MainMapViewController applicationDidBecomeActive");
	
	if (mapIsVisible && [RealityVisionClient instance].isSignedOn)
	{
        [users refresh];
        [catalogCameras refresh];
        [favoriteCameras refresh];

#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        [rovingCameras refresh];
#endif

#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
		[fileCameras refresh];
		[screencastCameras refresh];
#endif

		[self startRefreshTimer];
	}
}


#pragma mark - RootViewController methods

- (void)setIsCenteredOnCameras:(BOOL)isCenteredOnCameras
{
	[super setIsCenteredOnCameras:isCenteredOnCameras];
	cameraMapDelegate.centerOnCameras = isCenteredOnCameras;
}

- (void)setIsTrackingLocation:(BOOL)isTrackingLocation
{
	[super setIsTrackingLocation:isTrackingLocation];
	cameraMapDelegate.centerOnUserLocation = isTrackingLocation;
}

- (void)showCredentialsViewController:(CredentialsViewController *)viewController
{
	NSAssert(self.navigationController.topViewController==self,@"Attempting to get credentials when main map is hidden.");
	DDLogVerbose(@"MainMapViewController showCredentialsViewController activePopover");
	
	[activePopover dismissPopoverAnimated:YES];
	
    activePopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    activePopover.delegate = self;
    
    [activePopover presentPopoverFromBarButtonItem:self.statusButton 
                               permittedArrowDirections:UIPopoverArrowDirectionAny 
                                               animated:YES];
}

- (void)dismissCredentialsViewController
{
	BOOL credentialsShown = activePopover && [activePopover.contentViewController isKindOfClass:[CredentialsViewController class]];
	
	if (credentialsShown)
	{
		DDLogVerbose(@"MainMapViewController dismissCredentialsViewController activePopover");
		[self dismissActivePopover];
	}
}

- (void)updateLocationAware:(BOOL)locationAware
{
    [super updateLocationAware:locationAware];
	mapView.showsUserLocation = locationAware;
}

- (void)userInterfaceEnabled:(BOOL)enabled
{
	self.trackLocationButton.enabled = enabled;
	self.centerOnButton.enabled = enabled;
	self.showLabelsButton.enabled = enabled;
    
	for (UIBarItem * item in self.navigationItem.leftBarButtonItems)
	{
		item.enabled = enabled;
	}
	
	for (UIBarItem * item in self.navigationItem.rightBarButtonItems)
	{
		item.enabled = enabled;
	}
}

- (void)showNetworkDisconnected:(BOOL)networkDisconnected
{
	[super showNetworkDisconnected:networkDisconnected];
	self.signOnOffEnabled = (! networkDisconnected);
	[self userInterfaceEnabled:[RealityVisionClient instance].isSignedOn && (! networkDisconnected)];
}

- (void)updateSignOnStatus:(BOOL)signedOn
{
	[super updateSignOnStatus:signedOn];
	[self userInterfaceEnabled:signedOn];
	
	if (signedOn)
	{
		if (self.isCenteredOnCameras && self.isTrackingLocation)
			self.isTrackingLocation = NO;
		
		self.centerOnButton.on = self.isCenteredOnCameras;
		self.trackLocationButton.on = self.isTrackingLocation;
	}
	else
	{
		[self savePreferences];
	}
    
	if ([[PttChannelManager instance].channels count] > 0)
	{
		[self setToolbarItems:[self createToolbarItems] animated:YES];
	}
    
	if (mapIsVisible)
	{
		if (signedOn)
		{
			[self dismissCredentialsViewController];
			[self startMapUpdates];
		}
		else 
		{
			mapView.showsUserLocation = NO;
			
			[self stopRefreshTimer];
            [self dismissActivePopover];
			[self dismissAllVideoPlayers];
			
            [cameraMapDelegate removeCameras:users.userDevices fromMap:mapView];
            [users reset];
            
			[cameraMapDelegate removeCameras:catalogCameras.cameras fromMap:mapView];
			[catalogCameras reset];
			
			[cameraMapDelegate removeCameras:favoriteCameras.cameras fromMap:mapView];
			[favoriteCameras reset];
			
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
            // transmitters are displayed as users -- don't remove them from the map since they were never added
			[rovingCameras reset];
#endif
			
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
            [cameraMapDelegate removeCameras:fileCameras.cameras fromMap:mapView];
            [fileCameras reset];
            
            [cameraMapDelegate removeCameras:screencastCameras.cameras fromMap:mapView];
            [screencastCameras reset];
#endif
		}
	}
}

- (void)showVideo:(CameraInfoWrapper *)cameraToView forAnnotationView:(MKAnnotationView *)annotationView
{
	NSAssert(videoPlayers,@"Video players have not been created");
	NSAssert(maxVideoPlayers>0,@"Max video players must be greater than 0");
	
	// the viewing camera is the map object the mini viewer will be tied to
	// for transmitting cameras, this will be the same as the cameraToView
	// but when watching a camera feed that another user is watching, it will
	// be the map object for that user
	id <MapObject> viewingCamera = (id <MapObject>)annotationView.annotation;
	
	// if there is already a video playing for this camera, dismiss it
	id existingViewer = viewingCamera.cameraViewer;
	if ([existingViewer isKindOfClass:[MotionJpegMiniPlayerView class]])
	{
		[self dismissVideoPlayer:existingViewer];
	}
	
	MotionJpegMiniPlayerView * player = [[MotionJpegMiniPlayerView alloc] initWithCamera:cameraToView
																			   forViewer:viewingCamera
																	   mapAnnotationView:annotationView
																				   onMap:mapView];
	
	player.delegate = self;
	cameraToView.cameraViewer = player;
	[mapView addSubview:player];
	
	if ([videoPlayers count] == maxVideoPlayers)
	{
		[self dismissVideoPlayer:[videoPlayers objectAtIndex:0]];
	}
	
	[videoPlayers addObject:player];
}

- (void)showVideoForAnnotationView:(MKAnnotationView *)aView
{
	id <MapObject> camera = (id <MapObject>)aView.annotation;
	[self showVideo:camera.camera forAnnotationView:aView];
}

- (void)showViewedVideo:(ViewerInfo *)viewedFeed forAnnotationView:(MKAnnotationView *)aView
{
	[self dismissActivePopover];
	CameraInfoWrapper * cameraToWatch = [[CameraInfoWrapper alloc] initWithViewer:viewedFeed];
	[self showVideo:cameraToWatch forAnnotationView:aView];
}

- (void)dismissViewedFeedsView:(ViewedFeedsViewController *)view
{
	if (activePopover.contentViewController == view)
		[self dismissActivePopover];
}

- (void)showViewedFeedsForAnnotationView:(MKAnnotationView *)aView
{
	NSAssert([aView isKindOfClass:[UserMapAnnotationView class]],@"annotation view must be a UserMapAnnotationView");
	
	[self dismissActivePopover];
	
	UserDevice * userDevice = (UserDevice *)aView.annotation;
	ViewedFeedsViewController * viewController = [[ViewedFeedsViewController alloc] initWithNibName:@"ViewedFeedsViewController" 
																							 bundle:nil];
	viewController.userMapAnnotationView = (UserMapAnnotationView *)aView;
	viewController.delegate = self;
	
    activePopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    activePopover.delegate = self;
	activeAnnotationView = aView;
	viewController.popoverController = activePopover;
    
	CGPoint userDevicePoint = [mapView convertCoordinate:userDevice.coordinate toPointToView:mapView];
	CGRect annotationFrame = CGRectMake(userDevicePoint.x - aView.frame.size.width / 2.0, 
										userDevicePoint.y - aView.frame.size.height + 6.0, 
										aView.frame.size.width, 
										aView.frame.size.height);
	
    [activePopover presentPopoverFromRect:annotationFrame 
                                   inView:mapView 
                 permittedArrowDirections:UIPopoverArrowDirectionAny 
                                 animated:YES];
}

- (void)shareVideo:(CameraInfoWrapper *)camera fromView:(UIView *)theVideoView
{
    [self dismissActivePopover];
    
    RecipientSelectionViewController * viewController = 
        [[RecipientSelectionViewController alloc] initWithNibName:@"RecipientSelectionViewController" 
                                                           bundle:nil];
    viewController.camera = camera;
    viewController.delegate = self;
	
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    activePopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    activePopover.delegate = self;
    
	videoViewToShare = theVideoView;
    [activePopover presentPopoverFromRect:videoViewToShare.frame 
                                   inView:mapView 
                 permittedArrowDirections:UIPopoverArrowDirectionAny 
                                 animated:YES];
}

- (void)didCompleteVideoSharing
{
    [self dismissActivePopover];
}

- (void)trackLocationButtonPressed
{
	self.isTrackingLocation = ! self.isTrackingLocation;
	
	if (self.isTrackingLocation)
	{
		self.isCenteredOnCameras = NO;
		[cameraMapDelegate zoomToLocation:[RealityVisionClient instance].actualLocation onMap:mapView];
	}
}

- (void)centerOnButtonPressed
{
	self.isCenteredOnCameras = ! self.isCenteredOnCameras;
	
	if (self.isCenteredOnCameras)
	{
		self.isTrackingLocation = NO;
		[cameraMapDelegate zoomToCamerasOnMap:mapView];
	}
}

- (void)showLabelsButtonPressed
{
    self.showLabels = ! self.showLabels;
    [self updateMapAnnotations];
}

- (void)resetPttTalkButton
{
	[pttControl resetTalkButton];
}

- (CameraSideMapViewDelegate *)auxiliaryMapDelegate
{
    return auxiliaryMapDelegate;
}

- (void)setAuxiliaryMapDelegate:(CameraSideMapViewDelegate *)newAuxiliaryMapDelegate
{
    auxiliaryMapDelegate = newAuxiliaryMapDelegate;
    
    if (newAuxiliaryMapDelegate != nil)
    {
        if (! users.hidden)
        {
            [auxiliaryMapDelegate addCameras:users.userDevices];
        }
        
        if (! catalogCameras.hidden)
        {
            [auxiliaryMapDelegate addCameras:catalogCameras.camerasInCategory];
        }
        
        if (! favoriteCameras.hidden)
        {
            [auxiliaryMapDelegate addCameras:favoriteCameras.camerasInCategory];
        }
        
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        if (! rovingCameras.hidden)
        {
            [auxiliaryMapDelegate addCameras:rovingCameras.camerasInCategory];
        }
#endif
        
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
        if (! fileCameras.hidden)
        {
            [auxiliaryMapDelegate addCameras:fileCameras.camerasInCategory];
        }
        
        if (! screencastCameras.hidden)
        {
            [auxiliaryMapDelegate addCameras:screencastCameras.camerasInCategory];
        }
#endif
    }
}


#pragma mark - Map view delegate and gesture recognizer delegate callbacks

- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated:(BOOL)animated
{
	for (MotionJpegMiniPlayerView * player in videoPlayers) 
	{
		[player updateLocation];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{   
    return YES;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender 
{
	self.isCenteredOnCameras = NO;
	self.isTrackingLocation = NO;
}

- (void)handleZoomGesture:(UIPinchGestureRecognizer *)sender 
{
	self.isCenteredOnCameras = NO;
	self.isTrackingLocation = NO;
}


#pragma mark - Public methods

- (void)didVerifySignOn
{
    [self startMapUpdates];
}

- (void)filterCamerasOfType:(BrowseCameraCategory)category show:(BOOL)show
{
	CameraDataSource * dataSource = [self cameraDataSourceForCategory:category];
	dataSource.hidden = ! show;
    
    if (show)
    {
        DDLogInfo(@"MainMapViewController: Show cameras of category %d",category);
        
        // handle user feeds by showing the transmitting users; for all others use the cameras from the data source
        NSArray * camerasToShow = (category == BC_Transmitters) ? users.userDevicesTransmitting : dataSource.camerasInCategory;
    	[cameraMapDelegate addCameras:camerasToShow toMap:mapView];
    }
    else
    {
        DDLogInfo(@"MainMapViewController: Hide cameras of category %d",category);
        
        // handle user feeds by hiding the transmitting users; for all others use the cameras from the data source
        NSArray * camerasToHide = (category == BC_Transmitters) ? users.userDevicesTransmitting : dataSource.camerasInCategory;
		[self dismissVideoPlayersForCameras:camerasToHide];
		[cameraMapDelegate removeCameras:camerasToHide fromMap:mapView];
    }
    
    [mapView setNeedsLayout];
}

- (CameraDataSource *)cameraDataSourceForCategory:(BrowseCameraCategory)category
{
	switch (category) 
	{
		case BC_Cameras:
			return catalogCameras;
            
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
		case BC_Files:
            return fileCameras;
            
		case BC_Screencasts:
			return screencastCameras;
#endif
			
		case BC_Favorites:
			return favoriteCameras;
			
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
		case BC_Transmitters:
			return rovingCameras;
#endif
			
		default:
			DDLogError(@"Unknown camera category %d", category);
	}
	
	return nil;
}

- (BOOL)showUsers
{
    return ! users.hidden;
}

- (void)setShowUsers:(BOOL)showUsers
{
	users.hidden = ! showUsers;
    
    if (showUsers)
    {
        DDLogInfo(@"MainMapViewController: Show users");
        
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        // if user feeds are already shown, only add non-transmitting user devices; otherwise add them all
        BOOL showUserFeeds = ! [self cameraDataSourceForCategory:BC_Transmitters].hidden;
        NSArray * usersToShow = showUserFeeds ? users.userDevicesNotTransmitting : users.userDevices;
#else
        NSArray * usersToShow = users.userDevices;
#endif
    	[cameraMapDelegate addCameras:usersToShow toMap:mapView];
    }
    else
    {
        DDLogInfo(@"MainMapViewController: Hide users");
        
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        // if user feeds should be shown, only hide non-transmitting user devices; otherwise hide them all
        BOOL showUserFeeds = ! [self cameraDataSourceForCategory:BC_Transmitters].hidden;
        NSArray * usersToHide = showUserFeeds ? users.userDevicesNotTransmitting : users.userDevices;
#else
        NSArray * usersToHide = users.userDevices;
#endif
		[self dismissVideoPlayersForCameras:usersToHide];
		[cameraMapDelegate removeCameras:usersToHide fromMap:mapView];
    }
    
    [mapView setNeedsLayout];
}

- (void)refreshCameras
{
	DDLogInfo(@"MainMapViewController refreshCameras");
	
    if ([RealityVisionClient instance].isSignedOn)
    {
        [catalogCameras refresh];
        [favoriteCameras refresh];

#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        [rovingCameras refresh];
#endif

#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
		[fileCameras refresh];
		[screencastCameras refresh];
#endif
    }
}

- (void)refreshUsers
{
	DDLogInfo(@"MainMapViewController refreshUsers");
	
    if ([RealityVisionClient instance].isSignedOn)
    {
        [users refresh];
    }
}

- (NSArray *)userMapObjects
{
	// @todo What about users with multiple devices online?  There will be only one table row item.  Which user device do we center on?
	return [self filteredArrayOfMapObjects:users.userDevices];
}

- (NSArray *)cameraMapObjects
{
	return [self filteredArrayOfMapObjects:catalogCameras.cameras];
}

- (NSArray *)screencastMapObjects
{	
	return [self filteredArrayOfMapObjects:screencastCameras.cameras];
}

- (NSArray *)videoFileMapObjects
{	
	return [self filteredArrayOfMapObjects:fileCameras.cameras];
}


#pragma mark - UserDataSource methods

- (void)dataSource:(UserDataSource *)dataSource addedUsers:(NSArray *)userDevices
{
    DDLogVerbose(@"MainMapViewController addedUsers");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
    	[cameraMapDelegate addCameras:userDevices toMap:mapView];
        [auxiliaryMapDelegate addCameras:userDevices];
    }
}

- (void)dataSource:(UserDataSource *)dataSource removedUsers:(NSArray *)userDevices
{
    DDLogVerbose(@"MainMapViewController removedUsers");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
		[self dismissVideoPlayersForCameras:userDevices];
    	[cameraMapDelegate removeCameras:userDevices fromMap:mapView];
        [auxiliaryMapDelegate removeCameras:userDevices];
    }
}

- (void)dataSource:(UserDataSource *)dataSource updatedUsers:(NSArray *)userDevices
{
    DDLogVerbose(@"MainMapViewController updatedUsers");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
		[cameraMapDelegate updateCameras:userDevices onMap:mapView];
        [auxiliaryMapDelegate updateCameras:userDevices];
    }
}

- (void)userListDidGetError:(NSError *)error
{
    // @todo currently fail silently ... may want a way to indicate issue to user
	DDLogWarn(@"MainMapViewController userListDidGetError: %@", error);
}


#pragma mark - CameraCatalogDataSource methods

- (void)dataSource:(CameraDataSource *)dataSource addedCameras:(NSArray *)cameras
{
    DDLogVerbose(@"MainMapViewController addedCameras");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
    	[cameraMapDelegate addCameras:cameras toMap:mapView];
        [auxiliaryMapDelegate addCameras:cameras];
    }
}

- (void)dataSource:(CameraDataSource *)dataSource removedCameras:(NSArray *)cameras
{
    DDLogVerbose(@"MainMapViewController removedCameras");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
		[self dismissVideoPlayersForCameras:cameras];
    	[cameraMapDelegate removeCameras:cameras fromMap:mapView];
        [auxiliaryMapDelegate removeCameras:cameras];
    }
}

- (void)dataSource:(CameraDataSource *)dataSource updatedCameras:(NSArray *)cameras
{
    DDLogVerbose(@"MainMapViewController updatedCameras");
    
    if (([RealityVisionClient instance].isSignedOn) && (! dataSource.hidden))
    {
		[cameraMapDelegate updateCameras:cameras onMap:mapView];
        [auxiliaryMapDelegate updateCameras:cameras];
    }
}

- (void)cameraListDidGetError:(NSError *)error
{
    // @todo currently fail silently ... may want a way to indicate issue to user
	DDLogError(@"MainMapViewController cameraListDidGetError: %@", error);
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
    if ([keyPath isEqual:@"mapType"]) 
	{
		NSValue * mapTypeValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (mapTypeValue != nil)
		{
			MKMapType mapType;
			[mapTypeValue getValue:&mapType];
			mapView.mapType = mapType;
            [self updateMapAnnotations];
		}
    }
    else if ([keyPath isEqual:@"isAlerting"]) 
	{
        alertButton.tintColor = [self alertTintColor];
    }
	else if ([keyPath isEqualToString:@"channels"])
	{
		// refresh toolbar to show or hide channel selection button
		[self setToolbarItems:[self createToolbarItems] animated:YES];
	}
}


#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	if (popoverController == activePopover)
	{
        if ([popoverController.contentViewController isKindOfClass:[CredentialsViewController class]])
        {
            // if the user cancelled entering credentials, hide the connecting indicator
            [self showConnecting:NO];
        }
        
		activePopover = nil;
	}
}


#pragma mark - Button callbacks

- (void)showSettings
{
	BOOL settingsShown = activePopover && [activePopover.contentViewController isKindOfClass:[OptionsMenuPopoverController class]];
	[self dismissActivePopover];
    
	if (! settingsShown)
	{
		DDLogVerbose(@"MainMapViewController showSettings activePopover");
		
		OptionsMenuPopoverController * viewController =
			[[OptionsMenuPopoverController alloc] initWithNibName:@"OptionsMenuPopoverController" 
															bundle:nil];
		viewController.locationAccuracyDelegate = [RealityVisionClient instance];
		
		activePopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
		activePopover.delegate = self;
		viewController.popoverController = activePopover;
		
		[activePopover presentPopoverFromBarButtonItem:self.settingsButton 
								   permittedArrowDirections:UIPopoverArrowDirectionAny 
												   animated:YES];
	}
}

- (void)showFilter
{
    BOOL filterShown = NO;
    
    if (activePopover && [activePopover.contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navigationController = (UINavigationController *)activePopover.contentViewController;
        filterShown = [[navigationController.viewControllers objectAtIndex:0] isKindOfClass:[MapFilterViewController class]];
    }
    
	[self dismissActivePopover];
    
	if (! filterShown)
	{
		MapFilterViewController * menuViewController = 
			[[MapFilterViewController alloc] initWithNibName:@"MapFilterViewController" 
													   bundle:nil];
		
        UINavigationController * navigationController = 
            [[UINavigationController alloc] initWithRootViewController:menuViewController];
        
		activePopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		activePopover.delegate = self;
        menuViewController.popoverController = activePopover;
		
		[activePopover presentPopoverFromBarButtonItem:filterButton
								   permittedArrowDirections:UIPopoverArrowDirectionAny 
												   animated:YES];
	}
}

- (void)showFind
{
	BOOL findShown = NO;
	
	if (activePopover && [activePopover.contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navigationController = (UINavigationController *)activePopover.contentViewController;
        findShown = [[navigationController.viewControllers objectAtIndex:0] isKindOfClass:[MapFindViewController class]];
    }
    
	[self dismissActivePopover];
	
	if (! findShown)
	{
		MapFindViewController * menuViewController = [[MapFindViewController alloc] initWithNibName:@"MapFindViewController"
																							 bundle:nil];
		menuViewController.mapViewController = (MainMapViewController*)((RealityVisionAppDelegate*)[UIApplication sharedApplication].delegate).rootViewController;
		
		UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
		
		activePopover = [[UIPopoverController alloc] initWithContentViewController:navController];
		activePopover.delegate = self;
		menuViewController.popoverController = activePopover;
		
		[activePopover presentPopoverFromBarButtonItem:findButton
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
	}
}

- (void)showChannelSelection
{
    BOOL channelSelectShown = NO;
    
    if (activePopover && [activePopover.contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController * navigationController = (UINavigationController *)activePopover.contentViewController;
		UIViewController * root = [navigationController.viewControllers objectAtIndex:0];
        channelSelectShown = [root isKindOfClass:[PttChannelSelectViewController class]];
    }
    
	[self dismissActivePopover];
    
	if (! channelSelectShown)
	{
		PttChannelSelectViewController * viewController = 
			[[PttChannelSelectViewController alloc] initWithAvailableChannels:[PttChannelManager instance].channels 
															  selectedChannel:[PttChannelManager instance].selectedChannel];
		viewController.delegate = self;
		
        UINavigationController * navigationController = 
			[[UINavigationController alloc] initWithRootViewController:viewController];
        
		activePopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
		activePopover.delegate = self;
		
		[activePopover presentPopoverFromBarButtonItem:pttChannelButton 
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
	}
}

- (void)transmitPressed
{
    RealityVisionClient * client = [RealityVisionClient instance];
    if (client.isSignedOn)
    {
        [client startTransmitSession];
    }
}

- (void)watchPressed
{
    if ([RealityVisionClient instance].isSignedOn)
    {
        WatchMenuViewController * viewController = 
            [[WatchMenuViewController alloc] initWithNibName:@"WatchMenuViewController" 
                                                       bundle:nil];
        [[RealityVisionAppDelegate rootViewController].navigationController pushViewController:viewController 
                                                                                      animated:YES];
    }
}

- (void)historyPressed
{
    if ([RealityVisionClient instance].isSignedOn)
    {
        CommandHistoryMenuViewController * viewController = 
            [[CommandHistoryMenuViewController alloc] initWithNibName:@"CommandHistoryMenuViewController" 
                                                                bundle:nil];
        [[RealityVisionAppDelegate rootViewController].navigationController pushViewController:viewController 
                                                                                      animated:YES];
    }
}

- (void)alertPressed
{
    RealityVisionClient * client = [RealityVisionClient instance];
    if (client.isSignedOn)
    {
        [client toggleAlertMode];
    }
}


#pragma mark - PTT methods

- (void)pttChannelSelected:(NSString *)channel
{
	[self dismissActivePopover];
	[[PushToTalkController instance] pttChannelSelected:channel];
}

- (void)pttChannelSelectionCancelled
{
	[self dismissActivePopover];
}


#pragma mark - Private methods

- (UIColor *)alertTintColor
{
    return [RealityVisionClient instance].isAlerting ? [UIColor redColor] : nil;
}

- (void)dismissActivePopover
{
	[activePopover dismissPopoverAnimated:YES];
	activePopover = nil;
}

#if 0
- (void)resetCameraFilters 
{
	[self filterCamerasOfType:BC_Cameras show:YES];
	[self filterCamerasOfType:BC_Favorites show:YES];
	[self filterCamerasOfType:BC_Transmitters show:YES];
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
	[self filterCamerasOfType:BC_Files show:YES];
	[self filterCamerasOfType:BC_Screencasts show:YES];
#endif
}
#endif

- (void)startMapUpdates
{
	mapView.showsUserLocation = [RealityVisionClient instance].isLocationAware;
	[self createVideoPlayers];
    [users getUsers];
	[catalogCameras getCameras];
	[favoriteCameras getCameras];

#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
	[rovingCameras getCameras];
#endif

#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
	[fileCameras getCameras];
	[screencastCameras getCameras];
#endif

	[self startRefreshTimer];
}

- (void)updateMapAnnotations
{
    for (id <MKAnnotation> annotation in mapView.annotations) 
    {
        MKAnnotationView * annotationView = [mapView viewForAnnotation:annotation];
        
        if ([annotationView isKindOfClass:[RealityVisionMapAnnotationView class]])
        {
            RealityVisionMapAnnotationView * mapAnnotationView = (RealityVisionMapAnnotationView *)annotationView;
            [mapAnnotationView update];
        }
    }
}

- (void)startRefreshTimer
{
	// timer must be created and removed on the same thread so we'll do it to the main thread
	dispatch_async(dispatch_get_main_queue(), 
	               ^{
					   DDLogVerbose(@"MainMapViewController startRefreshTimer");
					   
                       int cameraRefreshPeriod = [ConfigurationManager instance].clientConfiguration.clientCameraRefreshPeriod;
					   [cameraRefreshTimer invalidate];
					   cameraRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:cameraRefreshPeriod
																			target:self 
																		  selector:@selector(refreshCameras) 
																		  userInfo:nil 
																		   repeats:YES];
                       
					   int userRefreshPeriod = [ConfigurationManager instance].clientConfiguration.tabletMapUserRefreshPeriod;
					   [userRefreshTimer invalidate];
					   userRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:userRefreshPeriod
                                                                                  target:self 
                                                                                selector:@selector(refreshUsers) 
                                                                                userInfo:nil 
                                                                                 repeats:YES];
				   });
}

- (void)stopRefreshTimer
{
	// timer must be created and removed on the same thread so we'll do it to the main thread
	dispatch_async(dispatch_get_main_queue(), 
	               ^{
					   DDLogVerbose(@"MainMapViewController stopRefreshTimer");
					   [cameraRefreshTimer invalidate];
					   cameraRefreshTimer = nil;
					   [userRefreshTimer invalidate];
					   userRefreshTimer = nil;
				   });
}

- (void)createVideoPlayers
{
	if (videoPlayers == nil)
	{
		maxVideoPlayers = [ConfigurationManager instance].clientConfiguration.maximumSimultaneousFeeds;
		
		if (maxVideoPlayers < 1)
		{
			DDLogWarn(@"Maximum simultaneous video feeds = %d; setting to 1", maxVideoPlayers);
			maxVideoPlayers = 1;
		}
		
		videoPlayers = [NSMutableArray arrayWithCapacity:maxVideoPlayers];
	}
}

- (void)dismissVideoPlayer:(MotionJpegMiniPlayerView *)player
{
	player.camera.cameraViewer = nil;
	[player removeFromSuperview];
	[videoPlayers removeObject:player];
}

- (void)dismissVideoPlayersForCameras:(NSArray *)cameras
{
	for (id <MapObject> camera in cameras)
	{
		id cameraViewer = camera.cameraViewer;
		if (cameraViewer && [cameraViewer isKindOfClass:[MotionJpegMiniPlayerView class]])
		{
			[self dismissVideoPlayer:cameraViewer];
		}
	}
}

- (void)dismissAllVideoPlayers
{
	for (MotionJpegMiniPlayerView * player in videoPlayers) 
	{
        // we can't remove the object from the collection while iterating through it,
        // so just remove its view from the map and defer clearing the collection until we're done
		player.camera.cameraViewer = nil;
		[player removeFromSuperview];
	}
    
    [videoPlayers removeAllObjects];
}

#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
- (void)stopStreamingVideo:(NSNotification *)notification
{
	// if the top view controller is a MotionJpegMapViewController, use that as the alertview delegate
	// so that the view closes after the user selects OK
	UIViewController * topViewController = self.navigationController.topViewController;
	id delegate = ([topViewController isKindOfClass:[MotionJpegMapViewController class]]) ? topViewController : nil;
	[self showMaxVideoStreamingAlertWithDelegate:delegate];
	[self dismissAllVideoPlayers];
}
#endif

- (NSString *)getPrefsFilename
{
	return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"Map.prefs"];	
}

- (void)savePreferences
{
	MapConfiguration * config = [[MapConfiguration alloc] init];
	config.isTrackingLocation = self.isTrackingLocation;
	config.isCenteredOnCameras = self.isCenteredOnCameras;
    config.showLabels = self.showLabels;
	
	if (catalogCameras)
	{
		config.showCameras = ! catalogCameras.hidden;
	}
	
	if (favoriteCameras)
	{
		config.showFavorites = ! favoriteCameras.hidden;
	}
	
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
	if (rovingCameras)
	{
		config.showTransmitters = ! rovingCameras.hidden;
	}
#endif
	
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
	if (fileCameras)
	{
		config.showFiles = ! fileCameras.hidden;
	}
	
	if (screencastCameras)
	{
		config.showScreencasts = ! screencastCameras.hidden;
	}
#endif
    
    if (users)
    {
        config.showUsers = ! users.hidden;
    }
	
	if (! [NSKeyedArchiver archiveRootObject:config toFile:[self getPrefsFilename]])
	{
		DDLogError(@"Could not save map preferences");
	}
	
}

- (NSArray *)filteredArrayOfMapObjects:(NSArray *)arrayToFilter
{
	NSPredicate * hasLocation = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
								 {
									 if (! [evaluatedObject conformsToProtocol:@protocol(MapObject)])
										 return NO;
									 
									 id <MapObject> item = evaluatedObject;
									 return item.hasLocation;
								 }];
    
    NSArray * mapObjects = [arrayToFilter filteredArrayUsingPredicate:hasLocation];
	return mapObjects;
}

@end
