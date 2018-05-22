//
//  CommandService.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"
#import "WebServiceResponseHandler.h"

@class CameraInfo;
@class QueryString;


/**
 *  Delegate used by the CommandService class to indicate when web services respond.
 */
@protocol CommandServiceDelegate

/**
 *  Called when a Post command call completes.
 *  
 *  Note that, unlike other WebServices, CommandService will prompt the user to retry if
 *  an error occurs.  Thus onPostCommandResult:error: is only called if the operation is
 *  successful, or if an error occurred but the user declined to retry it.
 *  
 *  @param guid  Unique identifier for posted command.
 *  @param error An error, if one occurred, or nil if the operation 
 *               completed successfully.
 */
- (void)onPostCommandResult:(NSString *)guid error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision Command Service web service requests.
 */
@interface CommandService : WebService <UIAlertViewDelegate>

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <CommandServiceDelegate> delegate;

/**
 *  Initializes a CommandService object.
 *
 *  @param url      The base URL for RealityVision web services.
 *  @param delegate The delegate to notify when a web service responds.
 *
 *  @return An initialized CommandService object or nil if the object
 *          could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url andDelegate:(id <CommandServiceDelegate>)delegate;

/**
 *  Initiates a Post View Camera request.
 *  
 *  @param viewUrl    URL of the video feed.
 *  @param caption    Caption to use when displaying the video.
 *  @param proxied    YES if the camera is being proxied by the RealityVision Server.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewCameraUrl:(NSString *)viewingUrl 
                  caption:(NSString *)caption 
                isProxied:(BOOL)proxied 
              withMessage:(NSString *)message 
                       to:(NSArray *)recipients;

/**
 *  Initiates a Post View Camera Info request.
 *  
 *  @param camera     CameraInfo object describing the video feed.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewCameraInfo:(CameraInfo *)camera 
               withMessage:(NSString *)message 
                        to:(NSArray *)recipients;

/**
 *  Initiates a Post View Screencast request.
 *  
 *  @param screencastName Name of the screencast.
 *  @param caption        Caption to use when displaying the video.
 *  @param message        A message to send with the command.
 *  @param recipients     An array of Recipient objects.
 */
- (void)postViewScreencast:(NSString *)screencastName 
                   caption:(NSString *)caption 
               withMessage:(NSString *)message 
                        to:(NSArray *)recipients;

/**
 *  Initiates a Post View User Feed request.
 *  
 *  @param deviceId   Device ID of the transmitting device.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewUserFeed:(NSString *)deviceId 
             withMessage:(NSString *)message
                      to:(NSArray *)recipients;

/**
 *  Initiates a Post View User Feed From Beginning request.
 *  
 *  @param deviceId   Device ID of the transmitting device.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewUserFeedFromBeginning:(NSString *)deviceId 
                          withMessage:(NSString *)message
                                   to:(NSArray *)recipients;

/**
 *  Initiates a Post View Device Archive Since request.
 *  
 *  @param deviceId   Device ID of the transmitting device.
 *  @param startTime  Start time of the archive feed in UTC.
 *  @param caption    Caption to use when displaying the video.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewArchiveForDevice:(NSString *)deviceId 
                           since:(NSDate *)startTime 
                         caption:(NSString *)caption 
                     withMessage:(NSString *)message 
                              to:(NSArray *)recipients;

/**
 *  Initiates a Post View Device Archive Between request.
 *  
 *  @param deviceId   Device ID of the transmitting device.
 *  @param startTime  Start time of the archive feed in UTC.
 *  @param endTime    End time of the archive feed in UTC.
 *  @param caption    Caption to use when displaying the video.
 *  @param message    A message to send with the command.
 *  @param recipients An array of Recipient objects.
 */
- (void)postViewArchiveForDevice:(NSString *)deviceId 
                betweenStartTime:(NSDate *)startTime 
                     andStopTime:(NSDate *)stopTime 
                         caption:(NSString *)caption 
                     withMessage:(NSString *)message 
                              to:(NSArray *)recipients;

@end
