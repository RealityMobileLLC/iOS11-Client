//
//  ClientTransaction.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"

@class ArrayOfFavoriteEntry;
@class ClientStatus;
@class ClientTransaction;
@class Command;
@class CommandHistoryResult;
@class DirectiveType;
@class GpsLockStatus;
@class Session;
@class SessionResult;


/**
 *  Delegate used by the ClientTransaction class to indicate when web services respond.
 */
@protocol ClientTransactionDelegate

@optional

/**
 *  Called when an AddFavoriteCommand call completes.
 *
 *  @param favoriteId Unique identifier of the added favorite.
 *  @param error      An error, if one occurred, or nil if the operation
 *                    completed successfully.
 */
- (void)onAddFavoriteResult:(NSNumber *)favoriteId error:(NSError *)error;

/**
 *  Called when an AddComment call completes.
 *
 *  @param error  The error, if one occurred, or nil if successful.
 *  @param sender The ClientTransaction operation that completed.
 */
- (void)onAddComment:(NSError *)error fromClientTransaction:(ClientTransaction *)sender;

/**
 *  Called when a GetCommandHistory call completes.
 *
 *  @param commandHistory The CommandHistoryResult returned by the GetCommandHistory service.
 *  @param error          An error, if one occurred, or nil if the operation 
 *                        completed successfully.
 */
- (void)onCommandHistoryResult:(CommandHistoryResult *)commandHistory error:(NSError *)error;

/**
 *  Called when a GetCommand call completes.
 *  
 *  @param command The Command returned by the GetCommand service.
 *  @param error   An error, if one occurred, or nil if the operation
 *                 completed successfully.
 */
- (void)onGetCommandResult:(Command *)command error:(NSError *)error;

/**
 *  Called when an GetPendingCommandCount call completes.
 *
 *  @param count Number of commands the user has not yet viewed on any device.
 *  @param error An error, if one occurred, or nil if the operation
 *               completed successfully.
 */
- (void)onGetUnreadCommandCountResult:(NSNumber *)count error:(NSError *)error;

/**
 *  Called when a GetFavorites call completes.
 *  
 *  @param favorites  An array of FavoriteEntry objects returned by GetFavorites.
 *  @param error      An error, if one occurred, or nil if the operation
 *                    completed successfully.
 */
- (void)onGetFavoritesResult:(NSArray *)favorites error:(NSError *)error;

/**
 *  Called when a GetSession call completes.
 *  
 *  @param session The Session returned by the GetSession service.
 *  @param error   An error, if one occurred, or nil if the operation
 *                 completed successfully.
 */
- (void)onGetSessionResult:(Session *)session error:(NSError *)error;

/**
 *  Called when a GetTransmitters call completes.
 *
 *  @param transmitters An array of TransmitterInfo objects returned by GetTransmitters.
 *  @param error        An error, if one occurred, or nil if the operation
 *                      completed successfully.
 */
- (void)onGetTransmittersResult:(NSArray *)transmitters error:(NSError *)error;

/**
 *  Called when a SearchVideoHistory call completes.
 *
 *  @param sessions An array of SessionResult objects returned by SearchVideoHistory.
 *  @param error    An error, if one occurred, or nil if the operation
 *                  completed successfully.
 */
- (void)onVideoHistoryResult:(SessionResult *)sessions error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision Client Transaction web service requests.
 */
@interface ClientTransaction : WebService 

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <ClientTransactionDelegate> delegate;

/**
 *  Initializes a ClientTransaction object.
 *
 *  @param url The base URL for RealityVision web services.
 *  @return An initialized ClientTransaction object or nil if the object could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 *  Initiates an Accept Command request.
 *
 *  @param commandId The ID of the command to accept.
 *  @param deviceId  The client's device ID.
 *  @param response  The client's response to the command.
 */
- (void)acceptCommand:(NSString *)commandId 
			forDevice:(NSString *)deviceId 
		 withResponse:(NSString *)response;

/**
 *  Initiates an Add Comment To Last Session request.
 *
 *  @param comment  The user's comment.
 *  @param deviceId The client's device ID.
 */
- (void)addComment:(NSString *)comment toLastSessionforDevice:(NSString *)deviceId; 

/**
 *  Initiates an Add Session Comment request.
 *
 *  @param comment   The user's comment.
 *  @param sessionId The session.
 */
- (void)addComment:(NSString *)comment forSession:(int)sessionId; 

/**
 *  Initiates an Add Frame Comment request.
 *
 *  @param comment   The user's comment.
 *  @param sessionId The session.
 *  @param frameId   The frame.
 */
- (void)addComment:(NSString *)comment forSession:(int)sessionId andFrame:(int)frameId; 

/**
 *  Inititates an Add Favorite request.
 *
 *  @param command The command to be favorited.
 *  @param caption The caption that describes the favorite.
 *  @return A unique ID for the added favorite.
 */
- (void)addFavoriteCommand:(Command *)command withCaption:(NSString *)caption;

/**
 *  Initiates an Add Favorite Entries request.
 *
 *  @param entries An array of favorite entries.
 */
- (void)addFavoriteEntries:(ArrayOfFavoriteEntry *)entries;

/**
 *  Initiates a Delete Favorite request.
 *
 *  @param favoriteId The ID of the favorite entry to delete.
 */
- (void)deleteFavorite:(int)favoriteId; 

/**
 *  Initiates a Delete Favorites request.
 *
 *  @param favoriteIds An array of favorite IDs to delete.
 */
- (void)deleteFavorites:(NSArray *)favoriteIds;

/**
 *  Initiates a Dismiss Command request.
 *
 *  @param commandId The ID of the command to dismiss.
 *  @param deviceId  The client's device ID.
 */
- (void)dismissCommand:(NSString *)commandId forDevice:(NSString *)deviceId;

/**
 *  Initiates a Get Command request.
 *
 *  @param deviceId  The client's device ID.
 */
- (void)getCommandForDevice:(NSString *)deviceId;

/**
 *  Initiates a Get Command By ID request.
 *
 *  @param commandId The ID of the command to get.
 */
- (void)getCommandById:(NSString *)commandId;

/**
 *  Initiates a Get Device Info request.
 *
 *  @param deviceId The client's device ID.
 */
- (void)getDeviceInfoForDevice:(NSString *)deviceId;

/**
 *  Initiates a Get Favorites request.
 */
- (void)getFavorites;

/**
 *  Initiates a Get New History Count request.
 */
- (void)getNewHistoryCount;

/**
 *  Initiates a Get Retrieved Commands request.
 *  The delegate will receive an onGetCommandHistoryResult: message when complete.
 *  
 *  @param commandId The ID of the last command received, or nil to get the newest commands.
 *  @param count     Number of commands to get, or -1 to get all.
 */
- (void)getReceivedCommandsAfterCommand:(NSString *)commandId count:(int)count;

/**
 *  Initiates a Get Sent Commands Of Type request.
 *  The delegate will receive an onGetCommandHistoryResult: message when complete.
 *  
 *  @param directiveType The type of commands to retrieve.
 *  @param commandId     The ID of the last command received, or nil to get the newest commands.
 *  @param count         Number of commands to get, or -1 to get all.
 */
- (void)getSentCommandsOfType:(DirectiveType *)directiveType 
                 afterCommand:(NSString *)commandId 
                        count:(int)count;

/**
 *  Initiates a Get Session request.
 */
- (void)getSession:(int)sessionId;

/**
 *  Initiates a Get Transmitters request.
 */
- (void)getTransmitters;

/**
 *  Initiates a Get Unread Command Count request.
 */
- (void)getUnreadCommandCount;

/**
 *  Initiates a Ping request.
 */
- (void)ping;

/**
 *  Initiates a Post Capabilities request.
 *
 *  @param capabilities Dictionary containing the capabilities for the device.
 *  @param deviceId     The client's device ID.
 */
- (void)postCapabilities:(NSDictionary *)capabilities forDevice:(NSString *)deviceId;

/**
 *  Initiates a Post GPS request.
 *
 *  @param nmeaString The location in NMEA format.
 *  @param deviceId   The client's device ID.
 */
- (void)postGpsLocation:(NSString *)nmeaString forDevice:(NSString *)deviceId;

/**
 *  Initiates a Post GPS Status request.
 *  
 *  @param gpsIsOn    Indicates whether location monitoring is enabled.
 *  @param lockStatus The device's location lock status.
 *  @param nmeaString The location in NMEA format.
 *  @param deviceId   The client's device ID.
 */
- (void)postGpsOn:(BOOL)gpsIsOn 
	   lockStatus:(GpsLockStatus *)lockStatus 
			 nmea:(NSString *)nmeaString 
		forDevice:(NSString *)deviceId;

/**
 *  Initiates a Post Status request.
 *
 *  @param status   The current status of the device.
 *  @param deviceId The client's device ID.
 */
- (void)postStatus:(ClientStatus *)status forDevice:(NSString *)deviceId;

/**
 *  Initiates a Received Command request.
 *
 *  @param commandId The ID of the command to acknowledge.
 *  @param deviceId  The client's device ID.
 */
- (void)receivedCommand:(NSString *)commandId forDevice:(NSString *)deviceId;

/**
 *  Initiates a Received New History Count request.
 */
- (void)receivedNewHistoryCount;

/**
 *  Initiates a Search Video History request.
 *  
 *  @param text   Text to search for in video comments.
 *  @param offset The offset into the result set of the first session to return.
 *  @param count  The number of sessions to return.
 */
- (void)searchVideoHistoryFor:(NSString *)text offset:(int)offset count:(int)count;

/**
 *  Initiates an Update Connection Time request.
 */
- (void)updateConnectionTimeForDevice:(NSString *)deviceId;

/**
 *  Initiates an Update Favorite request.
 *
 *  @param favoriteId The ID of the favorite entry to update.
 *  @param command    The new command to be favorited.
 *  @param caption    The new caption that describes the favorite.
 */
- (void)updateFavorite:(int)favoriteId 
           withCommand:(Command *)command 
            andCaption:(NSString *)caption;

@end
