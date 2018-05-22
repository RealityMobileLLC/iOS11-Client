//
//  MotionJpegMapViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MotionJpegMapViewController.h"
#import "CameraInfoWrapper.h"
#import "CameraInfo.h"
#import "Comment.h"
#import "GpsLockStatus.h"
#import "Session.h"
#import "TransmitterInfo.h"
#import "CommentTableViewCellProvider.h"
#import "CommentTableViewCell.h"
#import "CameraSideMapViewDelegate.h"
#import "AccessoryView.h"
#import "ImageScrollView.h"
#import "LocationStatusBarButtonItem.h"
#import "SelectableBarButtonItem.h"
#import "PttChannelManager.h"
#import "PushToTalkController.h"
#import "PushToTalkBar.h"
#import "UIView+Layout.h"
#import "UIImage+RealityVision.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "FavoritesManager.h"
#import "MainMapViewController.h"
#import "RecipientSelectionViewController.h"
#import "RootViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface MotionJpegMapViewController()

@property (nonatomic) BOOL hasLocation;
@property (nonatomic) BOOL hasSession;

@end


@implementation MotionJpegMapViewController
{
	MotionJpegStream          * stream;
    CameraSideMapViewDelegate * mapViewDelegate;
	
	// ui elements not in nib
	UITableView             * commentsView;
	MKMapView               * mapView;
	PushToTalkBar           * pttBar;
	UILabel                 * frameTimeLabel;
	UIButton                * addSessionCommentButton;
	UIButton                * addFrameCommentButton;
	SelectableBarButtonItem * favoriteButton;
	UIBarButtonItem         * shareButton;
	UIView                  * sessionCommentsHeader;
	UIView                  * frameCommentsHeader;
	VideoControlsView       * videoControls;
	PanTiltZoomControlsView * ptzView;
	WatchOptionsView        * watchOptionsView;
	NSTimer                 * hideControlsTimer;
	
    // indicates whether end video feed is an active transmit session 
    // (note that it could be an archive of an active transmit session)
    BOOL cameraIsLiveFeed;
    
    // state data
	BOOL isFirstImage;
	BOOL isPaused;
    BOOL isLiveFeed;
	BOOL isShowingErrorAlert;      // ensure we don't have multiple outstanding alerts
	BOOL isShowingMap;
	BOOL isShowingComments;
	BOOL controlsHidden;
	BOOL streamIsClosing;
    BOOL shareVideoInProgress;
	BOOL endOfVideoHidden;
    
    // session data (only used when watching archive feed)
	NSMutableArray    * sessionComments;
	NSMutableArray    * frameComments;
	NSDate            * sessionStartTime;
	NSDate            * sessionStopTime;
	NSDate            * sessionCurrentFrameTime;
	int                 sessionId;
	int                 frameId;
	BOOL                isFrameComment;
    ClientTransaction * getSessionRequest;
	
	// outstanding ClientTransaction requests
	NSMutableArray    * addCommentRequests;
	
#ifdef RV_WATCH_FRAME_RATE
	int                 intervalFrameCount;
	NSDate            * intervalStartTime;
#endif
}

@synthesize camera;
@synthesize watchView;
@synthesize connectingIndicator;
@synthesize replayButton;
@synthesize endOfVideoLabel;
@synthesize hasLocation;
@synthesize hasSession;


#pragma mark - Initialization and cleanup

- (void)createRightBarButtonItems
{
	NSMutableArray * buttonItemArray = [NSMutableArray arrayWithCapacity:2];
	
	if (self.camera.canBeFavorite)
	{
		favoriteButton = [[SelectableBarButtonItem alloc] initWithFrame:CGRectMake(0, 0, 20, 20)
																 target:self 
																 action:@selector(toggleFavorite:) 
															   offImage:[UIImage imageNamed:@"favorite_off"] 
																onImage:[UIImage imageNamed:@"favorite_on"]];
		[buttonItemArray addObject:favoriteButton];
	}
	
	shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
																target:self 
																action:@selector(shareButtonPressed:)];
	shareButton.enabled = NO;
	[buttonItemArray addObject:shareButton];
	
	self.navigationItem.rightBarButtonItems = buttonItemArray;
}

- (void)createWatchOptionsView
{
	watchOptionsView = [[WatchOptionsView alloc] init];
	watchOptionsView.delegate = self;
	watchOptionsView.frame = CGRectMake(CENTER(self.view.bounds.size.width, watchOptionsView.bounds.size.width), 
										0, 
										watchOptionsView.bounds.size.width, 
										watchOptionsView.bounds.size.height);
	[self.view addSubview:watchOptionsView];
}

- (void)createFrameTimeLabel
{
	frameTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.mainView.bounds.size.width - 40, 21)];
	frameTimeLabel.textAlignment = UITextAlignmentRight;
	frameTimeLabel.font = [UIFont systemFontOfSize:14];
	frameTimeLabel.textColor = [UIColor whiteColor];
	frameTimeLabel.backgroundColor = [UIColor clearColor];
	frameTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.mainView addSubview:frameTimeLabel];
}

- (UIButton *)createAddCommentButtonWithAction:(SEL)action
{
	UIButton * button = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	
	button.frame = CGRectMake(commentsView.bounds.size.width - button.bounds.size.width - 5, 
							  0, 
							  button.bounds.size.width, 
							  button.bounds.size.height);
	
	return button;
}

- (UIView *)createCommentsHeaderWithText:(NSString *)text andCommentButton:(UIButton *)button
{
	double width  = commentsView.bounds.size.width;
	double height = button.bounds.size.height;
	
	UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 200, height)];
	label.text = text;
	label.font = [UIFont systemFontOfSize:18];
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	headerView.backgroundColor = [UIColor grayColor];
	
	[headerView addSubview:button];
	[headerView addSubview:label];
	
	return headerView;
}

/*
 *  Ensure self is no longer a delegate before unloading or dealloc.
 *  
 *  @todo ios4 this will no longer be needed when we use weak references for delegates in ios5
 */
- (void)removeSelfAsDelegate
{
	// unregister for notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// remove delegate for all outstanding add comment requests
	for (ClientTransaction * request in addCommentRequests) 
	{
		request.delegate = nil;
	}
	
	mapView.delegate = nil;
    stream.delegate = nil;
	getSessionRequest.delegate = nil;
}

- (void)dealloc 
{
	DDLogVerbose(@"MotionJpegMapViewController dealloc");
	[self removeSelfAsDelegate];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    NSAssert(self.camera,@"Camera must be set before MotionJpegMapViewController is loaded");
    
	DDLogVerbose(@"MotionJpegMapViewController viewDidLoad");
    [super viewDidLoad];
	self.title = self.camera.name;
	[self createRightBarButtonItems];
	
	// create push to talk controls
	pttBar = [[PushToTalkBar alloc] initWithFrame:CGRectMake(0, 356, 320, 60)];
	pttBar.delegate = [PushToTalkController instance];
	[self.view addSubview:pttBar];
    
    // session and frame comments
    sessionComments = [NSMutableArray arrayWithCapacity:10];
    frameComments = [NSMutableArray arrayWithCapacity:10];
	addCommentRequests = [NSMutableArray arrayWithCapacity:5];
    
    // set up scroll view
    self.mainView = [[ImageScrollView alloc] initWithFrame:self.watchView.bounds];
	[self.watchView addSubview:self.mainView];
	
	// create ptz controls
	ptzView = [[PanTiltZoomControlsView alloc] initWithFrame:self.watchView.bounds];
	ptzView.camera = self.camera;
	ptzView.hideControlsTimerDelegate = self;
	ptzView.hidden = YES;
	[self.watchView addSubview:ptzView];
	
	// create comments header views
	addSessionCommentButton = [self createAddCommentButtonWithAction:@selector(addSessionComment:)];
	sessionCommentsHeader = [self createCommentsHeaderWithText:NSLocalizedString(@"Session Comments",@"Session comments label") 
											  andCommentButton:addSessionCommentButton];
	
	addFrameCommentButton = [self createAddCommentButtonWithAction:@selector(addFrameComment:)];
	addFrameCommentButton.enabled = NO;
	frameCommentsHeader = [self createCommentsHeaderWithText:NSLocalizedString(@"Frame Comments",@"Frame comments label") 
											andCommentButton:addFrameCommentButton];
	
	// create map view
	CGRect accessoryFrame = CGRectMake(0, 0, 320, self.watchView.bounds.size.height);
	mapView = [[MKMapView alloc] initWithFrame:accessoryFrame];
	mapViewDelegate = [[CameraSideMapViewDelegate alloc] initWithCamera:camera forMapView:mapView];
	mapView.delegate = mapViewDelegate;
	mapView.mapType = [RealityVisionClient instance].mapType;
	mapView.hidden = YES;
	
	// create comments view
	commentsView = [[UITableView alloc] initWithFrame:accessoryFrame style:UITableViewStylePlain];
	commentsView.delegate = self;
	commentsView.dataSource = self;
	commentsView.hidden = YES;
	[commentsView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil]
	   forCellReuseIdentifier:[CommentTableViewCell reuseIdentifier]];
    
	// create accessory view with map and comments
	self.accessoryView = [[AccessoryView alloc] initWithFrame:accessoryFrame];
	[self.accessoryView addSubview:mapView];
	[self.accessoryView addSubview:commentsView];
	[self.watchView addSubview:self.accessoryView];
	
	// a transmitter doesn't have a location until one shows up in the video feed
	self.hasLocation = (! self.camera.isTransmitter) && self.camera.hasLocation;
	self.hasSession = NO;
	
	// initialize video stream state data
	isFirstImage = YES;
	isPaused = NO;
    isLiveFeed = cameraIsLiveFeed = self.camera.isLiveFeed;
	sessionId = kRVNoSessionId;
	frameId = kRVNoFrameId;
	
	// on ipad, show map view by default if the feed has a location
	if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && (self.hasLocation))
	{
		[self showMapFullScreen:NO];
		watchOptionsView.selectedOption = WO_ShowMapHalfScreen;
	}
	
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
	DDLogVerbose(@"MotionJpegMapViewController viewDidUnload");
    [super viewDidUnload];
	[self removeSelfAsDelegate];
	
	self.accessoryView = nil;
	self.mainView = nil;
	commentsView = nil;
	watchView = nil;
	pttBar = nil;
	
    mapViewDelegate = nil;
	mapView = nil;
	ptzView = nil;
	watchOptionsView = nil;
	
	connectingIndicator = nil;
	replayButton = nil;
	endOfVideoLabel = nil;
	frameTimeLabel = nil;
	addSessionCommentButton = nil;
	addFrameCommentButton = nil;
	favoriteButton = nil;
    shareButton = nil;
	
	sessionCommentsHeader = nil;
	frameCommentsHeader = nil;
	videoControls = nil;
	
	[hideControlsTimer invalidate];
	hideControlsTimer = nil;
    
	stream = nil;
	sessionComments = nil;
	frameComments = nil;
	sessionStartTime = nil;
	sessionStopTime = nil;
	sessionCurrentFrameTime = nil;
    
    getSessionRequest = nil;
	addCommentRequests = nil;
    
#ifdef RV_WATCH_FRAME_RATE
	intervalStartTime = nil;
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"MotionJpegMapViewController viewWillAppear");
	[super viewWillAppear:animated];
	
	pttBar.hidden = [[PttChannelManager instance].channels count] == 0;
	[pttBar layoutPttBarAndResizeView:watchView forInterfaceOrientation:self.interfaceOrientation];
	
	// register for changes to available channels
	[[PttChannelManager instance] addObserver:self 
								   forKeyPath:@"channels" 
									  options:NSKeyValueObservingOptionNew 
									  context:NULL];
	
	// set the state of the favorite button, if it exists
    if (favoriteButton != nil)
    {
        if ([FavoritesManager favorites] == nil)
        {
            favoriteButton.enabled = NO;
            favoriteButton.on = NO;
        }
        else
        {
            favoriteButton.enabled = YES;
            favoriteButton.on = [FavoritesManager isAFavorite:self.camera];
        }
        
        [FavoritesManager updateAndAddObserver:self];
    }
	
	if (stream == nil)
	{
		isFirstImage = YES;
		[connectingIndicator startAnimating];
        [self playFeedAtUrl:self.camera.sourceUrl andRemainPaused:NO];
		
		if ((stream != nil) && (! stream.isClosed))
		{
			// set watching status on server
			[[RealityVisionClient instance] startWatchSession];
		}
	}
    else if (! stream.isClosed)
    {
        [self resetControlsTimer];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"MotionJpegMapViewController viewDidAppear");
	[super viewDidAppear:animated];
    
	if (self.camera.hasLocation)
	{
		[self setMapRegion:self.camera.coordinate];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"MotionJpegMapViewController viewWillDisappear");
    [self disableControlsTimer];
	[pttBar resetTalkButton];
	[[PttChannelManager instance] removeObserver:self forKeyPath:@"channels"];
	
    if (favoriteButton != nil)
    {
        [FavoritesManager removeObserver:self];
    }
	
	if (self.isMovingFromParentViewController)
	{
		streamIsClosing = YES;
		[stream close];

#ifdef RV_WATCH_FRAME_RATE
		intervalStartTime = nil;
#endif
        
        UIViewController * rootViewController = [RealityVisionAppDelegate rootViewController];
        if ([rootViewController isKindOfClass:[MainMapViewController class]] && ((self.camera.isDirect) || (isLiveFeed)))
        {
            MainMapViewController * mainMapViewController = (MainMapViewController *)rootViewController;
            mainMapViewController.auxiliaryMapDelegate = nil;
        }
		
		// turn off watching status on server
		[[RealityVisionClient instance] stopWatchSession];
	}
	
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	if (! pttBar.hidden)
	{
		[pttBar layoutPttBarAndResizeView:watchView forInterfaceOrientation:interfaceOrientation];
	}
	
	[super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self layoutMainView];
}


#pragma mark - Main view (image) methods

- (ImageScrollView *)scrollView
{
	return (ImageScrollView *)self.mainView;
}

- (void)layoutMainView
{
    [self layoutReplayView];
	[ptzView setNeedsLayout];
	[self.scrollView setNeedsLayout];
}


#pragma mark - Video stream start/stop methods

- (void)playFeedAtUrl:(NSURL *)videoUrl andRemainPaused:(BOOL)remainPaused
{
    DDLogInfo(@"Requesting camera feed at %@", videoUrl);
    stream = [[MotionJpegStream alloc] initWithUrl:videoUrl];
    stream.delegate = self;
	
	// @todo need requirements on how to handle webcams that require credentials; for now, disallow access
	stream.allowCredentials = ! camera.isDirect;
    
	addFrameCommentButton.enabled = NO;
	self.endOfVideoHidden = YES;
    streamIsClosing = NO;
	
    if (! remainPaused)
    {
		if (videoControls != nil)
		{
			videoControls.isPlaying = YES;
		}
		
        isPaused = NO;
    }
    
#ifdef RV_WATCH_FRAME_RATE
    intervalFrameCount = 0;
    intervalStartTime = [NSDate date];
#endif
    
    NSError * error = nil;
    if (! [stream open:&error])
    {
        NSString * errorMsg = [NSString stringWithFormat:@"Error opening motion jpeg stream: %@", error];
        [self streamClosedWithError:[RvError rvErrorWithLocalizedDescription:errorMsg]];
    }
}

- (void)stopFeedAndShowLiveButton:(BOOL)showLiveButton
{
	streamIsClosing = YES;
    [stream close];
    
    if (showLiveButton && cameraIsLiveFeed)
    {
        [videoControls showLiveButton:YES];
        [videoControls enableForwardButton:YES];
    }
}

- (void)playVideoFromTime:(NSDate *)frameTime andRemainPaused:(BOOL)remainPaused
{
	NSURL * newUrl = [self.camera urlForStartTime:frameTime];
	
	if (newUrl != nil)
	{
        [self stopFeedAndShowLiveButton:cameraIsLiveFeed];
        [self playFeedAtUrl:newUrl andRemainPaused:remainPaused];
	}
}

#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
- (void)stopStreamingVideo:(NSNotification *)notification
{
	if ((! isShowingErrorAlert) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone))
	{
		isShowingErrorAlert = YES;
		
		// show streaming video timeout alert (on iPad, alert will be shown by MainMapViewController)
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController showMaxVideoStreamingAlertWithDelegate:self];
	}
	
	streamIsClosing = YES;
	[stream close];
}
#endif


#pragma mark - MotionJpegStreamDelegate methods

- (void)didGetImage:(UIImage *)image 
		   location:(CLLocation *)location 
			   time:(NSDate *)timestamp 
		  sessionId:(int)imageSessionId 
			frameId:(int)imageFrameId
{
	[self.scrollView setImage:image];
	
	if (isFirstImage)
	{
		[self didGetFirstImageWithSessionId:imageSessionId];
	}
	
	if (location != nil)
	{
		self.camera.coordinate = location.coordinate;
		
		if (! self.hasLocation)
		{
			// this is the first location received for this camera, so set up the map view
            [self enableMapViewAtCoordinate:location.coordinate];
			
			// for transmitters on the iPad, show the map view
			if ((self.camera.isTransmitter) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad))
			{
				[self showMapFullScreen:NO];
			}
			
			[self resetControlsTimer];
		}
		else 
		{
			[mapView setCenterCoordinate:self.camera.coordinate animated:!mapView.hidden];
		}
	}
	
	if (timestamp != nil)
	{
		sessionCurrentFrameTime = timestamp;
		[self setFrameTime:sessionCurrentFrameTime];
		
		if (videoControls != nil)
		{
			NSTimeInterval timeSinceStart = [timestamp timeIntervalSinceDate:sessionStartTime];
			videoControls.currentTime = timeSinceStart;
			
			if (isLiveFeed)
			{
				videoControls.totalTime = timeSinceStart;
			}
			else if (cameraIsLiveFeed)
			{
				// watching an archive of a live feed, so current end time is now
				videoControls.totalTime = MAX(-[sessionStartTime timeIntervalSinceNow],timeSinceStart);
			}
		}
	}
	
	if (self.hasSession && (sessionId == imageSessionId) && (imageFrameId != kRVNoFrameId))
	{
		frameId = imageFrameId;
	}

	// stop video after this frame if paused
	if (isPaused)
	{
		[self pause];
	}
	
#ifdef RV_WATCH_FRAME_RATE
	intervalFrameCount++;
	NSDate * timeNow = [NSDate date];
	NSTimeInterval elapsedSeconds = [timeNow timeIntervalSinceDate:intervalStartTime];
	if (elapsedSeconds >= 1.0)
	{
		float frameRate = intervalFrameCount / elapsedSeconds;
		DDLogVerbose(@"Frame rate = %.1f", frameRate);
		intervalFrameCount = 0;
		intervalStartTime = timeNow;
	}
#endif
}

- (void)didGetFirstImageWithSessionId:(int)imageSessionId
{
	isFirstImage = NO;
	[connectingIndicator stopAnimating];
	
	// if the camera has a location and is not a transmitter, go ahead and show it on the map
	// (transmitter location only shows on map when location is embedded in video frame)
	if ((self.camera.hasLocation) && (! self.camera.isTransmitter))
	{
        [self enableMapViewAtCoordinate:self.camera.coordinate];
	}
	
	// if the image has a session id but no session has been loaded, get the session
	if ((! self.hasSession) && (imageSessionId != kRVNoSessionId))
	{
        sessionId = imageSessionId;
        [self reloadSession];
	}
	
	// if the camera supports ptz, show controls
	if (self.camera.isPanTiltZoom)
	{
		ptzView.hidden = NO;
	}
	
	if (frameTimeLabel)
	{
		[self.mainView bringSubviewToFront:frameTimeLabel];
	}
	
    shareButton.enabled = YES;
	[self resetControlsTimer];
	[self addTapGestureAction:@selector(toggleControls:) 
					   toView:self.scrollView 
			   waitForGesture:self.scrollView.doubleTapGesture];
}

- (void)didGetSession:(Session *)session
{
    if (! self.hasSession)
    {
        self.hasSession = YES;
        sessionId  = session.sessionId;
		
		// include comments views in watch options
		[watchOptionsView setNeedsLayout];
        
        if (videoControls == nil)
        {
            [self createVideoControls];
        }
        
        sessionStartTime = session.startTime;
        
        if (sessionCurrentFrameTime == nil)
        {
            sessionCurrentFrameTime = session.startTime;
        }
        
        sessionStopTime = [session.stopTime timeIntervalSince1970] >= 0 ? session.stopTime : sessionCurrentFrameTime;
        
        [videoControls enableForwardButton:self.camera.isArchiveFeed];
        videoControls.totalTime = [sessionStopTime timeIntervalSinceDate:sessionStartTime];
        
        if (! cameraIsLiveFeed)
        {
            // if this is an archive feed but doesn't have a stop time then it's still transmitting so let the user switch to live view
            cameraIsLiveFeed = self.camera.isArchiveFeed && [session.stopTime timeIntervalSince1970] < 0;
            [videoControls showLiveButton:cameraIsLiveFeed];
        }
        
        if (self.camera.isArchiveFeed)
        {
 			[self createFrameTimeLabel];
			[self setFrameTime:sessionCurrentFrameTime];
        }
    }
    
	videoControls.alpha = 1.0;
	videoControls.hidden = NO;
	controlsHidden = NO;
    [self updateComments:session.comments];
}

- (void)streamDidEnd
{
	if ((self.camera.isVideoServerFeed) || (self.camera.isScreencast))
	{
		if (videoControls)
		{
			// when video server feeds end, stop video playback
			videoControls.isPlaying = NO;
            
            if (cameraIsLiveFeed)
            {
                [videoControls showLiveButton:NO];
                [videoControls enableForwardButton:NO];
            }
			
			if ((self.hasSession) && (! isPaused))
			{
				self.endOfVideoHidden = NO;
			}
		}
	}
	else if (! streamIsClosing)
	{
		// retry non-video server feeds unless we are trying to shutdown
        [self playFeedAtUrl:self.camera.sourceUrl andRemainPaused:NO];
	}
}

- (void)streamClosedWithError:(NSError *)error
{
    if (videoControls != nil)
    {
        videoControls.isPlaying = NO;
        
        if (cameraIsLiveFeed)
        {
            [videoControls showLiveButton:NO];
            [videoControls enableForwardButton:NO];
        }
    }
	
	if (isFirstImage)
	{
		[connectingIndicator stopAnimating];
	}
	
	if (! isShowingErrorAlert)
	{
		isShowingErrorAlert = YES;
		[pttBar resetTalkButton];
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to View Camera",
																				   @"Unable to view camera title") 
														 message:[error localizedDescription] 
														delegate:self 
											   cancelButtonTitle:NSLocalizedString(@"OK",@"OK") 
											   otherButtonTitles:nil];
		[alert show];
	}
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the only alerts are due to the stream closing unexpectedly or reaching the max streaming time
	// either way, dismiss this view controller if it's still the top view controller
	if ((self.navigationController.topViewController == self) && (self.presentedViewController == nil))
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}


#pragma mark - Video control methods

- (void)playFromTimeOffset:(NSTimeInterval)offset andRemainPaused:(BOOL)remainPaused
{
    isLiveFeed = NO;
	NSDate * newStartTime = [sessionStartTime dateByAddingTimeInterval:offset];
	[self playVideoFromTime:newStartTime andRemainPaused:remainPaused];
	[self resetControlsTimer];
	
	if (cameraIsLiveFeed)
	{
		[mapViewDelegate removeAllOtherCameras];
	}
}

- (void)playLiveFeedAndRemainPaused:(BOOL)remainPaused
{
    NSAssert(cameraIsLiveFeed,@"Video feed does not support a live feed");
    isLiveFeed = YES;
    [stream close];
    [videoControls showLiveButton:NO];
    [self playFeedAtUrl:[self.camera urlForLiveFeed] andRemainPaused:remainPaused];
	
	if (!remainPaused)
	{
		[mapViewDelegate restoreAllOtherCameras];
	}
}

- (void)pause
{
	isPaused = YES;
    [self stopFeedAndShowLiveButton:cameraIsLiveFeed];
	addFrameCommentButton.enabled = YES;
	[self resetControlsTimer];
	
	if (cameraIsLiveFeed)
	{
		[mapViewDelegate removeAllOtherCameras];
	}
}

- (IBAction)replayVideo
{
    isLiveFeed = self.camera.isLiveFeed;
    [videoControls enableForwardButton:(! isLiveFeed)];
	
	isFirstImage = YES;
	[self.scrollView setImage:nil];
	[connectingIndicator startAnimating];
	[self playFeedAtUrl:self.camera.sourceUrl andRemainPaused:NO];
	
	if (cameraIsLiveFeed)
	{
		[mapViewDelegate removeAllOtherCameras];
	}
}

- (void)toggleControls:(UIGestureRecognizer *)gestureRecognizer
{
	if (! stream.isClosed)
	{
		controlsHidden = ! controlsHidden;
		
		if (controlsHidden)
		{
            [self disableControlsTimer];
		}
		else 
		{
			[self resetControlsTimer];
		}
		
		if (self.camera.isPanTiltZoom)
		{
			ptzView.alpha  = controlsHidden ? 0.0 : 1.0;
			ptzView.hidden = controlsHidden;
		}
		else if (videoControls != nil)
		{
			videoControls.alpha  = controlsHidden ? 0.0 : 1.0;
			videoControls.hidden = controlsHidden;
		}
	}
}


#pragma mark - Hide controls timer

- (void)resetControlsTimer
{
	[hideControlsTimer invalidate];
	hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 
														 target:self 
													   selector:@selector(hideControls:) 
													   userInfo:nil 
														repeats:NO];
}

- (void)disableControlsTimer
{
    [hideControlsTimer invalidate];
    hideControlsTimer = nil;
}

- (void)hideControls:(NSTimer *)timer
{
	if ((! stream.isClosed) && (! controlsHidden))
	{
		controlsHidden = YES;
		
		if (self.camera.isPanTiltZoom)
		{
			[UIView animateWithDuration:0.3 
							 animations:^{ ptzView.alpha = 0.0; } 
							 completion:^(BOOL finished) { ptzView.hidden = YES; }];
		}
		else if (videoControls != nil)
		{
			[UIView animateWithDuration:0.3 
							 animations:^{ videoControls.alpha = 0.0; } 
							 completion:^(BOOL finished) { videoControls.hidden = YES; }];
		}
	}
	
	hideControlsTimer = nil;
}


#pragma mark - Share video methods

- (IBAction)shareButtonPressed:(id)sender
{
    [self disableControlsTimer];
    
    // if the video feed isn't paused share it as is, otherwise prompt user for what to share
    if (! isPaused)
    {
        [self presentShareVideoViewControllerAndShareFromTime:nil];
        return;
    }
    
    // don't use a cancel button on the iPad because this will be shown in a popover
    NSString * cancelButton = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? NSLocalizedString(@"Cancel",@"Cancel") : nil;
    
    NSString * secondButtonTitle = (self.camera.isLiveFeed) ? NSLocalizedString(@"Share live feed",@"Share live feed") 
                                                            : NSLocalizedString(@"Share from beginning",@"Share from beginning");
    
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self 
                                                     cancelButtonTitle:cancelButton 
                                                destructiveButtonTitle:nil 
                                                     otherButtonTitles:NSLocalizedString(@"Share from here",@"Share from here"),
                                                                       secondButtonTitle,
                                                                       nil];
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        NSInteger theButtonIndex = buttonIndex - actionSheet.firstOtherButtonIndex;
        NSDate * shareFromTime = (theButtonIndex == 0) ? sessionCurrentFrameTime : nil;
        [self presentShareVideoViewControllerAndShareFromTime:shareFromTime];
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
    if ((stream != nil) && (! stream.isClosed))
    {
        [self resetControlsTimer];
    }
}

- (void)presentShareVideoViewControllerAndShareFromTime:(NSDate *)fromTime
{    
    RecipientSelectionViewController * viewController = 
        [[RecipientSelectionViewController alloc] initWithNibName:@"RecipientSelectionViewController" 
                                                           bundle:nil];
    viewController.camera = self.camera;
    viewController.shareVideoStartTime = fromTime;
    viewController.delegate = self;
    
    [self.navigationController pushViewController:viewController animated:YES];
    shareVideoInProgress = YES;
}

- (void)dismissShareVideoViewControllerAnimated:(BOOL)animated
{
    NSAssert(shareVideoInProgress,@"Can not dismiss share video view controller when it is not present");
    [self.navigationController popViewControllerAnimated:animated];
    shareVideoInProgress = NO;
}

- (void)didCompleteVideoSharing
{
    [self dismissShareVideoViewControllerAnimated:YES];
}


#pragma mark - Add favorite methods

- (void)toggleFavorite:(id)sender
{
	if (favoriteButton.on)
	{
		[FavoritesManager remove:self.camera];
	}
	else
	{
		[FavoritesManager add:self.camera];
	}
	
	favoriteButton.on = ! favoriteButton.on;
    [self resetControlsTimer];
}


#pragma mark - FavoritesObserver 

- (void)favoritesUpdated:(NSArray *)favorites orError:(NSError *)error
{
	DDLogVerbose(@"MotionJpegMapViewController favoritesUpdated");
	if (favorites != nil)
	{
		favoriteButton.enabled = YES;
		favoriteButton.on = [FavoritesManager isAFavorite:self.camera];
	}
}


#pragma mark - WatchOptionsDelegate

- (void)setHasSession:(BOOL)newHasSession
{
	hasSession = newHasSession;
	
	if (watchOptionsView != nil)
	{
		[watchOptionsView setNeedsLayout];
	}
	else if (hasSession)
	{
		[self createWatchOptionsView];
	}
}

- (void)setHasLocation:(BOOL)newHasLocation
{
	hasLocation = newHasLocation;
	
	if (watchOptionsView != nil)
	{
		[watchOptionsView setNeedsLayout];
	}
	else if (hasLocation)
	{
		[self createWatchOptionsView];
	}
}

- (BOOL)canShowMap
{
	return hasLocation;
}

- (BOOL)canShowComments
{
	return hasSession;
}

- (void)showVideoFullScreen
{
	[self hideAccessoryView];
	isShowingMap = NO;
	isShowingComments = NO;
	[self resetControlsTimer];
}

- (void)showMapFullScreen:(BOOL)fullScreen
{
	[self showAccessoryView:mapView 
		  hideAccessoryView:commentsView 
				 fullScreen:fullScreen 
			  flipDirection:UIViewAnimationOptionTransitionFlipFromLeft];
	
	isShowingMap = YES;
	isShowingComments = NO;
	[self resetControlsTimer];
}

- (void)showCommentsFullScreen:(BOOL)fullScreen
{
	[self showAccessoryView:commentsView 
		  hideAccessoryView:mapView 
				 fullScreen:fullScreen 
			  flipDirection:UIViewAnimationOptionTransitionFlipFromRight];
	
	isShowingMap = NO;
	isShowingComments = YES;
	[self resetControlsTimer];
}


#pragma mark - Add comment methods

- (void)addSessionComment:(id)sender
{
	NSAssert(sessionId!=kRVNoSessionId,@"addSessionComment should only be called for a user or archive feed");
	
	DDLogVerbose(@"MotionJpegMapViewController addSessionComment");
	isFrameComment = NO;
	
	EnterCommentViewController * enterCommentViewController = 
		[[EnterCommentViewController alloc] initWithNibName:@"EnterCommentViewController" 
													  bundle:nil];
	
	enterCommentViewController.title = NSLocalizedString(@"Enter Session Comment",@"Enter session comment title");
	enterCommentViewController.delegate = self;
    
	[self presentViewController:enterCommentViewController animated:YES completion:NULL];
}

- (void)addFrameComment:(id)sender
{
	NSAssert(hasSession,@"addFrameComment should only be called for an archive feed");
	NSAssert(frameId!=kRVNoFrameId,@"addFrameComment should only be called when a frame is displayed");
	
	DDLogVerbose(@"MotionJpegMapViewController addFrameComment");
	isFrameComment = YES;
	
	EnterCommentViewController * enterCommentViewController = 
		[[EnterCommentViewController alloc] initWithNibName:@"EnterCommentViewController" 
													  bundle:nil];
	
	enterCommentViewController.title = NSLocalizedString(@"Enter Frame Comment",@"Enter frame comment title");
	enterCommentViewController.delegate = self;
    
	[self presentViewController:enterCommentViewController animated:YES completion:NULL];
}

- (void)didEnterComment:(NSString *)commentText
{
	DDLogVerbose(@"MotionJpegMapViewController didEnterComment");
	
	if (! NSStringIsNilOrEmpty(commentText))
	{
		// create comment to display in table
		Comment * comment = [[Comment alloc] init];
		comment.commentId = 0;
		comment.comments = commentText;
		comment.entryTime = [NSDate date];
		comment.username = [RealityVisionClient instance].userId;
		comment.isFrameComment = isFrameComment;
		comment.thumbnail = (! isFrameComment) ? nil : self.scrollView.image;
		
		// get web service
		NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
        clientTransaction.delegate = self;
		
		// track all add comment requests
		[addCommentRequests addObject:clientTransaction];

		if (! isFrameComment)
		{
			[clientTransaction addComment:commentText forSession:sessionId];
			[sessionComments insertObject:comment atIndex:0];
		}
		else 
		{
			comment.frameId = frameId;
			comment.frameTime = sessionCurrentFrameTime;
			[clientTransaction addComment:commentText forSession:sessionId andFrame:frameId];
			[frameComments insertObject:comment atIndex:0];
		}
		
		// for archive feeds, also add the comment to the underlying camera so it shows up on the browse view
		if (self.camera.isArchivedSession)
		{
			Session * session = self.camera.sourceObject;
			[session.comments addObject:comment];
		}
		
		[commentsView reloadData];
	}
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Get session comments methods

- (void)reloadSession
{
	NSAssert(sessionId!=kRVNoSessionId,@"reloadSession should only be called for a user or archive feed");
    
    if (getSessionRequest != nil)
        return;
    
    NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
    getSessionRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
    getSessionRequest.delegate = self;
    [getSessionRequest getSession:sessionId];
}

- (void)onGetSessionResult:(Session *)session error:(NSError *)error
{
	DDLogInfo(@"MotionJpegMapViewController onGetSessionResult");
    
    if (getSessionRequest == nil)
    {
        DDLogVerbose(@"GetSession request was cancelled.");
        return;
    }
	
    getSessionRequest = nil;
    
	if ((session == nil) && (error == nil))
	{
		error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the video session."];
	}
	
	if (error != nil)
	{
		DDLogError(@"Error retrieving video session: %@", error);
		return;
	}
        
    [self didGetSession:session];
}

- (void)onAddComment:(NSError *)error fromClientTransaction:(ClientTransaction *)sender
{
	[addCommentRequests removeObject:sender];
    [self reloadSession];
}


#pragma mark - Map view methods

- (void)setMapRegion:(CLLocationCoordinate2D)coordinate
{
	CLLocationDegrees latitudeDelta  = 2.0 / 69.0;
	CLLocationDegrees longitudeDelta = 2.0 / 69.0;
	
	MKCoordinateRegion mapRegion = MKCoordinateRegionMake(coordinate, 
														  MKCoordinateSpanMake(latitudeDelta, longitudeDelta));
	
	[mapView setRegion:mapRegion animated:!mapView.hidden];
}


#pragma mark - Comments view methods (table view delegate and data source)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView 
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return (section == 0) ? sessionCommentsHeader.bounds.size.height : frameCommentsHeader.bounds.size.height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return (section == 0) ? sessionCommentsHeader : frameCommentsHeader; 
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section 
{
    return (section == 0) ? [sessionComments count] : [frameComments count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
	{
		Comment * comment = [sessionComments objectAtIndex:indexPath.row];
		return [CommentTableViewCellProvider heightForRowWithSessionComment:comment
														 constrainedToWidth:tableView.frame.size.width
															 tableViewStyle:tableView.style];
	}
	else
	{
		Comment * comment = [frameComments objectAtIndex:indexPath.row];
		return [CommentTableViewCellProvider heightForRowWithFrameComment:comment
													   constrainedToWidth:tableView.frame.size.width
														   tableViewStyle:tableView.style];
	}
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	UITableViewCell * cell;
	
	if (indexPath.section == 0)
	{
		cell = [CommentTableViewCellProvider tableView:theTableView
								 cellForSessionComment:[sessionComments objectAtIndex:indexPath.row]];
	}
	else 
	{
		cell = [CommentTableViewCellProvider tableView:theTableView
								   cellForFrameComment:[frameComments objectAtIndex:indexPath.row]];
	}
 	
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	Comment * comment = [frameComments objectAtIndex:indexPath.row];
 	CommentDetailViewController * commentView = [[CommentDetailViewController alloc] initWithComment:comment];
	commentView.delegate = self;
	[self.navigationController pushViewController:commentView animated:YES];
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if ([keyPath isEqualToString:@"channels"])
	{
		BOOL hide = [[PttChannelManager instance].channels count] == 0;
		[pttBar hide:hide andResizeView:watchView interfaceOrientation:self.interfaceOrientation animated:YES];
	}
}


#pragma mark - Private methods

- (void)setFrameTime:(NSDate *)frameTime
{
	[frameTimeLabel setText:[NSDateFormatter localizedStringFromDate:frameTime
														   dateStyle:NSDateFormatterMediumStyle 
														   timeStyle:NSDateFormatterShortStyle]];
}

- (void)updateComments:(NSArray *)newComments
{
    [frameComments removeAllObjects];
    [sessionComments removeAllObjects];
    
    for (Comment * comment in newComments)
    {
        NSMutableArray * commentsArray = (comment.isFrameComment) ? frameComments : sessionComments;
        [commentsArray addObject:comment];
    }
    
    [sessionComments sortUsingSelector:@selector(compareEntryTime:)];
    [frameComments sortUsingSelector:@selector(compareEntryTime:)];
    [commentsView reloadData];
    
    // for archive feeds, also update the underlying camera so they show up on the browse view
    if (self.camera.isArchivedSession)
    {
        Session * session = self.camera.sourceObject;
        [session.comments removeAllObjects];
        [session.comments addObjectsFromArray:newComments];
    }
}

- (void)enableMapViewAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [mapView addAnnotation:self.camera];
    [self setMapRegion:coordinate];
    self.hasLocation = YES;
    
    UIViewController * rootViewController = [RealityVisionAppDelegate rootViewController];
    if ([rootViewController isKindOfClass:[MainMapViewController class]] && ((self.camera.isDirect) || (isLiveFeed)))
    {
        MainMapViewController * mainMapViewController = (MainMapViewController *)rootViewController;
        mainMapViewController.auxiliaryMapDelegate = mapView.delegate;
    }
}

- (void)playVideoFromComment:(Comment *)comment
{
	[self playVideoFromTime:comment.frameTime andRemainPaused:NO];
}

- (BOOL)endOfVideoHidden
{
	return replayButton.hidden;
}

- (void)setEndOfVideoHidden:(BOOL)hidden
{
    // determine the positioning of Replay Controls once they're about to be shown
    if (! hidden)
    {
        [self layoutReplayView];
    }
    
	replayButton.hidden = endOfVideoLabel.hidden = hidden;
}

- (void)createVideoControls 
{
	NSAssert(videoControls==nil,@"Video controls were already created");
	
	const CGFloat kVideoControlsWidth = 300;
	const CGFloat kVideoControlsHeight = 90;
	const CGFloat kPad = 20;
	
	videoControls = [[VideoControlsView alloc] initWithFrame:CGRectMake(CENTER(self.watchView.bounds.size.width, kVideoControlsWidth),
																		self.watchView.bounds.size.height - kVideoControlsHeight - kPad,
																		kVideoControlsWidth,
																		kVideoControlsHeight)];
    [videoControls showLiveButton:NO];
    [videoControls enableForwardButton:YES];
    videoControls.delegate = self;
    videoControls.isPlaying = YES;
    isPaused = NO;
    [self.watchView addSubview:videoControls];
}

- (void)layoutReplayView
{
	// bounds in which replay view will be centered
    CGRect bounds = self.watchView.bounds;
	bounds.origin.y += 50;
	bounds.size.height -= 50;
	
	if ((videoControls != nil) && (! videoControls.hidden))
    {
		// if video controls are shown, make sure replay view is above them
        bounds.size.height = videoControls.frame.origin.y;
    }
    
	// center the replay button vertically and horizontally
	CGFloat y = CENTER(bounds.size.height, replayButton.bounds.size.height) + bounds.origin.y;
    CGFloat x = CENTER(bounds.size.width, replayButton.bounds.size.width);
    [replayButton setOrigin:CGPointMake(x, y)];
	
	// position the end of video label below the replay button
    y += replayButton.bounds.size.height;
	x = CENTER(bounds.size.width, endOfVideoLabel.bounds.size.width);
    [endOfVideoLabel setOrigin:CGPointMake(x, y)];
}

- (UIGestureRecognizer *)addTapGestureAction:(SEL)action toView:(UIView *)theView
{
	UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
	[theView addGestureRecognizer:gesture];
	return gesture;
}

- (UIGestureRecognizer *)addTapGestureAction:(SEL)action toView:(UIView *)theView waitForGesture:(UIGestureRecognizer *)firstGesture
{
	UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
	[gesture requireGestureRecognizerToFail:firstGesture];
	[theView addGestureRecognizer:gesture];
	return gesture;
}

- (UIGestureRecognizer *)addTapGestureAction:(SEL)action toView:(UIView *)theView taps:(NSUInteger)taps touches:(NSUInteger)touches
{
	UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
	gesture.numberOfTapsRequired = taps;
	gesture.numberOfTouchesRequired = touches;
	[theView addGestureRecognizer:gesture];
	return gesture;
}

@end
