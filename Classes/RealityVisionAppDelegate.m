//
//  RealityVisionAppDelegate.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import "RealityVisionAppDelegate.h"
#import "MainMenuViewController.h"
#import "MainMapViewController.h"
#import "DownloadManager.h"
#import "RealityVisionClient.h"

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "RVLogFormatter.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@implementation RealityVisionAppDelegate
{
    // used to determine if a push notification was received while in UIApplicationStateBackground
    BOOL wasInBackground;
}

@synthesize window=_window;
@synthesize navigationController=_navigationController;
@synthesize rootViewController;


#pragma mark - Public methods

static int networkActivityCount;

+ (NSString *)appName
{
	return [self infoValueForKey:@"CFBundleDisplayName"];
}

+ (NSString *)versionString
{
	NSString * appVersion = [self infoValueForKey:@"RVAboutVersion"];
	if ([appVersion length] == 0)
	{
		NSString * shortVersionString = [self infoValueForKey:@"CFBundleShortVersionString"];
		NSString * bundleVersionString = [self infoValueForKey:@"CFBundleVersion"];
		appVersion = [NSString stringWithFormat:@"%@ (%@)", shortVersionString, bundleVersionString];
	}
	
	return appVersion;
}

+ (NSString *)documentDirectory
{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if (paths == nil)
	{
		DDLogError(@"Unable to get document directory paths");
		return @"";
	}
	
	NSString * documentDirectory = [paths objectAtIndex:0];
	if (documentDirectory == nil)
	{
		DDLogError(@"Unable to get document directory");
		return @"";
	}
	
	return documentDirectory;
}

+ (id)infoValueForKey:(NSString *)key
{
	id localizedValue = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    return (localizedValue != nil) ? localizedValue : [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}

+ (UIViewController *)rootViewController
{
	RealityVisionAppDelegate * instance = [UIApplication sharedApplication].delegate;
	return instance.rootViewController;
}

+ (void)didStartNetworking
{
    if (networkActivityCount++ == 0)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	}
}

+ (void)didStopNetworking
{
    NSAssert(networkActivityCount>0,@"didStopNetworking called more than didStartNetworking");
    if (--networkActivityCount == 0)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}

+ (void)forceSignOff
{
    [[RealityVisionClient instance] signOffForced];
}

+ (void)showNotImplementedAlert
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"The goggles they do nothing!"
													 message:@"This feature is not implemented."
													delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
	[alert show];
}


#pragma mark - Application lifecycle

/*
 *  Notifies the application that it has launched and, optionally, what caused
 *  it to launch.  This is the entry point for the RealityVision app.
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
	// initialize logging
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	RVLogFormatter * logFormatter = [[RVLogFormatter alloc] init];
	[[DDASLLogger sharedInstance] setLogFormatter:logFormatter];
	[[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
	
	[[DDTTYLogger sharedInstance] setColorsEnabled:YES];
	UIColor * green = [UIColor colorWithRed:0 green:0.5 blue:0.25 alpha:1];
	[[DDTTYLogger sharedInstance] setForegroundColor:green backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
	[[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
	
	DDLogInfo(@"RealityVisionAppDelegate applicationDidFinishLaunchingWithOptions");
    
    // cleanup previously downloaded files
    [DownloadManager deleteDownloadedFiles];

	// initialize member variables
    networkActivityCount = 0;
    wasInBackground = YES;

	// determine what caused us to launch
	if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey] != nil)
	{
		// we don't have to do anything with this notification because
		// RealityVisionClient will always start location services which
		// gives us the location update
		DDLogInfo(@"RealityVision launched with location update");
	}
	
	NSDictionary * remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (remoteNotification != nil)
	{
		DDLogInfo(@"RealityVision launched with remote notification");
		[self application:application didReceiveRemoteNotification:remoteNotification];
	}
	
	UILocalNotification * localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
	if (localNotification != nil)
	{
		DDLogInfo(@"RealityVision launched with local notification for action %@", localNotification.alertAction);
        [self application:application didReceiveLocalNotification:localNotification];
	}
    
	// create window and root view controller
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		rootViewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController" bundle:nil];
	else
		rootViewController = [[MainMapViewController alloc] initWithNibName:@"MainMapViewController" bundle:nil];
	
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	self.window.rootViewController = self.navigationController;
	[self.window makeKeyAndVisible];
	
	// register for user settings changes
	[[NSNotificationCenter defaultCenter] addObserver:[RealityVisionClient instance]
											 selector:@selector(defaultsChanged:)
												 name:NSUserDefaultsDidChangeNotification
											   object:nil];

	// register for push notifications and get token
//	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
//																		   UIRemoteNotificationTypeSound | 
//																		   UIRemoteNotificationTypeAlert)];	
//	

	
	if( SYSTEM_VERSION_LESS_THAN( @"10.0" ) ){
		[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound |    UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
		[[UIApplication sharedApplication] registerForRemoteNotifications];
		
		//if( option != nil )
		//{
		//    NSLog( @"registerForPushWithOptions:" );
		//}
	}else{
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
		center.delegate = self;
		[center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
		 {
			 if( !error ){
				 [[UIApplication sharedApplication] registerForRemoteNotifications];  // required to get the app to do anything at all about push notifications
				 NSLog( @"Push registration success." );
			 }else{
				 NSLog( @"Push registration FAILED" );
				 NSLog( @"ERROR: %@ - %@", error.localizedFailureReason, error.localizedDescription );
				 NSLog( @"SUGGESTIONS: %@ - %@", error.localizedRecoveryOptions, error.localizedRecoverySuggestion );
		}
   }];  
 }
	
	return YES;
}

/*
 *  Notifies the application that it is about to move from active to inactive
 *  state.  This can occur for certain types of temporary interruptions (such 
 *  as an incoming phone call or SMS message) or when the user quits the 
 *  application and it begins the transition to the background state.
 * 
 *  Use this method to pause ongoing tasks, disable timers, and throttle down 
 *  OpenGL ES frame rates.  Games should use this method to pause the game.
 */
- (void)applicationWillResignActive:(UIApplication *)application 
{
	DDLogInfo(@"RealityVisionAppDelegate applicationWillResignActive");
}

/*
 *  Notifies the application that it has moved from inactive to active state.
 *
 *  This method can be used to restart any tasks that were paused (or not yet 
 *  started) while the application was inactive.  If the application was 
 *  previously in the background, optionally refresh the user interface.
 */
- (void)applicationDidBecomeActive:(UIApplication *)application 
{
	DDLogInfo(@"RealityVisionAppDelegate applicationDidBecomeActive");
	[[RealityVisionClient instance] didBecomeActive];
    wasInBackground = NO;
}

/*
 *  Notifies the application that it is about to move from the background to 
 *  inactive state.
 */
- (void)applicationWillEnterForeground:(UIApplication *)application 
{
	DDLogInfo(@"RealityVisionAppDelegate applicationWillEnterForeground");
    wasInBackground = YES;
}

/*
 *  Notifies the application that it is about to enter the background. 
 *  
 *  Use this method to release shared resources, save user data, invalidate 
 *  timers, and store enough application state information to restore the 
 *  application to its current state in case it is terminated later.
 *  
 *  Since RealityVision supports background execution, this is called instead
 *  of applicationWillTerminate: when the user quits.
 */
- (void)applicationDidEnterBackground:(UIApplication *)application 
{
	DDLogInfo(@"RealityVisionAppDelegate applicationDidEnterBackground");
	[[RealityVisionClient instance] didEnterBackground];
}

/*
 *  Notifies the application that it is about to terminate.
 */
- (void)applicationWillTerminate:(UIApplication *)application 
{
	DDLogWarn(@"RealityVisionAppDelegate applicationWillTerminate");
}


#pragma mark - Local and remote notifications

/*
 *  Notifies the application that it has successfully registered for remote
 *  (push) notifications and provides the device token to use when sending a
 *  notification to this device.
 */
//- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)token 
//{
//    [[RealityVisionClient instance] didReceiveRemoteNotificationToken:token];
//}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	// custom stuff we do to register the device with our AWS middleman
	NSLog(@"My token is: %@", deviceToken);

	
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    willPresentNotification:(UNNotification *)notification
		 withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
	NSLog( @"Handle push from foreground" );
	// custom code to handle push while app is in the foreground
	NSLog(@"%@", notification.request.content.userInfo);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
		 withCompletionHandler:(void (^)())completionHandler
{
	NSLog( @"Handle push from background or closed" );
	// if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
	NSLog(@"%@", response.notification.request.content.userInfo);
}

/*
 *  Notifies the application that it failed to register for remote (push)
 *  notifications.  This is most likely because the user has declined to
 *  receive remote notifications for RealityVision.
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error 
{
    DDLogError(@"Failed to register for remote notifications: %@", error);
	
	// send empty token to indicate device should not receive remote notifications
	[[RealityVisionClient instance] didReceiveRemoteNotificationToken:nil];
}

/*
 *  Notifies the application that it has received a remote (push) notification.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
	DDLogInfo(@"RealityVisionAppDelegate didReceiveRemoteNotification");
	NSNumber * forceCommand = [notification objectForKey:@"cmd"];
    
	if (forceCommand)
	{
        // execute force command
        int directive = forceCommand.intValue;
        NSString * commandId = [notification objectForKey:@"id"];
        [[RealityVisionClient instance] didReceiveForceCommand:directive withId:commandId userNotified:wasInBackground];
	}
    else
    {
        NSDictionary * apsDictionary = [notification objectForKey:@"aps"];
        
        // message to display with alert
        NSString * message = [apsDictionary objectForKey:@"alert"];
        
        // unread commands (display on badge and menus)
        NSNumber * badge = [apsDictionary objectForKey:@"badge"];
        NSInteger numberOfUnreadCommands = badge.integerValue;
        
        // pending commands (number of missed or ignored notifications)
        NSNumber * count = [notification objectForKey:@"count"];
        NSInteger numberOfPendingCommands = count.integerValue;
        
        if (numberOfPendingCommands > 1)
        {
            // notify user they missed multiple commands
            [[RealityVisionClient instance] didReceiveCommandNotificationWithMessage:message 
                                                                     pendingCommands:numberOfPendingCommands 
                                                                      unreadCommands:numberOfUnreadCommands 
                                                                        userNotified:wasInBackground];
        }
        else
        {
            // notify user of single command
            NSString * commandId = [notification objectForKey:@"id"];
            [[RealityVisionClient instance] didReceiveCommandNotificationWithMessage:message 
                                                                           commandId:commandId 
                                                                      unreadCommands:numberOfUnreadCommands 
                                                                        userNotified:wasInBackground];
        }
    }
}

/*
 *  Notifies the application that is has received a local notification.
 *  RealityVision uses these for the scheduled sign on/off feature.
 */
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	DDLogInfo(@"RealityVisionAppDelegate didReceiveLocalNotification");
	[[RealityVisionClient instance] didReceiveLocalNotification:notification userNotified:wasInBackground];
}


#pragma mark - Memory management

/*
 *  Notifies the application that memory is running low.  Free up as much
 *  memory as possible by purging cached data objects that can be recreated
 *  (or reloaded from disk) later.
 */
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
	DDLogWarn(@"RealityVisionAppDelegate applicationDidReceiveMemoryWarning");
}

@end
