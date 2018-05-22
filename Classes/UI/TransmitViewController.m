//
//  TransmitViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/25/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "TransmitViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+RealityVision.h"
#import "SystemUris.h"
#import "GpsLockStatus.h"
#import "CameraInfoWrapper.h"
#import "TransmitterInfo.h"
#import "MotionJpegTransmitClient.h"
#import "ClientTransaction.h"
// @todo #import "HeadRequest.h"
#import "ConfigurationManager.h"
#import "LocationStatusBarButtonItem.h"
#import "PushToTalkBar.h"
#import "PushToTalkController.h"
#import "PttChannelManager.h"
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


#define TRANSMIT_RETRY_DELAY (30.0)


#pragma mark - Statistics timer

#define NANOSECONDS_PER_SECOND   (1000 * 1000 * 1000)
#define STAT_DISPLAY_INTERVAL_NS (NANOSECONDS_PER_SECOND)

static dispatch_source_t CreateDispatchTimer(uint64_t interval,
											 uint64_t leeway,
											 dispatch_queue_t queue,
											 dispatch_block_t block)
{
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
	if (timer != NULL)
	{
		dispatch_source_set_timer(timer, 
								  dispatch_time(DISPATCH_TIME_NOW, interval), 
								  interval, 
								  leeway);
		
		dispatch_source_set_event_handler(timer, block);
		dispatch_resume(timer);
	}
	
	return timer;
}


#ifdef RV_TRANSMIT_BACKGROUND
@interface TransmitViewController (BackgroundTransmit)

@property (nonatomic,retain) UILocalNotification * backgroundNotification;

@end
#endif


@implementation TransmitViewController
{
	PushToTalkBar                     * pttBar;
	TransmitPreferencesViewController * preferencesViewController;
	EnterCommentViewController        * enterCommentViewController;
	UINavigationController            * shareVideoViewController;
	UIActionSheet                     * activeActionSheet;
	
	BOOL                         transmitStarted;
    BOOL                         transmitComplete;
	BOOL                         needToGetComment;
	BOOL                         shareVideoInProgress;
	CGFloat                      jpegQuality;
    NSTimer                    * retryTimer;
	
	dispatch_queue_t             dispatchQueue;
	dispatch_semaphore_t         transmitCompleteSemaphore;
	dispatch_source_t            frameRateTimer;
	BOOL                         errorWritingFrame;
	uint8_t                    * frameBuffer;
	size_t                       frameBufferSize;
	
#ifdef RV_TRANSMIT_BACKGROUND
	UILocalNotification        * backgroundNotification;
	UIBackgroundTaskIdentifier   backgroundTaskId;
#endif
	
#if TARGET_OS_EMBEDDED
	AVCaptureSession           * captureSession;
	MotionJpegTransmitClient   * client;
#endif
}


@synthesize delegate;
@synthesize toolbar;
@synthesize imageView;
@synthesize statisticsView;
@synthesize frameRateLabel;
@synthesize bitRateLabel;

#ifdef RV_TRANSMIT_BACKGROUND
@synthesize backgroundNotification;
#endif


#pragma mark - Initialization and cleanup

- (void)createToolbar
{
    UIBarButtonItem * flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                 target:nil 
                                                                                 action:NULL];
    
    UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                  target:self 
                                                                                  action:@selector(doneButtonPressed)];
    
    UIBarButtonItem * locationStatus = [[LocationStatusBarButtonItem alloc] initWithLocationProvider:[RealityVisionClient instance]];
    
    UIBarButtonItem * shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                                   target:self 
                                                                                   action:@selector(shareButtonPressed:)];
    
    UIBarButtonItem * settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear"] 
                                                                         style:UIBarButtonItemStyleBordered 
                                                                        target:self 
                                                                        action:@selector(preferencesButtonPressed)];
    
    [self.toolbar setItems:[NSArray arrayWithObjects:doneButton, flexSpace, 
                                                     locationStatus, flexSpace, 
                                                     shareButton, flexSpace, 
                                                     settingsButton, nil] 
                  animated:NO];
}

- (void)dealloc 
{
	DDLogVerbose(@"TransmitViewController dealloc");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [retryTimer invalidate];
	[self releaseTransmitResources];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"TransmitViewController viewDidLoad");
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Transmit",@"Transmit");
    [self createToolbar];
	
	// create ptt bar
	pttBar = [[PushToTalkBar alloc] initWithFrame:CGRectMake(420, 0, 60, 268)];
	pttBar.delegate = [PushToTalkController instance];
	[self.view addSubview:pttBar];

	// load transmit preferences
	preferencesViewController = 
		[[TransmitPreferencesViewController alloc] initWithNibName:@"TransmitPreferencesViewController" 
															bundle:nil];
	preferencesViewController.delegate = self;
	
	transmitStarted = NO;
	needToGetComment = NO;
	errorWritingFrame = NO;

#ifdef RV_TRANSMIT_BACKGROUND
	backgroundTaskId = UIBackgroundTaskInvalid;
#endif
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"TransmitViewController viewDidUnload");
    [super viewDidUnload];
    [retryTimer invalidate];
    retryTimer = nil;
    toolbar = nil;
	statisticsView = nil;
	frameRateLabel = nil;
	bitRateLabel = nil;
    activeActionSheet = nil;
	preferencesViewController = nil;
	enterCommentViewController = nil;
	shareVideoViewController = nil;
	activeActionSheet = nil;
	pttBar = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"TransmitViewController viewWillAppear");
	[super viewWillAppear:animated];
	
	// layout ptt bar
	pttBar.hidden = [[PttChannelManager instance].channels count] == 0;
	[pttBar layoutPttBarAndResizeView:imageView forInterfaceOrientation:self.interfaceOrientation];
	
	// register for changes to available channels
	[[PttChannelManager instance] addObserver:self 
								   forKeyPath:@"channels" 
									  options:NSKeyValueObservingOptionNew 
									  context:NULL];
	
	if (! transmitStarted)
	{
        self.statisticsView.hidden = (! preferencesViewController.preferences.showStatistics);
		[self start];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"TransmitViewController viewDidAppear");
	[super viewDidAppear:animated];

	// BUG-4393 - recreating the toolbar to get around an iOS7 issue that may be resolved by compiling against the iOS7 SDK
	[self.toolbar setItems:nil];
	[self createToolbar];
	
    if (needToGetComment)
	{
		// we tried to stop and get comments while another modal was on top of this one, so try again
		needToGetComment = NO;
		[self stopAndGetComments:YES];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"TransmitViewController viewWillDisappear");
	[super viewWillDisappear:animated];
    [retryTimer invalidate];
    retryTimer = nil;
	[pttBar resetTalkButton];
	[[PttChannelManager instance] removeObserver:self forKeyPath:@"channels"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // force landscape orientation (ios5)
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationLandscapeRight;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)appDidEnterBackground:(NSNotification *)notification
{
    if (shareVideoInProgress)
    {
        [self dismissShareVideoViewControllerAnimated:NO];
    }
    
#ifndef RV_TRANSMIT_BACKGROUND
    [self stopAndGetComments:YES];
#else
    [self scheduleBackgroundNotification];
#endif
}


#pragma mark - Transmit control methods

- (void)start
{
	NSAssert(!transmitStarted,@"Transmit can only be started once");
    DDLogInfo(@"TransmitViewController start");
    transmitStarted = YES;
    transmitComplete = NO;
	
	// notify when app enters background so we can dismiss the share video view controller
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appDidEnterBackground:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
	// notify when reach cellular video streaming limit
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(stopStreamingVideo:)
											     name:RvStopVideoStreamingNotification 
											   object:nil];
#endif
	
	// create serial dispatch queue for processing frames
	dispatchQueue = dispatch_queue_create("camera-queue", NULL);
	
	if (dispatchQueue == NULL)
	{
		DDLogError(@"Could not create dispatch queue");
		// no need to release transmit resources because we haven't allocated any yet
		return;
	}
	
	// create semaphore for waiting on transmit complete
	transmitCompleteSemaphore = dispatch_semaphore_create(0);
	
	if (transmitCompleteSemaphore == NULL)
	{
		DDLogError(@"Could not create semaphore");
		[self releaseTransmitResources];
		return;
	}
	
#if TARGET_OS_EMBEDDED
	
	// get video camera
	AVCaptureDevice * videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	NSError         * error = nil;
	
	AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
	if (videoInput == nil) 
	{
		DDLogError(@"Failed to get video capture device");
		[self releaseTransmitResources];
		return;
	}
	
	AVCaptureVideoDataOutput * videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	if (videoOutput == nil)
	{
		DDLogError(@"Failed to create video capture output");
		[self releaseTransmitResources];
		return;
	}
	
	// set the video output to store frame in BGRA 
	NSString     * key           = (NSString *)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber     * value         = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary * videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	
	[videoOutput setVideoSettings:videoSettings];
	[videoOutput setSampleBufferDelegate:self queue:dispatchQueue];
	
#ifdef RV_LIMIT_FRAME_RATE
	const uint32_t FRAME_RATE = 10;
	videoOutput.minFrameDuration = CMTimeMake(1, FRAME_RATE);
#endif
	
	// initialize jpeg compression
	[self setjpegQuality:preferencesViewController.preferences.jpegCompression];
	
	// create capture preset
	TransmitCameraResolution cameraResolution = preferencesViewController.preferences.cameraResolution;
	NSString * captureSessionPreset = (cameraResolution == TR_High)   ? AVCaptureSessionPresetHigh : 
	                                  (cameraResolution == TR_Medium) ? AVCaptureSessionPresetMedium 
	                                                                  : AVCaptureSessionPresetLow;
	
    if (! [videoCaptureDevice supportsAVCaptureSessionPreset:captureSessionPreset])
    {
        DDLogError(@"Camera doesn't support desired resolution");
		[self releaseTransmitResources];
        return;
    }
	
	// create capture session
	captureSession = [[AVCaptureSession alloc] init];
	[captureSession beginConfiguration];
	[captureSession addInput:videoInput];
	[captureSession addOutput:videoOutput];
	[captureSession setSessionPreset:captureSessionPreset];
	[captureSession commitConfiguration];
	
	// create transmit client
	NSString * deviceId    = [RealityVisionClient instance].deviceId;
	NSURL    * baseUrl     = [ConfigurationManager instance].systemUris.videoStreamingBase;
	NSURL    * transmitUrl = [baseUrl URLByAppendingPathComponent:deviceId];
	
	NSURLCredential * credential = [ConfigurationManager instance].credential;
	client = [[MotionJpegTransmitClient alloc] initWithUrl:transmitUrl 
                                                      credential:credential 
                                                        delegate:self];
	
	if (! [client open:&error])
	{
		DDLogError(@"Error opening MotionJpegTransmitClient: %@", error);
		[self releaseTransmitResources];
        return;
	}
	
	// we're good to go, so start the capture session
	[self setBandwidthLimit:preferencesViewController.preferences.bandwidthLimit];
	[captureSession performSelector:@selector(startRunning) 
						 withObject:nil 
						 afterDelay:0.1];
#endif
	
	// create timer to update transmit statistics
	frameRateTimer = CreateDispatchTimer(STAT_DISPLAY_INTERVAL_NS, 0, 
										 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
										 ^{ [self performSelectorOnMainThread:@selector(updateStatistics) 
																   withObject:nil 
																waitUntilDone:NO]; 
										  });
	if (frameRateTimer == NULL)
	{
		// no need to release the transmit resources in this case ... we can run fine without knowing frame rate
		DDLogError(@"Failed to create frame rate timer");
	}
	
	// if we got this far, we are transmitting so don't let screen go to sleep
	UIApplication * app = [UIApplication sharedApplication];
	app.idleTimerDisabled = YES;

#ifdef RV_TRANSMIT_BACKGROUND
	backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{ [self stopAndGetComments:YES]; }];
#endif
}

- (void)retry
{
#if TARGET_OS_EMBEDDED
	DDLogInfo(@"Trying to reopen transmit client");
	
	NSError * error = nil;
	
	if (! [client open:&error])
	{
		DDLogError(@"Error opening MotionJpegTransmitClient: %@", error);
		[self performSelector:@selector(retry) withObject:nil afterDelay:TRANSMIT_RETRY_DELAY];
        return;
	}
	
	[captureSession startRunning];
#endif
}

- (void)stopAndGetComments:(BOOL)getComments
{
	DDLogInfo(@"TransmitViewController stop");
    
	[[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];

#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
	[[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:RvStopVideoStreamingNotification 
                                                  object:nil];
#endif
	
	if (enterCommentViewController)
	{
		// if we are awaiting comments but are told to force close, dismiss the enterCommentViewController
		if (! getComments)
		{
            [self didEnterComment:nil];
		}
		
		// only stopAndGetComments once
		return;
	}
	
	if (self.presentedViewController == preferencesViewController)
	{
		DDLogVerbose(@"Dismissing preferences view controller");
		
        // dismiss transmit preferences before continuing
        [self dismissViewControllerAnimated:YES completion:^{ [self stopAndGetComments:getComments]; }];
		return;
	}
	
	if (self.presentedViewController)
	{
		DDLogVerbose(@"Waiting for modal view controller to close before getting comment");
		needToGetComment = YES;
		return;
	}
	
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
#ifdef RV_TRANSMIT_BACKGROUND
	[self cancelBackgroundNotification];
	[[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
	backgroundTaskId = UIBackgroundTaskInvalid;
#endif
	
#if TARGET_OS_EMBEDDED
	[captureSession stopRunning];
	[client close];
#endif
	
    dispatch_async(dispatchQueue, ^{ [self releaseTransmitResources]; });
	
	if (getComments)
	{
        [self presentEnterCommentViewController];
	}
	else
	{
		DDLogVerbose(@"Dismissing transmit view controller");
		[delegate didStopTransmitting];
	}
}


#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
- (void)stopStreamingVideo:(NSNotification *)notification
{
#if TARGET_OS_EMBEDDED
	if (client.isOpen)
	{
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		{
			// on iPad, alert will be shown by MainMapViewController
			RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
			[rootViewController showMaxVideoStreamingAlertWithDelegate:nil];
		}
		
		[self stopAndGetComments:YES];
	}
#endif
}
#endif

- (void)notifyDelegateIfNotSharing
{
    // notify delegate that transmit is complete unless user is in the process of sharing video
    // note that delegate will dismiss this view controller when complete
    if (! shareVideoInProgress)
    {
        [delegate didStopTransmitting];
    }
}

// 
// This method releases resources created by start.  It should only be called by either start, 
// if it was unable to allocate all resources to start transmitting; or by stopAndGetComments, 
// when the transmit session is complete.
// 
// These resources should not be released by viewDidUnload because the View Controller can be 
// unloaded during an active transmit by a low memory warning.  Even if the view is unloaded, 
// we want to keep the transmit resources around until we are actually done transmitting.
// 
- (void)releaseTransmitResources
{
	DDLogVerbose(@"TransmitViewController releaseTransmitResources");
	
	if (frameRateTimer != NULL)
	{
		dispatch_source_cancel(frameRateTimer);
 		//dispatch_release(frameRateTimer);
        frameRateTimer = NULL;
	}
    
#if TARGET_OS_EMBEDDED
	client = nil;
	captureSession = nil;
#endif
	
	if (transmitCompleteSemaphore != NULL)
	{
		//dispatch_release(transmitCompleteSemaphore);
		transmitCompleteSemaphore = NULL;
	}
	
	if (dispatchQueue != NULL)
	{
		//dispatch_release(dispatchQueue);
		dispatchQueue = NULL;
	}
	
	if (frameBuffer != NULL)
	{
		free(frameBuffer);
		frameBuffer = NULL;
		frameBufferSize = 0;
	}
}


#pragma mark - Transmit preferences and statistics

- (void)setjpegQuality:(TransmitJpegCompression)jpegCompression
{
	// high compression = lowest quality
	jpegQuality = (jpegCompression == TC_High)   ? 0.50 :
	              (jpegCompression == TC_Medium) ? 0.75 : 1.00;
    DDLogVerbose(@"Transmit compression quality set to %f", jpegQuality);
}

- (void)setBandwidthLimit:(TransmitBandwidthLimit)bandwidthLimit
{
#if TARGET_OS_EMBEDDED
    static const int BitRate[] = { 100, 200, 300, 500, -1 };
    client.targetBitRate = BitRate[bandwidthLimit];
    DDLogVerbose(@"Transmit bandwidth limit set to %d kbps", client.targetBitRate);
#endif
}

- (void)transmitPreferencesDidChangeResolution:(BOOL)resolutionChanged 
								   compression:(BOOL)compressionChanged 
									 bandwidth:(BOOL)bandwidthChanged 
								showStatistics:(BOOL)showStatisticsChanged
{
	BOOL resetClientStatistics = NO;
	
	if (resolutionChanged)
	{
		TransmitCameraResolution resolution = preferencesViewController.preferences.cameraResolution;
		DDLogVerbose(@"Transmit resolution set to %d", resolution);
		
#if TARGET_OS_EMBEDDED
		NSString * captureSessionPreset = (resolution == TR_High)   ? AVCaptureSessionPresetHigh : 
										  (resolution == TR_Medium) ? AVCaptureSessionPresetMedium 
																	: AVCaptureSessionPresetLow;
		
		// configure capture session
		[captureSession beginConfiguration];
		[captureSession setSessionPreset:captureSessionPreset];
		[captureSession commitConfiguration];
		resetClientStatistics = YES;
#endif
	}
	
	if (compressionChanged)
	{
		[self setjpegQuality:preferencesViewController.preferences.jpegCompression];
		resetClientStatistics = YES;
	}
	
	if (bandwidthChanged)
	{
        [self setBandwidthLimit:preferencesViewController.preferences.bandwidthLimit];
		resetClientStatistics = YES;
	}
	
	if (showStatisticsChanged)
	{
		self.statisticsView.hidden = (! preferencesViewController.preferences.showStatistics);
	}
	
	if (resetClientStatistics)
	{
#if TARGET_OS_EMBEDDED
		[client resetStatistics];
#endif
	}
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)updateStatistics
{
#if TARGET_OS_EMBEDDED
	if (! client.isOpen)
	{
		DDLogWarn(@"Statistics are being updated after client closed");
		return;
	}
	
	[client computeStatistics];
		
	NSString * frameRateString = [NSString stringWithFormat:@"%.1f fps",  client.frameRate];
	NSString * bitRateString   = [NSString stringWithFormat:@"%.1f kbps", client.bitRate];
		
	self.frameRateLabel.text = frameRateString;
	self.bitRateLabel.text   = bitRateString;
		
	if (preferencesViewController.preferences.showStatistics)
	{
		[self.frameRateLabel setNeedsDisplay];
		[self.bitRateLabel   setNeedsDisplay];
	}
#endif
}


#pragma mark - Enter comments methods

- (void)presentEnterCommentViewController
{
    DDLogVerbose(@"Presenting enter comment view controller");
    
    enterCommentViewController = 
        [[EnterCommentViewController alloc] initWithNibName:@"EnterCommentViewController" 
                                                      bundle:nil];
    
    enterCommentViewController.title = NSLocalizedString(@"Enter Transmit Comment",@"Enter transmit comment title");
    enterCommentViewController.delegate = self;
    enterCommentViewController.restrictToLandscapeOrientation = YES;
    
    // present enter comment view controller on top of share video view controller, if it exists
    UIViewController * topViewController = shareVideoInProgress ? shareVideoViewController : self;
    [topViewController presentViewController:enterCommentViewController animated:YES completion:NULL];
}

- (void)dismissEnterCommentViewController
{
    NSAssert(enterCommentViewController!=nil,@"EnterCommentViewController is not shown");
    UIViewController * presentingViewController = shareVideoInProgress ? shareVideoViewController : self;
    [presentingViewController dismissViewControllerAnimated:YES completion:^{ [self notifyDelegateIfNotSharing]; }];
    enterCommentViewController = nil;
}

- (void)didEnterComment:(NSString *)comment
{
	DDLogVerbose(@"TransmitViewController didEnterComment");
    transmitComplete = YES;
	
	if (! NSStringIsNilOrEmpty(comment))
	{
		NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
		[clientTransaction addComment:comment toLastSessionforDevice:[RealityVisionClient instance].deviceId];
	}
    
    [self dismissEnterCommentViewController];
}


#pragma mark - Video sharing methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        NSInteger theButtonIndex = buttonIndex - actionSheet.firstOtherButtonIndex;
        [self presentShareVideoViewControllerAndShareFromBeginning:(theButtonIndex == 1)];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSAssert(activeActionSheet==actionSheet,@"TransmitViewController dismissed action sheet was not the active action sheet");
    activeActionSheet = nil;
}

- (void)presentShareVideoViewControllerAndShareFromBeginning:(BOOL)shareFromBeginning
{
    RecipientSelectionViewController * viewController = 
        [[RecipientSelectionViewController alloc] initWithNibName:@"RecipientSelectionViewController" 
                                                            bundle:nil];
    viewController.shareCurrentTransmitSession = YES;
    viewController.shareCurrentTransmitSessionFromBeginning = shareFromBeginning;
    viewController.delegate = self;
    viewController.showCancelButton = YES;
    viewController.restrictToLandscapeOrientation = YES;
    
    shareVideoViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:shareVideoViewController animated:YES completion:NULL];
}

- (void)dismissShareVideoViewControllerAnimated:(BOOL)animated
{
    [self dismissViewControllerAnimated:animated completion:NULL];
    shareVideoViewController = nil;
}

- (void)didCompleteVideoSharing
{
    [self dismissShareVideoViewControllerAnimated:(!transmitComplete)];
    
    if (transmitComplete)
    {
        [delegate didStopTransmitting];
    }
}

- (BOOL)shareVideoInProgress
{
    return (shareVideoViewController != nil);
}


#pragma mark - Button actions

- (IBAction)doneButtonPressed
{
    [activeActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
	[self stopAndGetComments:YES];
}

- (IBAction)shareButtonPressed:(id)sender
{
    if (activeActionSheet != nil)
    {
        return;
    }
    
    // don't use a cancel button on the iPad because this will be shown in a popover
    NSString * cancelButton = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? NSLocalizedString(@"Cancel",@"Cancel") : nil;
    
    activeActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self 
                                                 cancelButtonTitle:cancelButton 
                                            destructiveButtonTitle:nil 
                                                 otherButtonTitles:NSLocalizedString(@"Share live feed",@"Share live feed"),
                                                                   NSLocalizedString(@"Share from beginning",@"Share from beginning"),
                                                                   nil];
    [activeActionSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)cameraButtonPressed
{
	// @todo implement ability to toggle between front and rear camera
}

- (IBAction)preferencesButtonPressed
{
	DDLogVerbose(@"TransmitViewController preferencesButtonPressed");
    [activeActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
    [self presentViewController:preferencesViewController animated:YES completion:NULL];
}

- (void)retryTimerFired:(NSTimer *)timer
{
    [self retry];
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
		[pttBar hide:hide andResizeView:imageView interfaceOrientation:self.interfaceOrientation animated:YES];
	}
}


#ifdef RV_TRANSMIT_BACKGROUND

#pragma mark - Background processing

- (void)scheduleBackgroundNotification 
{
	NSAssert(self.backgroundNotification==nil,@"There is already an active background notification");
	DDLogInfo(@"TransmitViewController scheduleBackgroundNotification");
	
	static const NSTimeInterval transmitReminderAlertSeconds = 8 * 60;
	
	self.backgroundNotification = [[[UILocalNotification alloc] init] autorelease];
	self.backgroundNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:transmitReminderAlertSeconds];
	self.backgroundNotification.timeZone = [NSTimeZone defaultTimeZone];
	self.backgroundNotification.alertBody = NSLocalizedString(@"Transmit session is about to end",@"Transmit session is about to end prompt");
	self.backgroundNotification.alertAction = NSLocalizedString(@"Continue",@"Continue");
	self.backgroundNotification.alertLaunchImage = @"Default-transmit";
	self.backgroundNotification.soundName = UILocalNotificationDefaultSoundName;
		
	[[UIApplication sharedApplication] scheduleLocalNotification:self.backgroundNotification];
}

- (void)cancelBackgroundNotification
{
	if (self.backgroundNotification != nil)
	{
		DDLogInfo(@"TransmitViewController cancelBackgroundNotification");
		[[UIApplication sharedApplication] cancelLocalNotification:self.backgroundNotification];
		self.backgroundNotification = nil;
	}
}

#endif


#pragma mark - HeadRequest (for authentication)

#if 0  // @todo currently head requests are not used -- leaving here in case that changes
- (void)authenticateWithHeadRequest
{
	NSAssert(self.transmitUrl!=nil,@"transmitUrl must be set");
	HeadRequest * headRequest = [[HeadRequest alloc] initWithUrl:self.transmitUrl delegate:self];
	[headRequest send];
}

- (void)onAuthenticate:(NSError*)error
{
	NSAssert(self.transmitUrl!=nil,@"transmitUrl must be set");
	
	if (error != nil)
	{
		self.credential = [ConfigurationManager getCredentialForUrl:self.transmitUrl];
	}
	else 
	{
		DDLogError(@"TransmitViewController onAuthenticate error: %@",error);
	}
}
#endif


#pragma mark - TransmitClientDelegate

- (void)writeDidComplete:(NSError *)error
{
	// error was already logged by caller and we're not going to display to user
	errorWritingFrame = (error != nil);
	dispatch_semaphore_signal(transmitCompleteSemaphore);
}

- (void)clientClosedWithError:(NSError *)error
{
	DDLogWarn(@"TransmitViewController clientClosedWithError: %@", error);
	
#if TARGET_OS_EMBEDDED
	[captureSession stopRunning];
#endif
	
	errorWritingFrame = YES;
	dispatch_semaphore_signal(transmitCompleteSemaphore);
	
    if (! ([error.domain isEqualToString:RV_DOMAIN] && (error.code == RV_USER_CANCEL)))
    {
        // try again later
        retryTimer = [NSTimer scheduledTimerWithTimeInterval:TRANSMIT_RETRY_DELAY 
													  target:self 
													selector:@selector(retryTimerFired:) 
													userInfo:nil 
													 repeats:NO];
    }
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods

#if TARGET_OS_EMBEDDED

- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection
{
	// create an autorelease pool to ensure that any temporary objects we create
	// (such as the JPEG image we transmit) are released when we're done
	@autoreleasepool 
	{
		if (! client.isOpen)
		{
			DDLogVerbose(@"TransmitViewController captureOutput: client is closed");
			return;
		}
		
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		CVPixelBufferLockBaseAddress(imageBuffer,0);
		
		uint8_t * baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
		size_t    bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
		size_t    width       = CVPixelBufferGetWidth(imageBuffer); 
		size_t    height      = CVPixelBufferGetHeight(imageBuffer); 
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		if (colorSpace == NULL)
		{
			DDLogError(@"Could not create color space");
		}
		
		// copy image into our own buffer (required for calling CGBitmapContextCreateImage)
		size_t imageSize = bytesPerRow * height * sizeof(char); 
		if (imageSize > frameBufferSize)
		{
			DDLogVerbose(@"Allocating buffer of size %zd for resolution %zdx%zd", imageSize, width, height);
			
			if (frameBuffer != NULL)
			{
				free(frameBuffer);
				frameBufferSize = 0;
			}
			
			frameBuffer = malloc(imageSize);
			if (frameBuffer == NULL)
			{
				DDLogError(@"Unable to allocate buffer large enough for image");
				CGColorSpaceRelease(colorSpace);
				return;
			}
			
			frameBufferSize = imageSize;
		}
		
		memcpy(frameBuffer, baseAddress, imageSize);
		
		CGContextRef newContext = CGBitmapContextCreate(frameBuffer, width, height, 8,
														bytesPerRow, colorSpace,
														kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
		if (newContext == nil)
		{
			DDLogError(@"Could not create bitmap context");
		}
		
		CGImageRef newImage = CGBitmapContextCreateImage(newContext);
		
		// release resources and unlock image buffer
		CGContextRelease(newContext);
		CGColorSpaceRelease(colorSpace);
		CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
		
		// set image in image view
		// NOTE the following forces the view orientation to match what is transmitted no matter how the phone is rotated
		UIImageOrientation viewOrientation = 
			UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? UIImageOrientationUp : UIImageOrientationDown;
		
		UIImage * transmitUIImage = [UIImage imageWithCGImage:newImage];
		UIImage * viewUIImage     = [UIImage imageWithCGImage:newImage 
														scale:1 
												  orientation:viewOrientation];
		CGImageRelease(newImage);
		
		if ((transmitUIImage != nil) && (viewUIImage != nil))
		{
			NSData   * jpegData = UIImageJPEGRepresentation(transmitUIImage, jpegQuality);
			NSString * gpgga    = [RealityVisionClient instance].transmitLocationAsGpgga;
			
			// transmit jpeg data and wait for it to complete
			errorWritingFrame = NO;
			[client writeJpegData:jpegData withGpgga:gpgga];
			dispatch_semaphore_wait(transmitCompleteSemaphore, DISPATCH_TIME_FOREVER);
			
			// display transmitted image if there was no error
			if ((client.isOpen) && (! errorWritingFrame))
			{
					[self performSelectorOnMainThread:@selector(showImage:) 
										   withObject:viewUIImage 
										waitUntilDone:YES];
			}
		}
	}
}

- (void)showImage:(UIImage *)image
{
	self.imageView.image = image;
}

#endif

@end
