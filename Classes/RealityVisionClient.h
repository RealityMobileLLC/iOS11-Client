//
//  RealityVisionClient.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Reachability.h"
#import "ClientStatus.h"
#import "DirectiveType.h"
#import "GpsLockStatus.h"
#import "Configuration.h"
#import "ClientTransaction.h"
#import "CommandService.h"
#import "SecurityConfig.h"
#import "LocationStatusBarButtonItem.h"
#import "RVLocationAccuracyDelegate.h"
#import "TransmitViewController.h"

@class CameraInfoWrapper;
@class ConnectionProfile;
@class DeviceCapabilities;


/**
 *  Manages receiving commands and updating the client state and location on the 
 *  RealityVision server.
 */
@interface RealityVisionClient : NSObject < NSCoding, CLLocationManagerDelegate, UIAlertViewDelegate,
									        ConnectDelegate, RVLocationAccuracyDelegate,
                                            ClientTransactionDelegate, TransmitViewDelegate,
                                            SecurityConfigDelegate, 
                                            LocationStatusProvider >

/**
 *  The client's current Device ID.
 */
@property (strong,nonatomic,readonly) NSString * deviceId;

/**
 *  The User ID of the currently signed-on user, or "anonymous" if not signed-on.
 */
@property (strong,nonatomic,readonly) NSString * userId;

/**
 *  The User ID of the last signed-on user.
 */
@property (nonatomic,readonly) NSString * lastSignedOnUser;

/**
 *  Indicates whether the client is signing on or verifying sign on.
 */
@property (nonatomic,readonly) BOOL isConnecting;

/**
 *  Indicates whether the client is currently signed on.
 */
@property (nonatomic,readonly) BOOL isSignedOn;

/**
 *  Indicates whether the client is currently transmitting.
 */
@property (nonatomic,readonly) BOOL isTransmitting;

/**
 *  Indicates whether the client is in Alert mode.
 */
@property (nonatomic,readonly) BOOL isAlerting;

/**
 *  The client's actual current location from CLLocationManager.  This is not necessarily the 
 *  same as the last location reported to RealityVision.
 */
@property (strong,nonatomic,readonly) CLLocation * actualLocation;

/**
 *  The client's current location as a GPGGA string, if location is within the desired accuracy.
 *  Returns nil if location is not being tracked or if it is not within desired accuracy.
 */
@property (strong,nonatomic,readonly) NSString * transmitLocationAsGpgga;

/**
 *  Indicates whether the client is tracking location while signed on.
 *  
 *  Note that this property can be YES when the client is signed off, in which case it is not 
 *  currently tracking location.  Use the locationOn property to determine if the client is
 *  currently tracking location.
 */
@property (nonatomic) BOOL isLocationAware;

/**
 *  Indicates whether the client is currently tracking location.
 *  
 *  This returns YES iff both isSignedOn and isLocationAware are both YES.
 */
@property (nonatomic,readonly) BOOL locationOn;

/**
 *  The current location lock status.
 */
@property (nonatomic,readonly) GpsLockStatusEnum locationLock;

/**
 *  The desired accuracy to use when tracking location.
 */
@property (nonatomic) RVLocationAccuracy locationAccuracy;

/**
 *  Indicates whether the client has received a location with the desired accuracy.
 */
@property (nonatomic,readonly) BOOL hasLocationLock;

/**
 *  The number of unread commands in the user's inbox.
 */
@property (nonatomic) NSInteger inboxCommandCount;

/**
 *  Indicates the type of map to display.
 */
@property (nonatomic) MKMapType mapType;

/**
 *  The user's most recent search text.
 */
@property (nonatomic,copy) NSString * searchText;

/**
 *  The current network status.
 */
@property (nonatomic,readonly) NetworkStatus networkStatus;

/**
 *  Returns the singleton instance of the RealityVisionClient class.
 */
+ (RealityVisionClient *)instance;

/**
 *  Performs startup actions when application moves to the active state.
 */
- (void)didBecomeActive;

/**
 *  Performs cleanup actions when application moves to the background.
 */
- (void)didEnterBackground;

/**
 *  Saves the current state for restoring on restart.
 */
- (void)serialize;

/**
 *  Starts the sign on process and connects to the server.
 */
- (void)signOn;

/**
 *  Starts the sign off process and disconnects from the server.
 */
- (void)signOff;

/**
 *  Sets the client status to signed off due to a Force Sign Off command or a System Sign Off.
 *  Does not disconnect from the server because the client is already signed off.
 */
- (void)signOffForced;

/**
 *  Stores the device's APS token and sends it to the RealityVision server.
 *
 *  @param token The device's APS token.
 */
- (void)didReceiveRemoteNotificationToken:(NSData *)token;

/**
 *  Handles a force command received via push notification.
 *  
 *  @param directive    Command directive
 *  @param commandId    Unique command identifier
 *  @param userNotified YES if the user was notified by iOS (i.e. the app was in the background) 
 */
- (void)didReceiveForceCommand:(DirectiveTypeEnum)directive 
                        withId:(NSString *)commandId 
                  userNotified:(BOOL)userNotified;

/**
 *  Handles a command notification with multiple pending commands.
 *  
 *  @param message         Message to display to user
 *  @param pendingCommands Number of missed or ignored commands
 *  @param unreadCommands  Number of unread commands
 *  @param userNotified    YES if the user was notified by iOS (i.e. the app was in the background) 
 */
- (void)didReceiveCommandNotificationWithMessage:(NSString *)message 
                                 pendingCommands:(NSInteger)pendingCommands 
                                  unreadCommands:(NSInteger)unreadCommands 
                                    userNotified:(BOOL)userNotified;

/**
 *  Handles a command notification with a single commands
 *  
 *  @param message        Message to display to user
 *  @param commandId      Unique command identifier
 *  @param unreadCommands Number of unread commands
 *  @param userNotified   YES if the user was notified by iOS (i.e. the app was in the background) 
 */
- (void)didReceiveCommandNotificationWithMessage:(NSString *)message 
                                       commandId:(NSString *)commandId 
                                  unreadCommands:(NSInteger)unreadCommands 
                                    userNotified:(BOOL)userNotified;

/**
 *  Provides a local notification containing an action to perform.
 *
 *  @param localNotification The local notification.
 *  @param userNotified      YES if the user was notified by iOS (i.e. the app was in the background) 
 */
- (void)didReceiveLocalNotification:(UILocalNotification *)localNotification 
                       userNotified:(BOOL)userNotified;

/**
 *  Decrements the command inbox count after a command has been retrieved.
 */
- (void)decrementPendingCommandCount;

/**
 *  Switches location awareness on or off.
 */
- (void)toggleLocationAware;

/**
 *  Starts a transmit session.
 */
- (void)startTransmitSession;

/**
 *  Stops an in-progress transmit session.
 *  
 *  @param getComments YES if user should be prompted to enter a comment for the transmit session.
 */
- (void)stopTransmitSessionAndGetComments:(BOOL)getComments;

/**
 *  Indicates that client has started watching a video.  Note that unlike startTransmitSession,
 *  this does not start the watch itself.  It increments a reference count of the number of
 *  sessions that are being watched and sets the client status to watching if necessary.
 */
- (void)startWatchSession;

/**
 *  Indicates that client has stopped watching a video.  Note that unlike stopTransmitSession,
 *  this does not stop the watch itself.  It decrements a reference count of the number of
 *  sessions that are being watched and turns off the client watching status if necessary.
 */
- (void)stopWatchSession;

/**
 *  Enters alert mode.  If the device has a video camera, also starts transmitting.
 */
- (void)startAlert;

/**
 *  Exits alert mode.
 */
- (void)stopAlert;

/**
 *  Switches alert mode on or off.
 */
- (void)toggleAlertMode;

/**
 *  Places a phone call to the given number.
 *
 *  @param phoneNumber Phone number to call.
 *  @param user        User who requested phone call.
 */
- (void)placePhoneCall:(NSString *)phoneNumber fromUser:(NSString *)user;

/**
 *  Sends a View Camera command to one or more recipients along with an optional message.
 *  The exact command that gets sent depends on the type of video being shared.
 *
 *  @param camera     Video to share. Underlying video can be a transmitter (live user feed), 
 *                    session (archive user feed), screencast or fixed camera.
 *  @param fromTime   Start time for archive feed, or nil to share a live feed or a full archive 
 *                    session.
 *  @param recipients Array of Recipient objects to whom video will be sent.
 *  @param message    Optional message to send with command.
 */
- (void)shareVideo:(CameraInfoWrapper *)camera 
          fromTime:(NSDate *)fromTime 
    withRecipients:(NSArray *)recipients 
           message:(NSString *)message;

/**
 *  Sends a View User Feed command to one or more recipients along with an optional message.
 *  
 *  @param fromBeginning If YES, the archive of the current transmit session is shared from the beginning.
 *                       Otherwise, the live user feed is shared.
 *  @param recipients    Array of Recipient objects to whom video will be sent.
 *  @param message       Optional message to send with command.
 */
- (void)shareCurrentTransmitSessionFromBeginning:(BOOL)fromBeginning 
                                  withRecipients:(NSArray *)recipients 
                                         message:(NSString *)message;

@end
