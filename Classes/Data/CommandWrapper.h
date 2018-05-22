//
//  CommandWrapper.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Command;

/**
 *  Wrapper that provides a higher level abstraction for displaying and 
 *  executing a command.
 */
@interface CommandWrapper : NSObject 

/**
 *  The command.
 */
@property (strong, readonly) Command  * command;

/**
 *  The icon to use when displaying the command.
 */
@property (strong, readonly) UIImage  * icon;

/**
 *  The name to use when displaying the command.
 */
@property (strong, readonly) NSString * name;

/**
 *  The description to use when displaying the command.
 */
@property (strong, readonly) NSString * description;

/**
 *  The sender name to use when displaying the command.  This is the sender's
 *  full name, if available, otherwise it's the sender's username.
 */
@property (strong, readonly) NSString * senderName;

/**
 *  The recipients with groups listed first alphabetically, followed by users listed 
 *  alphabetically by full name.
 */
@property (strong, readonly) NSArray * sortedRecipients;

/**
 *  The event time as a localized string.
 */
@property (strong, readonly) NSString * eventTimeString;

/**
 *  The message to display in a command notification.  Includes the response
 *  and response time, if applicable.
 */
@property (strong, readonly) NSString * messageWithResponse;

/**
 *  Indicates whether the command is a "Force" command that gets immediately
 *  executed or a "Send" command that requires notification.
 */
@property (readonly) BOOL isForceCommand;

/**
 *  Indicates swhether the command was sent by the current user. Sent commands will
 *  not post received/accepted/dismissed command notifications to the server when 
 *  they are opened.
 */
@property (readonly) BOOL isSentCommand;

/**
 *  Indicates whether the command requests a user response that has not yet
 *  been provided.  
 */
@property (readonly) BOOL requiresResponse;

/**
 *  Indicates whether the command has been accepted.
 */
@property (readonly) BOOL wasAccepted;

/**
 *  Initializes a new CommandWrapper object.
 *
 *  @param cmd The Command object to wrap.
 */
- (id)initWithCommand:(Command *)cmd;

/**
 *  Initializes a new CommandWrapper object for a command sent by the current user.
 *  Sent commands will not post received/accepted/dismissed command notifications to
 *  the server when they are opened.
 *
 *  @param cmd The Command object to wrap.
 */
- (id)initWithSentCommand:(Command *)cmd;

/**
 *  Causes the command to be viewed.  For "Send" commands, this brings up a
 *  command notification that displays the message and allows the user to 
 *  view attached images, documents, cameras, URLs, etc.  For "Force" commands,
 *  this executes the command immediately.
 */
- (void)view;

/**
 *  Notifies the server that the user has accepted the command.
 */
- (void)accept;

/**
 *  Notifies the server that the user has provided a response to the command.
 *
 *  @param response Response to provide to the server, or nil if no response required.
 */
- (void)acceptWithResponse:(NSString *)response;

/**
 *  Notifies the server that the user has dismissed the command.
 */
- (void)dismiss;

@end
