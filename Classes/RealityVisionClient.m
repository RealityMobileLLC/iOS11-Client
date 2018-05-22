//
//  RealityVisionClient.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RealityVisionClient.h"
#import <AudioToolbox/AudioServices.h>
#import "NSString+RealityVision.h"
#import "RealityVisionAppDelegate.h"
#import "RootViewController.h"
#import "CommandInboxViewController.h"
#import "ClientConfiguration.h"
#import "ConfigurationManager.h"
#import "ConnectionProfile.h"
#import "ConnectionDatabase.h"
#import "DeviceCapabilities.h"
#import "DownloadManager.h"
#import "PttChannelManager.h"
#import "SystemUris.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "ClientServiceInfo.h"
#import "Command.h"
#import "CommandWrapper.h"
#import "DirectiveType.h"
#import "Session.h"
#import "TransmitterInfo.h"
#import "RvError.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_VERBOSE; // @todo LOG_LEVEL_INFO;
#endif

// define to limit streaming on both cell and wifi with a timeout of 1 minute
//#define RV_LIMITS_STREAMING_DEBUG


enum 
{
	VIEW_COMMAND_ALERT_TAG,
	SIGN_ON_ALERT_TAG,
	SIGN_OFF_ALERT_TAG,
	CANT_CONNECT_ALERT_TAG,
};


// keys used for serialization
static NSString * const KEY_SERVER_URL           = @"LastServerUrl";
static NSString * const KEY_SIGNED_ON            = @"SignedOn";
static NSString * const KEY_LOCATION_AWARE       = @"LocationAware";
static NSString * const KEY_LOCATION_ACCURACY    = @"LocationAccuracy";
static NSString * const KEY_LOCATION             = @"Location";
static NSString * const KEY_LOCATION_LAST_UPDATE = @"LocationUpdate";
static NSString * const KEY_LOCATION_HAS_LOCK    = @"LocationHasLock";
static NSString * const KEY_LOCATION_HAD_LOCK    = @"LocationHadLock";
static NSString * const KEY_CONNECTION_PROFILE   = @"ConnectionProfile";
static NSString * const KEY_APN_TOKEN            = @"ApnToken";
static NSString * const KEY_CONFIGURATION        = @"Configuration";
static NSString * const KEY_LAST_USER            = @"LastUser";
static NSString * const KEY_MAP_TYPE             = @"MapType";
static NSString * const KEY_MAP_SEARCH_TEXT      = @"MapSearchText";

// localized error messages
static NSString * ERROR_CANT_CONNECT_TITLE;
static NSString * ERROR_CANT_CONNECT_MSG;


@interface RealityVisionClient()
@property (nonatomic) BOOL isConnecting;
@property (nonatomic) NetworkStatus networkStatus;
@end


@implementation RealityVisionClient
{
	// serialized data
	NSURL                  * configurationUrl;
	NSString               * lastSignedOnUser;
	NSString               * apnToken;
	
	// current status
	BOOL                     isSignedOn;
	BOOL                     isWatching;
	BOOL                     isTransmitting;
	BOOL                     isAlerting;
	NSInteger                watchCount;
	MKMapType                mapType;
	BOOL                     isLocationAware;
	RVLocationAccuracy       locationAccuracy;
	BOOL                     hasLocationLock;
	BOOL                     hasHadLocationLock;
	CLLocation             * lastReportedLocation;
	NSDate                 * lastLocationUpdate;
	BOOL					 oldIsLocationAware;
	NSTimer                * cnsTimer;
	
	// configuration
	ConnectionProfile      * connectionProfile;
	DeviceCapabilities     * deviceCapabilities;
	CLLocationManager      * locationManager;
	
	// pending activities
    BOOL                     isVerifyingSignOn;
	BOOL                     hasNewApnToken;
    BOOL                     executeCommandOnStartup;
	BOOL                     showCommandInbox;
	NSString               * commandToExecute;
    UIAlertView            * commandNotificationAlert;
	TransmitViewController * transmitViewController;
	
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
	Reachability * networkReachability;
	NSTimer      * streamingOverCellularNotification;
#endif
}

@synthesize isConnecting;
@synthesize isSignedOn;
@synthesize isAlerting;
@synthesize isTransmitting;
@synthesize isLocationAware;
@synthesize locationAccuracy;
@synthesize hasLocationLock;
@synthesize mapType;
@synthesize lastSignedOnUser;
@synthesize searchText;
@synthesize networkStatus;


#pragma mark - Initialization and cleanup

static RealityVisionClient * instance = nil;

+ (RealityVisionClient *)instance
{
    if (instance == nil) 
	{
		@try 
		{
			// restore previous preferences, if they exist
			NSString * prefsFile = [RealityVisionClient getPrefsFilename];
			
			instance = [[NSFileManager defaultManager] fileExistsAtPath:prefsFile] ?
							[NSKeyedUnarchiver unarchiveObjectWithFile:prefsFile] : 
							[[RealityVisionClient alloc] init];
			
			// If the archive file is empty, unarchiveObjectWithFile: returns nil
			// instead of throwing an exception.  This should never happen but we've
			// seen it once.
			if (instance == nil)
			{
				DDLogError(@"Unable to restore RealityVision preferences.");
				instance = [[RealityVisionClient alloc] init];
			}
		}
		@catch (NSException * ex) 
		{
			DDLogError(@"Exception trying to restore preferences: %@", ex);
			instance = [[RealityVisionClient alloc] init];
		}
    }
	
    return instance;
}

+ (void)initialize
{
	if (self == [RealityVisionClient class])
	{
		ERROR_CANT_CONNECT_TITLE = NSLocalizedString(@"Could Not Connect",@"Could not connect alert");
		ERROR_CANT_CONNECT_MSG   = NSLocalizedString(@"Unable to connect to the service. Please review your connection settings.",
													 @"Unable to connect to RealityVision server error text");
	}
}

- (id)init
{
	NSAssert(instance==nil,@"RealityVisionClient singleton already instantiated");
	DDLogVerbose(@"RealityVisionClient init");
	
	self = [super init];
	if (self != nil)
	{
		[self initCommon];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
	NSAssert(instance==nil,@"RealityVisionClient singleton already instantiated");
	DDLogVerbose(@"RealityVisionClient initWithCoder");
	
	[self initCommon];
	configurationUrl     = [coder decodeObjectForKey:KEY_SERVER_URL];
	isVerifyingSignOn    = [coder decodeBoolForKey:KEY_SIGNED_ON];
	lastReportedLocation = [coder decodeObjectForKey:KEY_LOCATION];
	lastLocationUpdate   = [coder decodeObjectForKey:KEY_LOCATION_LAST_UPDATE];
	hasLocationLock      = [coder decodeBoolForKey:KEY_LOCATION_HAS_LOCK];
	hasHadLocationLock   = [coder decodeBoolForKey:KEY_LOCATION_HAD_LOCK];
	connectionProfile    = [coder decodeObjectForKey:KEY_CONNECTION_PROFILE];
	lastSignedOnUser     = [coder decodeObjectForKey:KEY_LAST_USER];
	apnToken             = [coder decodeObjectForKey:KEY_APN_TOKEN];
	locationAccuracy     = [coder decodeIntForKey:KEY_LOCATION_ACCURACY];
	isLocationAware      = [coder decodeBoolForKey:KEY_LOCATION_AWARE];
	
	if ([coder containsValueForKey:KEY_MAP_TYPE])
	{
		mapType = [coder decodeIntForKey:KEY_MAP_TYPE];
	}
	
	if ([coder containsValueForKey:KEY_CONFIGURATION])
	{
		[ConfigurationManager createFromCoder:coder forKey:KEY_CONFIGURATION];
	}
	
	// if connection profile has changed since last launch, sign user off
	if (isSignedOn && ((connectionProfile == nil) || 
					   (! [connectionProfile isEqual:[ConnectionDatabase activeProfile]])))
	{
		DDLogInfo(@"Connection profile changed. Signing off %@", connectionProfile.host);
		isVerifyingSignOn = NO;
		lastReportedLocation = nil;
		hasLocationLock = NO;
		hasHadLocationLock = NO;
		connectionProfile = nil;
		configurationUrl = nil;
		[ConfigurationManager invalidate];
		[[PttChannelManager instance] invalidate];
	}
	
	if ([coder containsValueForKey:KEY_MAP_SEARCH_TEXT] && isSignedOn)
	{
		searchText = [coder decodeObjectForKey:KEY_MAP_SEARCH_TEXT];
	}
	
	DDLogInfo(@"restored device ID = %@ for server %@", self.deviceId, configurationUrl);
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
	DDLogVerbose(@"RealityVisionClient encodeWithCoder");
	[coder encodeObject:configurationUrl     forKey:KEY_SERVER_URL];
	[coder encodeBool:isLocationAware        forKey:KEY_LOCATION_AWARE];
	[coder encodeInt:locationAccuracy        forKey:KEY_LOCATION_ACCURACY];
	[coder encodeBool:isSignedOn             forKey:KEY_SIGNED_ON];
	[coder encodeObject:lastSignedOnUser     forKey:KEY_LAST_USER];
	[coder encodeObject:lastReportedLocation forKey:KEY_LOCATION];
	[coder encodeObject:lastLocationUpdate   forKey:KEY_LOCATION_LAST_UPDATE];
	[coder encodeBool:hasLocationLock        forKey:KEY_LOCATION_HAS_LOCK];
	[coder encodeBool:hasHadLocationLock     forKey:KEY_LOCATION_HAD_LOCK];
	[coder encodeObject:connectionProfile    forKey:KEY_CONNECTION_PROFILE];
	[coder encodeObject:apnToken             forKey:KEY_APN_TOKEN];
	[coder encodeInt:mapType                 forKey:KEY_MAP_TYPE];
	[coder encodeObject:[ConfigurationManager instance] forKey:KEY_CONFIGURATION];
	[coder encodeObject:searchText           forKey:KEY_MAP_SEARCH_TEXT];
}

- (void)initCommon
{
    mapType = MKMapTypeStandard;
	isLocationAware = YES;
	lastLocationUpdate = [NSDate distantPast];
	deviceCapabilities = [[DeviceCapabilities alloc] init];
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version >= 6.0)
    {
		locationManager.pausesLocationUpdatesAutomatically = NO;
    }
	locationAccuracy = kRVLocationAccuracyHigh;
	networkStatus = ReachabilityUnknown;
}

- (void)dealloc
{
    NSAssert(NO,@"RealityVisionClient singleton should never be deallocated");
}


#pragma mark - Properties

- (void)setIsSignedOn:(BOOL)signedOn
{
    if (isSignedOn != signedOn)
    {
        // locationOn is derived from isSignedOn so notify observers
        [self willChangeValueForKey:@"locationOn"];
        isSignedOn = signedOn;
        [self didChangeValueForKey:@"locationOn"];
    }
}

- (CLLocation *)actualLocation
{
	return locationManager.location;
}

- (NSString *)transmitLocationAsGpgga
{
	NSString * gpgga = nil;
	
	if (isLocationAware || isAlerting)
	{
		CLLocation * location = self.actualLocation;
		
		if ([self isLocationLocked:location])
		{
			gpgga = [NSString gpggaStringWithLocation:location];
		}
	}
	
	return gpgga;
}

- (void)setHasLocationLock:(BOOL)locationLock
{
    if (hasLocationLock != locationLock)
    {
        // locationLock is derived from hasLocationLock so notify observers
        [self willChangeValueForKey:@"locationLock"];
        hasLocationLock = locationLock;
        
        if (hasLocationLock)
        {
            hasHadLocationLock = YES;
        }
        [self didChangeValueForKey:@"locationLock"];
    }
}

- (void)setIsLocationAware:(BOOL)wantsToBeLocationAware
{
	if ((wantsToBeLocationAware) && (! isLocationAware))
	{
        // locationOn is derived from isLocationAware, so notify observers
        [self willChangeValueForKey:@"locationOn"];
		isLocationAware = YES;
		
		if (isSignedOn)
		{
			[self startMonitoringLocation];
		}
        
        [self didChangeValueForKey:@"locationOn"];
	}
	else if ((! wantsToBeLocationAware) && (isLocationAware))
	{
        // locationOn is derived from isLocationAware, so notify observers
        [self willChangeValueForKey:@"locationOn"];
		isLocationAware = NO;
		
		if (isSignedOn)
		{
			[self stopMonitoringLocationAndPostStatus];
			hasLocationLock = NO;
		}
        
        [self didChangeValueForKey:@"locationOn"];
	}
}

- (void)setLocationAccuracy:(RVLocationAccuracy)newLocationAccuracy
{
	locationAccuracy = newLocationAccuracy;
	[self setLocationManagerAccuracy:locationAccuracy];
}

- (NSInteger)inboxCommandCount
{
    return [UIApplication sharedApplication].applicationIconBadgeNumber;
}

- (void)setInboxCommandCount:(NSInteger)inboxCommandCount
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = inboxCommandCount;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey 
{
    // indicate the properties for which we implement manual KVO
    if ([theKey isEqualToString:@"locationOn"] || [theKey isEqualToString:@"locationLock"] || [theKey isEqualToString:@"isAlerting"])
    {
        return NO;
    }
    
    return [super automaticallyNotifiesObserversForKey:theKey];
}


#pragma mark - Public methods

- (void)didBecomeActive
{
	DDLogVerbose(@"RealityVisionClient didBecomeActive");
	@try 
	{
		[self startMonitoringNetworkStatus];
		
		if (isTransmitting)
		{
#ifdef RV_TRANSMIT_BACKGROUND
			[transmitViewController cancelBackgroundNotification];
#endif
		}
		
		// setting the property triggers setting the accuracy for the location monitor
		self.locationAccuracy = locationAccuracy;
		
		if (isSignedOn || isVerifyingSignOn)
		{
            isVerifyingSignOn = YES;
			
            // if network is available, verify sign on by trying to get the current command count
            // if it succeeds, it will call didVerifySignOn to finish the startup process
			// if network is not available, defer this until it is
			if (self.networkStatus > NotReachable)
			{
				self.isConnecting = YES;
				[self updateUnreadCommandCount];
			}
		}
	}
	@catch (NSException * exception) 
	{
		DDLogError(@"Exception in RealityVisionClient startup: %@", exception);
	}
}

- (void)didVerifySignOn
{
	DDLogInfo(@"RealityVisionClient didVerifySignOn");
	[self setIsSignedOn:YES];
    [self startCnsTimer];
    [self updateStatus];
	
	if (hasNewApnToken)
	{
		[self postPushNotificationToken];
	}
	
	if (isLocationAware)
	{
		[self startMonitoringLocation];
	}
	else
	{
		[self postLocationStatus];
	}
	
    // update UI now that we've completed startup process
    RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
    [rootViewController didVerifySignOn];
    
    if (executeCommandOnStartup)
    {
        executeCommandOnStartup = NO;
        
        if (showCommandInbox)
        {
            // need to make sure main menu has loaded before the selector runs
            [rootViewController performSelectorOnMainThread:@selector(showCommandInbox) 
                                                 withObject:nil 
                                              waitUntilDone:NO];
            showCommandInbox = NO;
        }
        else if ((commandToExecute != nil) && (! isTransmitting))
        {
            // if we're transmitting, the command will execute when transmit completes
            [self getCommandAndExecute];
        }
    }
}

- (void)didEnterBackground
{
	DDLogVerbose(@"RealityVisionClient didEnterBackground");
    executeCommandOnStartup = NO;
	[self stopCnsTimer];
	[self serialize];
}

- (void)serialize
{
	@try 
	{
		NSString * prefsFile = [RealityVisionClient getPrefsFilename];
		if (! [NSKeyedArchiver archiveRootObject:self toFile:prefsFile])
		{
			DDLogError(@"RealityVisionClient could not save state");
		}
	}
	@catch (NSException * exception) 
	{
		DDLogError(@"Exception trying to serialize preferences: %@", exception);
	}
}

- (void)didReceiveForceCommand:(DirectiveTypeEnum)directive withId:(NSString *)commandId userNotified:(BOOL)userNotified
{
    DDLogInfo(@"RealityVisionClient didReceiveForceCommand (%d)", directive);
    
    if ((directive == DT_GoOffDuty) && isTransmitting)
    {
        // if we were transmitting, stop transmit session
        [self stopTransmitSessionAndGetComments:NO];
    }
    
	executeCommandOnStartup = YES;
    commandToExecute = commandId;
    
    // if the user was notified by iOS while the app was inactive the command will be executed in startup
    if (! userNotified)
    {
        DirectiveType * commandDirective = [[DirectiveType alloc] initWithValue:directive];
        NSDictionary * notificationInfo = [NSDictionary dictionaryWithObject:commandDirective 
                                                                      forKey:@"Directive"];
        
        // notify observers that a new command notification is about to be displayed ...
        // they should dismiss modals (except transmit) and any existing command notifications
        [[NSNotificationCenter defaultCenter] postNotificationName:RvWillDisplayCommandNotification 
                                                            object:self 
                                                          userInfo:notificationInfo];
        [self getCommandAndExecute];
    }
}

- (void)didReceiveCommandNotificationWithMessage:(NSString *)message 
                                       commandId:(NSString *)commandId 
                                  unreadCommands:(NSInteger)unreadCommands 
                                    userNotified:(BOOL)userNotified
{
    DDLogInfo(@"RealityVisionClient didReceiveCommandNotification for command id %@", commandToExecute);
    executeCommandOnStartup = YES;
    showCommandInbox = NO;
    commandToExecute = commandId;
    [self handleCommandNotificationWithMessage:message unreadCommands:unreadCommands userNotified:userNotified];
}

- (void)didReceiveCommandNotificationWithMessage:(NSString *)message 
                                 pendingCommands:(NSInteger)pendingCommands 
                                  unreadCommands:(NSInteger)unreadCommands 
                                    userNotified:(BOOL)userNotified
{
    DDLogInfo(@"RealityVisionClient didReceiveCommandNotification for multiple pending commands (%d)", pendingCommands);
    executeCommandOnStartup = YES;
    showCommandInbox = YES;
    commandToExecute = nil;  // in case we have a pending alert to show a single command
    [self handleCommandNotificationWithMessage:message unreadCommands:unreadCommands userNotified:userNotified];
}

- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification userNotified:(BOOL)userNotified
{
	NSString * action = localNotification.alertAction;
	DDLogInfo(@"RealityVisionClient didReceiveLocalNotification for action %@", action);
	
#ifdef RV_TRANSMIT_BACKGROUND
	// is notification for a soon-to-end transmit session?
	if ([action isEqualToString:NSLocalizedString(@"Continue",@"Continue")])
	{
		// nothing to do ... view controller should appear automatically
		return;
	}
#endif
	
	// local notification is a scheduled sign on or sign off
	BOOL wantsToSignOn = [action isEqualToString:NSLocalizedString(@"Sign On",@"Sign On")];
	
	if (wantsToSignOn == isSignedOn)
	{
		return;
	}
	
	// alert user if the app is active; for the inactive case, the user was already alerted by iOS
	if (! userNotified)
	{
		// alert user of notification
		AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
		
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController resetPttTalkButton];
		
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[RealityVisionAppDelegate appName]
														  message:localNotification.alertBody
														 delegate:self 
												cancelButtonTitle:NSLocalizedString(@"Close",@"Close")
												otherButtonTitles:action,nil];
		alert.tag = wantsToSignOn ? SIGN_ON_ALERT_TAG : SIGN_OFF_ALERT_TAG;
		[alert show];
	}
	else if (wantsToSignOn)
	{
		[self signOn];
	}
	else 
	{
		[self signOff];
	}
}

- (void)toggleLocationAware
{
    DDLogInfo(@"Location on/off pressed");
    [RealityVisionClient instance].isLocationAware = ! [RealityVisionClient instance].isLocationAware;
}

- (void)startAlert
{
    [self willChangeValueForKey:@"isAlerting"];
    isAlerting = YES;
    [self didChangeValueForKey:@"isAlerting"];
    
    [self setStatus:CS_Panic];
	[self startMonitoringLocationForAlert];
    
    if ([DeviceCapabilities supportsVideo])
    {
        [self startTransmitSession];
    }
}

- (void)stopAlert
{
    [self willChangeValueForKey:@"isAlerting"];
    isAlerting = NO;
    [self didChangeValueForKey:@"isAlerting"];
    
    [self setStatus:CS_Connected];
	[self restoreMonitoringLocationAfterAlert];
}

- (void)toggleAlertMode
{
    if (isAlerting)
    {
        [self stopAlert];
    }
    else 
    {
        [self startAlert];
    }
}

- (void)startTransmitSession
{
	if (([DeviceCapabilities supportsVideo]) && (! isTransmitting))
	{
		isTransmitting = YES;
		
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
		[self logReachability:@"transmit"];
#ifdef RV_LIMITS_STREAMING_DEBUG
        if (1)
#else
		if ([networkReachability currentReachabilityStatus] == ReachableViaWWAN)
#endif
		{
			[self scheduleVideoStreamingNotification];
		}
#endif
		
		transmitViewController = [[TransmitViewController alloc] initWithNibName:@"TransmitViewController" 
																			    bundle:nil];
		transmitViewController.delegate = self;
		
		if (isAlerting)
		{
			transmitViewController.title = @"Transmit (Alert)";
		}
		
		RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
		UIViewController * topViewController = appDelegate.navigationController.topViewController;
		[topViewController presentViewController:transmitViewController animated:YES completion:NULL];
	}
}

- (void)stopTransmitSessionAndGetComments:(BOOL)getComments
{
	if (isTransmitting)
	{
		[transmitViewController stopAndGetComments:getComments];
	}
}

- (void)doneTransmitting
{
	transmitViewController = nil;
	
	// some commands are deferred until transmit is complete
	[self showCommandOrInbox];
}

- (void)didStopTransmitting
{
	isTransmitting = NO;
	
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
	[self cancelVideoStreamingNotification];
#endif
    
	if (isAlerting)
	{
        [self stopAlert];
	}
    
	[transmitViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{ [self doneTransmitting]; }];
}

- (void)startWatchSession
{
    if (watchCount++ == 0)
	{
		isWatching = YES;
		[self setStatus:CS_Watching];
		
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
		[self logReachability:@"watch"];
#ifndef RV_LIMITS_STREAMING_DEBUG
		if ([networkReachability currentReachabilityStatus] == ReachableViaWWAN)
#endif
		{
			[self scheduleVideoStreamingNotification];
		}
#endif
	}
}

- (void)stopWatchSession
{
	NSAssert(watchCount>0,@"stopWatchSession called more than startWatchSession");
	
	if (--watchCount == 0)
	{

#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
		[self cancelVideoStreamingNotification];
#endif
		
		isWatching = NO;
		[self setStatus:CS_Connected];
	}
}

- (void)placePhoneCall:(NSString *)phoneNumber fromUser:(NSString *)user
{
	if ([DeviceCapabilities supportsPhone])
	{
		NSString * url = [NSString stringWithFormat:@"tel://%@", phoneNumber];
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	}
	else
	{
		NSString * msg = NSLocalizedString(@"%@ has requested you call %@",@"Request phone call alert message format");
		
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController resetPttTalkButton];
		
		UIAlertView * alert = 
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Request Phone Call",@"Request phone call alert title") 
										message:[NSString stringWithFormat:msg, user, phoneNumber] 
									   delegate:nil 
							  cancelButtonTitle:NSLocalizedString(@"OK",@"OK") 
							  otherButtonTitles:nil];
		[alert show];
	}
}

- (void)shareVideo:(CameraInfoWrapper *)camera 
          fromTime:(NSDate *)fromTime 
    withRecipients:(NSArray *)recipients 
           message:(NSString *)message
{
    // @todo we really should be putting these on an operation queue here 
    NSURL * commandServiceUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
    CommandService * commandService = [[CommandService alloc] initWithUrl:commandServiceUrl andDelegate:nil];
    
    if (camera.isTransmitter)
    {
        TransmitterInfo * transmitter = (TransmitterInfo *)camera.sourceObject;
        
        if (fromTime == nil)
        {
            [commandService postViewUserFeed:transmitter.deviceId  
                                 withMessage:message 
                                          to:recipients];
        }
        else
        {
            [commandService postViewArchiveForDevice:transmitter.deviceId 
                                               since:fromTime 
                                             caption:camera.cameraInfo.caption 
                                         withMessage:message 
                                                  to:recipients];
        }
    }
    else if (camera.isArchivedSession)
    {
        Session * session = (Session *)camera.sourceObject;
        
        if (fromTime == nil)
        {
            fromTime = session.startTime;
        }
        
        if (session.stopTime != nil)
        {
            [commandService postViewArchiveForDevice:session.deviceId 
                                               since:fromTime 
                                             caption:camera.cameraInfo.caption 
                                         withMessage:message 
                                                  to:recipients];
        }
        else
        {
            [commandService postViewArchiveForDevice:session.deviceId 
                                    betweenStartTime:fromTime 
                                         andStopTime:session.stopTime
                                             caption:camera.cameraInfo.caption 
                                         withMessage:message 
                                                  to:recipients];
        }
    }
    else if (camera.isScreencast)
    {
        // @todo how to handle "shareFromTime" for screencasts?
        NSString * screencastName = [camera.sourceUrl lastPathComponent];
        [commandService postViewScreencast:screencastName 
                                   caption:camera.cameraInfo.caption 
                               withMessage:message 
                                        to:recipients];
    }
    else
    {
        // @todo handle favorites?
        [commandService postViewCameraInfo:camera.cameraInfo 
                               withMessage:message 
                                        to:recipients];
    }
}

- (void)shareCurrentTransmitSessionFromBeginning:(BOOL)fromBeginning 
                                  withRecipients:(NSArray *)recipients 
                                         message:(NSString *)message
{
    // @todo we really should be putting these on an operation queue here 
    NSURL * commandServiceUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
    CommandService * commandService = [[CommandService alloc] initWithUrl:commandServiceUrl andDelegate:nil];
    
    if (fromBeginning)
    {
        [commandService postViewUserFeedFromBeginning:self.deviceId withMessage:message to:recipients];
    }
    else
    {
        [commandService postViewUserFeed:self.deviceId withMessage:message to:recipients];
    }
}


#pragma mark - Sign on/off

- (void)signOn
{
	NSAssert(!isSignedOn,@"Already signed on");
	
	if (networkReachability && self.networkStatus == NotReachable)
		return;
	
	if (isVerifyingSignOn)
		return;
	
	ConnectionProfile * profile = [ConnectionDatabase activeProfile];
	searchText = nil;
	
	if (profile == nil)
	{
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController showNoConfigurationsAlert];
	}
	else
	{
		DDLogInfo(@"Signing on %@", profile.host);
		// connect and get the configuration
		self.isConnecting = YES;
		connectionProfile = profile;
		[self signOnToUrl:[profile.url URLByAppendingPathComponent:@"Rest"]];
	}
}

- (void)doSignOff
{
	DDLogInfo(@"Signing off %@", connectionProfile.host);
	
	searchText = nil;
    
    // disable sign on until sign off process is complete
    RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
    rootViewController.signOnOffEnabled = NO;
    
	[self setIsSignedOn:NO];
	
	if (isTransmitting)
	{
		[self stopTransmitSessionAndGetComments:NO];
	}
    
    // check for isAlerting must happen AFTER checking isTransmitting.
    // on a device with a camera, stopping transmit also stops alert;
    // but with no camera, alert must be turned off separately
    if (isAlerting)
    {
        [self stopAlert];
    }
	
	if (isLocationAware)
	{
		[self stopMonitoringLocation];
        hasHadLocationLock = NO;
	}
    
	[self stopCnsTimer];
    [rootViewController showRootView];
}

- (void)signOff
{
	if (networkReachability && self.networkStatus == NotReachable)
		return;
	
	[self doSignOff];
	Configuration * configurationService = [[Configuration alloc] initWithConfigurationUrl:configurationUrl
																				  delegate:self];
	[configurationService disconnect:self.deviceId];
}

- (void)signOffForced
{
    if (isSignedOn || isVerifyingSignOn)
    {
		isVerifyingSignOn = NO;
        [self doSignOff];
        [self onDisconnect];
		
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController resetPttTalkButton];
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:[RealityVisionAppDelegate appName]
														 message:NSLocalizedString(@"You have been signed off by the system. Would you like to sign on again?",@"You have been signed off by the system. Would you like to sign on again?")
														delegate:self
											   cancelButtonTitle:NSLocalizedString(@"No",@"No")
											   otherButtonTitles:NSLocalizedString(@"Yes",@"Yes"), nil];
        alert.tag = SIGN_ON_ALERT_TAG;
        [alert show];
    }
}

- (void)defaultsChanged:(NSNotification *)notif
{
	if (isSignedOn && (! [connectionProfile isEqual:[ConnectionDatabase activeProfile]]))
	{
		// user preferences changed while we were signed on, so sign off
		DDLogInfo(@"RealityVisionClient defaultsChanged");
		[self signOff];
	}
}

- (NSString *)deviceId
{
	NSString * deviceId = [ConfigurationManager instance].deviceId;
	return deviceId ? deviceId : @"null";
}

- (NSString *)userId
{
	return isSignedOn ? self.lastSignedOnUser : @"anonymous";
}


#pragma mark - Remote Notification Token

- (NSString *)createStringFromToken:(NSData *)token
{
	NSMutableString * tokenString = nil;
	
	if (token != nil)
	{
		tokenString = [NSMutableString stringWithCapacity:[token length]*2];
		
		const uint8_t * byte = [token bytes];
		const uint8_t * endOfToken = byte + [token length];
		while (byte < endOfToken)
		{
			[tokenString appendFormat:@"%.2x", *byte];
			byte++;
		}
	}
	
	return tokenString;
}

- (void)postPushNotificationToken
{
	NSAssert(self.isSignedOn,@"Must be signed on to post capabilities");
	NSAssert(hasNewApnToken,@"APN token already posted to server");
	
	hasNewApnToken = NO;
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	[clientTransaction postCapabilities:[deviceCapabilities pushNotificationValues] forDevice:self.deviceId];
}

- (void)didReceiveRemoteNotificationToken:(NSData *)token
{
	DDLogInfo(@"Remote notification token: %@", [token description]);
	
	NSString * newToken = [self createStringFromToken:token];
	[deviceCapabilities setValue:newToken forKey:KEY_PUSH_TOKEN];
	
	if (! [newToken isEqualToString:apnToken])
	{
		// update token and send to server
		apnToken = newToken;
		hasNewApnToken = YES;
		
		if (isSignedOn)
		{
			[self postPushNotificationToken];
		}
	}
}


#pragma mark - Device status methods

- (void)setStatus:(ClientStatusEnum)status
{
    if (isSignedOn)
    {
        NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
        ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
        [clientTransaction postStatus:[ClientStatus clientStatusWithValue:status] forDevice:self.deviceId];
    }
}

- (void)updateStatus
{
	if (isAlerting)
	{
		[self setStatus:CS_Panic];
	}
	else if (isWatching)
	{
		[self setStatus:CS_Watching];
	}
	else
	{
		[self setStatus:CS_Connected];
	}
}


#pragma mark - Connection status (CNS) methods

- (void)updateConnectionTime
{
	if (! isSignedOn)
	{
		DDLogWarn(@"RealityVisionClient updateConnectionTime called while signed off");
		return;
	}
	
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	[clientTransaction updateConnectionTimeForDevice:self.deviceId];	
}

- (void)startCnsTimer
{
	// timer must be created and removed on the same thread so we'll do it to the main thread
	dispatch_async(dispatch_get_main_queue(), 
	               ^{
					   DDLogVerbose(@"RealityVisionClient startCnsTimer");
					   int refreshPeriod = [ConfigurationManager instance].clientConfiguration.clientConnectionActiveRate;
					   [cnsTimer invalidate];
					   cnsTimer = [NSTimer scheduledTimerWithTimeInterval:refreshPeriod
																		target:self 
																	  selector:@selector(updateConnectionTime) 
																	  userInfo:nil 
																	   repeats:YES];
				   });
}

- (void)stopCnsTimer
{
	// timer must be created and removed on the same thread so we'll do it to the main thread
	dispatch_async(dispatch_get_main_queue(), 
	               ^{
					   DDLogVerbose(@"RealityVisionClient stopCnsTimer");
					   [cnsTimer invalidate];
					   cnsTimer = nil;
				   });
}


#pragma mark - Command methods

#ifdef RV_ACKNOWLEDGE_NEW_HISTORY_COUNT
- (void)postReceivedNewHistoryCount
{
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	[clientTransaction receivedNewHistoryCount];	
}
#endif

- (void)decrementPendingCommandCount
{
	int count = self.inboxCommandCount;
	if (count == 0)
	{
		DDLogWarn(@"Inbox count is about to be decremented below 0");
		return;
	}
	
	[self setInboxCommandCount:(count-1)];
	DDLogVerbose(@"Decremented inbox count: %d", self.inboxCommandCount);
}

- (void)updateUnreadCommandCount
{
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	clientTransaction.delegate = self;
	[clientTransaction getUnreadCommandCount];
}

- (void)onGetUnreadCommandCountResult:(NSNumber *)count error:(NSError *)error
{
	if ((error == nil) && (count != nil))
	{
		[self setInboxCommandCount:[count integerValue]];
		DDLogInfo(@"Got new command count: %d", self.inboxCommandCount);
	}
    
    if (isVerifyingSignOn)
    {
		self.isConnecting = NO;
		
		if (error == nil)
		{
			[self didVerifySignOn];
		}
		
        isVerifyingSignOn = NO;
    }
}

- (void)getCommandAndExecute
{
	NSAssert(commandToExecute!=nil,@"Command ID not set");
	
	if (isSignedOn)
	{
		// calls onGetCommandResult to execute the command after retrieving it
		NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
		clientTransaction.delegate = self;
		[clientTransaction getCommandById:commandToExecute];
	}
	else 
	{
		// sign on and then get command
		[self signOn];
	}
}

- (void)onGetCommandResult:(Command *)command error:(NSError *)error
{
	commandToExecute = nil;
	
	if (error != nil)
	{
        // only show alert if client wasn't forced off
        if (isSignedOn)
        {
			RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
			[rootViewController resetPttTalkButton];
			
            UIAlertView * alert =
				[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could Not Get Command",@"Could not get command alert") 
										   message:[error localizedDescription]
									      delegate:nil
							     cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
							     otherButtonTitles:nil];
            [alert show];
        }
		return;
	}
	
	CommandWrapper * cmd = [[CommandWrapper alloc] initWithCommand:command];
	[cmd view];
}

- (void)showCommandOrInbox
{
    executeCommandOnStartup = NO;
    
	if (commandToExecute != nil)
	{
		[self getCommandAndExecute];
	}
	else if (showCommandInbox)
	{
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController showCommandInbox];
		showCommandInbox = NO;
	}
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == VIEW_COMMAND_ALERT_TAG)
    {
        commandNotificationAlert = nil;
    }
    
	if (buttonIndex != 0)
	{
		// stop transmitting before performing user action
		if (isTransmitting)
		{
			// note that this doesn't turn off the isTransmitting flag until user has finished entering comments
			[self stopTransmitSessionAndGetComments:YES];
		}
		
		switch (alertView.tag) 
		{
			case VIEW_COMMAND_ALERT_TAG:
				// if transmitting, defer executing command until transmit complete
				if (! isTransmitting)
				{
					// notify observers that a new command notification is about to be displayed ...
					// they should dismiss modals (except transmit) and any existing command notifications
					[[NSNotificationCenter defaultCenter] postNotificationName:RvWillDisplayCommandNotification object:self];
					[self showCommandOrInbox];
				}
				break;
				
			case SIGN_ON_ALERT_TAG:
				[self signOn];
				break;
				
			case SIGN_OFF_ALERT_TAG:
				[self signOff];
				break;
				
			default:
				DDLogError(@"RealityVisionClient unknown alert tag: %d", alertView.tag);
				break;
		}
	}
	else if (alertView.tag == VIEW_COMMAND_ALERT_TAG)
	{
		// if user cancelled the option to view a command, clear the commandToExecute
		commandToExecute = nil;
	}
	else if (alertView.tag == CANT_CONNECT_ALERT_TAG)
	{
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController showAddConnectionView];
	}
}


#pragma mark - CLLocationManagerDelegate methods

static CLLocationAccuracy accuracyInMeters[] = 
{
	3000.0,   // kRVLocationAccuracyLow
	 100.0,   // kRVLocationAccuracyMedium
	  16.0    // kRVLocationAccuracyHigh
};


// iOS 6>
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	DDLogVerbose(@"%s: %@", __FUNCTION__, locations);
	
	[self locationManager:manager didUpdateToLocation:[locations objectAtIndex:[locations count]-1] fromLocation:nil];
}

// iOS <6 (deprecrated in iOS 6)
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	const CLLocationAccuracy LocationAccuracyEpsilon = 1.0;
	const NSTimeInterval     MaxLocationAgeInSeconds = 24 * 60 * 60;
	
	BOOL oldLocationLock   = hasLocationLock;
	BOOL newLocationLock   = [self isLocationLocked:newLocation];
	BOOL lockStatusChanged = (oldLocationLock != newLocationLock);
	
	NSTimeInterval locationAgeInSeconds        = abs([newLocation.timestamp timeIntervalSinceNow]);
	NSTimeInterval minSecondsPerLocationReport = [ConfigurationManager instance].clientConfiguration.maximumGpsTransmissionRate;
	NSTimeInterval secondsSinceLastReport      = abs([newLocation.timestamp timeIntervalSinceDate:lastLocationUpdate]);
	CLLocationAccuracy lastLocationAccuracy    = (lastReportedLocation != nil) ? lastReportedLocation.horizontalAccuracy : 0.0;
	
	//
	// report new location only if: 
	//   * GPS lock state changes OR 
	//   * (distance exceeds GPS threshold distance AND 
	//      location is within desired accuracy AND
	//      location is not stale AND
	//      (at least min seconds per report have passed since last update OR
	//       location is more accurate than the previous report))
	// 
	// GPS threshold distance filtering is handled by CLLocationManager
	//
    if ((lockStatusChanged) ||
		((newLocationLock) &&
		 (locationAgeInSeconds <= MaxLocationAgeInSeconds) && 
		 ((secondsSinceLastReport >= minSecondsPerLocationReport) || 
		  (newLocation.horizontalAccuracy < lastLocationAccuracy - LocationAccuracyEpsilon))))
    {
		DDLogVerbose(@"RealityVisionClient locationManager didUpdateToLocation:(%+.6f, %+.6f) accuracy(meters)=%.2f",
					 newLocation.coordinate.latitude,
					 newLocation.coordinate.longitude,
					 newLocation.horizontalAccuracy);
		
		lastLocationUpdate = [NSDate date];
		lastReportedLocation = newLocation;
		[self setHasLocationLock:newLocationLock];
		[self postLocationStatus];
    }
	else 
	{
        DDLogVerbose(@"RealityVisionClient locationManager ignoring didUpdateToLocation:(%+.6f, %+.6f) accuracy(meters)=%.2f",
					 newLocation.coordinate.latitude,
					 newLocation.coordinate.longitude,
					 newLocation.horizontalAccuracy);
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	if (! [[error domain] isEqualToString:kCLErrorDomain])
	{
		// shouldn't be getting non-CoreLocation errors here but just to be safe ...
		DDLogWarn(@"RealityVisionClient locationManager didFailWithError: %@", [error localizedDescription]);
		return;
	}
	
	switch ([error code])
	{
		case kCLErrorLocationUnknown:
			// if unable to obtain location, report lost location lock
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: The location manager was unable to obtain a location value right now.");
			hasLocationLock = NO;
			[self postLocationStatus];
			break;
		
		case kCLErrorDenied:
			// if user denied access to location services, turn off location awareness
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: Access to the location service was denied by the user.");
			self.isLocationAware = NO;
			break;

		case kCLErrorNetwork:
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: The network was unavailable or a network error occurred.");
			break;
			
		case kCLErrorHeadingFailure:
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: The heading could not be determined.");
			break;
			
		case kCLErrorRegionMonitoringDenied:
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: Access to the region monitoring service was denied by the user.");
			break;
			
		case kCLErrorRegionMonitoringFailure:
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: A registered region cannot be monitored.");
			break;
			
		case kCLErrorRegionMonitoringSetupDelayed:
			DDLogWarn(@"RealityVisionClient locationManager didFailWithError: Core Location could not initialize the region monitoring feature immediately.");
			break;
			
		default:
			DDLogWarn(@"LocationManager failed with unknown error: %@", [error localizedDescription]);
	}
}

- (BOOL)locationOn
{
    return isSignedOn && isLocationAware;
}

- (GpsLockStatusEnum)locationLock
{
	BOOL gpsOn = isLocationAware || isAlerting;
	
	GpsLockStatusEnum lockStatusValue = (! gpsOn)            ? GL_NoLock :
                                        (hasLocationLock)    ? GL_Lock :
                                        (hasHadLocationLock) ? GL_LostLock : GL_NoLock;
    
    return lockStatusValue;
}

- (void)postLocationStatus
{
	if (! isSignedOn)
	{
		DDLogWarn(@"RealityVisionClient postLocationStatus called while signed off");
		return;
	}
	
	BOOL gpsOn = isLocationAware || isAlerting;
	
	GpsLockStatus * lockStatus = [[GpsLockStatus alloc] initWithValue:[self locationLock]];
	NSString      * gpgga      = lastReportedLocation ? [NSString gpggaStringWithLocation:lastReportedLocation] : @"";
	
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	[clientTransaction postGpsOn:gpsOn lockStatus:lockStatus nmea:gpgga forDevice:self.deviceId];
}


#pragma mark - LocationMonitor methods

- (void)startMonitoringLocation
{
	NSAssert(isSignedOn,@"Client must be signed on to monitor location");
	
	DDLogInfo(@"RealityVisionClient turning on GPS Location updates; accuracy=%f", locationManager.desiredAccuracy);
	locationManager.distanceFilter = [ConfigurationManager instance].clientConfiguration.gpsThresholdDistance;
	[locationManager startUpdatingLocation];
	
	// also use significant location updates to allow us to restart location monitoring at startup or after crash
	[locationManager startMonitoringSignificantLocationChanges];
	[self postLocationStatus];
}

- (void)stopMonitoringLocationAndPostStatus
{
    [self stopMonitoringLocation];
	
	if (isSignedOn)
	{
		[self postLocationStatus];
	}
}

- (void)stopMonitoringLocation
{
    DDLogInfo(@"RealityVisionClient turning off GPS Location updates");
	[locationManager stopUpdatingLocation];
	[locationManager stopMonitoringSignificantLocationChanges];
	[self setHasLocationLock:NO];
}

- (void)startMonitoringLocationForAlert
{
	NSAssert(isAlerting,@"startMonitoringLocationForAlert requires isAlerting to be YES");
	
	oldIsLocationAware = self.isLocationAware;
	[self setLocationManagerAccuracy:kRVLocationAccuracyHigh];
	self.isLocationAware = YES;
}

- (void)restoreMonitoringLocationAfterAlert
{
	NSAssert(!isAlerting,@"restoreMonitoringLocationAfterAlert requires isAlerting to be NO");
	
	[self setLocationManagerAccuracy:self.locationAccuracy];
	self.isLocationAware = oldIsLocationAware;
}

- (void)setLocationManagerAccuracy:(RVLocationAccuracy)accuracy
{
	locationManager.desiredAccuracy = (accuracy == kRVLocationAccuracyHigh)   ? kCLLocationAccuracyBest : 
	                                  (accuracy == kRVLocationAccuracyMedium) ? kCLLocationAccuracyHundredMeters 
																			  : kCLLocationAccuracyThreeKilometers;
}


#pragma mark - Network reachability monitoring methods

//- (NetworkStatus)networkStatus
//{
//	return (networkReachability) ? [networkReachability currentReachabilityStatus] : ReachabilityUnknown;
//}

- (void)startMonitoringNetworkStatus
{
    if (networkReachability == nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkReachabilityChanged:)
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        
		NSString * host = [[ConnectionDatabase activeProfile].url host];
        DDLogInfo(@"RealityVisionClient startMonitoringNetworkStatus for host %@", host);
        networkReachability = [Reachability reachabilityWithHostName:host];
        [networkReachability startNotifier];
    }
}

#if 0  // for now, never stop monitoring network status
- (void)stopMonitoringNetworkStatus
{
    if (networkReachability != nil)
    {
        DDLogInfo(@"RealityVisionClient stopMonitoringNetworkStatus");
        [networkReachability stopNotifier];
        networkReachability = nil;
		networkStatus = ReachabilityUnknown;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    }
}
#endif

- (void)logReachability:(NSString *)caller
{
	NSString * statusString = (networkStatus == NotReachable)     ? @"Not Reachable" :
	                          (networkStatus == ReachableViaWiFi) ? @"WiFi"
	                                                              : @"WWAN";
	DDLogInfo(@"Network status for %@ is %@", caller, statusString);
}

- (void)networkReachabilityChanged:(NSNotification *)notification
{
	NSParameterAssert([[notification object] isKindOfClass:[Reachability class]]);
	self.networkStatus = [networkReachability currentReachabilityStatus];
	[self logReachability:@"RealityVisionClient"];
	
#ifdef RV_LIMITS_STREAMING_OVER_CELLULAR
#ifndef RV_LIMITS_STREAMING_DEBUG
	if (isTransmitting || isWatching)
	{
		if (([networkReachability currentReachabilityStatus] == ReachableViaWWAN) &&
			(streamingOverCellularNotification == nil))
		{
			// lost WiFi connection
			[self scheduleVideoStreamingNotification];
		}
		else if (([networkReachability currentReachabilityStatus] == ReachableViaWiFi) &&
				 (streamingOverCellularNotification != nil))
		{
			// gained WiFi connection
			[self cancelVideoStreamingNotification];
		}
	}
#endif
#endif
	
	if ((networkStatus != NotReachable) && (isVerifyingSignOn) && (! self.isConnecting))
	{
		DDLogInfo(@"Network is reachable, verifying sign on");
		self.isConnecting = YES;
		[self updateUnreadCommandCount];
	}
	else if (self.isConnecting && networkStatus == NotReachable)
	{
		DDLogVerbose(@"Network is not reachable ... cancelling connect attempt");
		self.isConnecting = NO;
	}
}


#pragma  mark - Video streaming timeout methods

- (void)videoStreamingOverCellularTimedOut:(NSTimer *)theTimer
{
	DDLogInfo(@"RealityVisionClient videoStreamingOverCellularTimedOut");
	
	// notify observers to stop streaming video
	[[NSNotificationCenter defaultCenter] postNotificationName:RvStopVideoStreamingNotification object:nil];
}

- (void)scheduleVideoStreamingNotification 
{
	NSAssert(streamingOverCellularNotification==nil,@"Video streaming over cellular notification already exists");
	DDLogInfo(@"RealityVisionClient scheduleVideoStreamingNotification");
	
#ifdef RV_LIMITS_STREAMING_DEBUG
	const NSTimeInterval maxCellularStreamingSeconds = 1.0 * 60.0;
#else
	const NSTimeInterval maxCellularStreamingSeconds = 10.0 * 60.0;
#endif
	
	streamingOverCellularNotification = [NSTimer scheduledTimerWithTimeInterval:maxCellularStreamingSeconds 
																			  target:self 
																			selector:@selector(videoStreamingOverCellularTimedOut:) 
																			userInfo:nil 
																			 repeats:NO];
}

- (void)cancelVideoStreamingNotification
{
	if (streamingOverCellularNotification != nil)
	{
		DDLogInfo(@"RealityVisionClient cancelVideoStreamingNotification");
		[streamingOverCellularNotification invalidate];
		streamingOverCellularNotification = nil;
	}
}


#pragma mark - ConnectDelegate methods

- (void)signOnToUrl:(NSURL *)configUrl
{
	configurationUrl = configUrl;
	SecurityConfig * configurationService = [[SecurityConfig alloc] initWithSecurityConfigUrl:configurationUrl 
																					  delegate:self];
	[configurationService getRequireSslForCredentials];
}

- (void)onGotRequireSslForCredentials:(BOOL)requireSslForCredentials error:(NSError *)error
{
	if (error != nil)
	{
        if (error.domain == RV_DOMAIN && error.code == RV_USER_CANCEL)
        {
            DDLogInfo(@"RealityVisionClient onGotRequireSslForCredentials: user cancelled");
        }
        else
        {
            DDLogError(@"RealityVisionClient onGotRequireSslForCredentials received error: %@", error);
            
            UIAlertView * alert = 
                [[UIAlertView alloc] initWithTitle:ERROR_CANT_CONNECT_TITLE
										   message:ERROR_CANT_CONNECT_MSG
										  delegate:self 
								 cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
								 otherButtonTitles:nil];
            alert.tag = CANT_CONNECT_ALERT_TAG;
            [alert show];
        }
		
		self.isConnecting = NO;
	}
	else
    {
        [ConfigurationManager instance].requireSslForCredentials = requireSslForCredentials;
        [self connectToUrl];
    }
}

- (void)connectToUrl
{
	DDLogInfo(@"RealityVisionClient connectToUrl");
	hasNewApnToken = NO;
	Configuration * configurationService = [[Configuration alloc] initWithConfigurationUrl:configurationUrl 
																				   delegate:self];
	[configurationService connect:self.deviceId capabilities:deviceCapabilities.values];
}

- (void)onConnect:(ClientServiceInfo *)clientInfo error:(NSError *)error
{
	self.isConnecting = NO;
	
	if (error != nil)
	{
		if (! ([[error domain] isEqualToString:RV_DOMAIN]) && ([error code] == RV_USER_CANCEL))
		{
			DDLogError(@"RealityVisionClient onConnect received error: %@", error);
			
			UIAlertView * alert = 
				[[UIAlertView alloc] initWithTitle:ERROR_CANT_CONNECT_TITLE 
										   message:ERROR_CANT_CONNECT_MSG 
										  delegate:self 
								 cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
								 otherButtonTitles:nil];
			alert.tag = CANT_CONNECT_ALERT_TAG;
			[alert show];
		}
	}
	else if (clientInfo == nil)
	{
		DDLogError(@"RealityVisionClient onConnect did not receive ClientServiceInfo");
		
		NSString * msg = NSLocalizedString(@"Did not receive expected response from server.",
										   @"Did not receive response error text");
		
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:ERROR_CANT_CONNECT_TITLE 
														  message:msg
													     delegate:nil 
											    cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
											    otherButtonTitles:nil];
		[alert show];
	}
	else
	{
		//[clientInfo log];  // debug logging
		[clientInfo augmentExternalUrisHostWith:connectionProfile.host];
		NSDictionary * configUris = connectionProfile.isExternal ? clientInfo.externalSystemUris
		                                                         : clientInfo.systemUris;
		
		SystemUris * systemUris = [[SystemUris alloc] initFromUriDictionary:configUris];
		
		// compare the configuration service urls, if they are different get the configuration 
		// from the configuration server listed in the response
		NSString * configUrlString    = [configurationUrl absoluteString];
		NSString * newConfigUrlString = [systemUris.configurationRest absoluteString];
		
		if ((newConfigUrlString != nil) &&
			([configUrlString caseInsensitiveCompare:newConfigUrlString] != NSOrderedSame))
		{
			DDLogInfo(@"%@ -> %@", configUrlString, newConfigUrlString);
			[self signOnToUrl:[NSURL URLWithString:newConfigUrlString]];
		}
		else 
		{
			[self connectedWithClientInfo:clientInfo andSystemUris:systemUris];
		}
		
	}
}

- (void)connectedWithClientInfo:(ClientServiceInfo *)clientInfo andSystemUris:(SystemUris *)systemUris
{
	DDLogInfo(@"RealityVisionClient connected");
	
	ClientConfiguration * clientConfig = [[ClientConfiguration alloc] initFromDictionary:clientInfo.clientConfiguration];
	
	[ConfigurationManager updateClientConfiguration:clientConfig 
											   uris:systemUris 
										   deviceId:clientInfo.deviceId];
	
	[self setIsSignedOn:YES];
	
	// update last signed on user, if changed
	NSString * user = [[ConfigurationManager instance].credential user];
	if ([user caseInsensitiveCompare:lastSignedOnUser] != NSOrderedSame)
	{
		lastSignedOnUser = [[NSString alloc] initWithString:user];
	}
	
	// turn on location monitoring if user wants
	if (isLocationAware)
	{
		[self startMonitoringLocation];
	}
	
	// start cns timer
	[self startCnsTimer];
	
	// update badge to display pending command count
	DDLogInfo(@"pending command count: %ld", clientInfo.newHistoryCount);
	[self setInboxCommandCount:clientInfo.newHistoryCount];
	
	// if we launched due to a remote notification, retrieve the command
	if (commandToExecute != nil)
	{
		[self getCommandAndExecute];
	}
	else if (clientInfo.newHistoryCount)
	{
		RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
		[rootViewController showNewCommandsAlert];
	}
	
	// get list of ptt channels
	[[PttChannelManager instance] updateChannelList];
	
	// save current state
	[self serialize];
}

- (void)onDisconnect
{
	if (! [ConfigurationManager instance].clientConfiguration.clientCanStoreUserid)
	{
		lastSignedOnUser = nil;
	}
	
	[ConfigurationManager invalidate];
	connectionProfile = nil;
	configurationUrl = nil;
	
	[[PttChannelManager instance] invalidate];
	
	// save current state
	[self serialize];
    
    RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
    rootViewController.signOnOffEnabled = YES;
}


#pragma mark - Helper methods

- (BOOL)isLocationLocked:(CLLocation *)location
{
	return ((location != nil) && 
			(location.horizontalAccuracy >= 0.0) && 
			(location.horizontalAccuracy <= accuracyInMeters[self.locationAccuracy]));
}

- (void)alertUserOfCommandWithMessage:(NSString *)message
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    
    if (commandNotificationAlert != nil)
    {
        [commandNotificationAlert dismissWithClickedButtonIndex:0 animated:YES];
    }
	
	RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
	[rootViewController resetPttTalkButton];
    
    commandNotificationAlert = [[UIAlertView alloc] initWithTitle:[RealityVisionAppDelegate appName]
														  message:message
														 delegate:self 
												cancelButtonTitle:NSLocalizedString(@"Close",@"Close")
												otherButtonTitles:NSLocalizedString(@"View",@"View"),nil];
    commandNotificationAlert.tag = VIEW_COMMAND_ALERT_TAG;
    [commandNotificationAlert show];
}

- (void)handleCommandNotificationWithMessage:(NSString *)message 
                              unreadCommands:(NSInteger)unreadCommands 
                                userNotified:(BOOL)userNotified
{
    [self setInboxCommandCount:unreadCommands];
	
	// if the user was not notified by iOS (i.e., app is in the foreground), notify them now
	if (! userNotified)
	{
        // "wait_fences: failed to receive reply: 10004003"
		[self performSelectorOnMainThread:@selector(alertUserOfCommandWithMessage:) withObject:message waitUntilDone:NO];
	}
}

+ (NSString *)getPrefsFilename
{
	return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"RealityVision.prefs"];
}

@end
