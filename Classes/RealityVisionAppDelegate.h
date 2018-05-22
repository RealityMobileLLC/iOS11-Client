//
//  RealityVisionAppDelegate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#define SYSTEM_VERSION_GRATERTHAN_OR_EQUALTO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

/**
 *  The UIApplicationDelegate for RealityVision.
 */
@interface RealityVisionAppDelegate : UIResponder <UIApplicationDelegate,UNUserNotificationCenterDelegate>

/**
 *  Gets the app name. Allows for rebranding.
 */
+ (NSString *)appName;

/**
 *  Gets the version number.
 */
+ (NSString *)versionString;

/**
 *  Gets the application's document directory.
 *
 *  @return The application's document directory or empty string on error.
 */
+ (NSString *)documentDirectory;

/**
 *  Gets a value from the application's info property list.
 */
+ (id)infoValueForKey:(NSString *)key;

/**
 *  Gets the application's root view controller.
 */
+ (UIViewController *)rootViewController;

/**
 *  Indicates that a network connection to the server is active.
 *
 *  This turns on the network activity indicator if it's not already on.
 */
+ (void)didStartNetworking;

/**
 *  Indicates that a network connection has stopped.
 *
 *  This turns off the network activity indicator if there are no more
 *  active network connections.
 */
+ (void)didStopNetworking;

/**
 *  Indicates the client device is not signed on and the user must reauthenticate.
 */
+ (void)forceSignOff;

/**
 *  Lets the user know that the goggles do nothing.
 */
+ (void)showNotImplementedAlert;


// Interface Builder outlets
@property (nonatomic,strong) IBOutlet UIWindow               * window;
@property (nonatomic,strong) IBOutlet UINavigationController * navigationController;
@property (nonatomic,strong) IBOutlet UIViewController       * rootViewController;

@end
