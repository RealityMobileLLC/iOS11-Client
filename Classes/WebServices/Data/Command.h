//
//  Command.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DirectiveType;
@class CommandResponseType;


/**
 *  A command that can be sent to a RealityVision client device.
 */
@interface Command : NSObject 

@property (strong, nonatomic) NSString            * commandId;
@property (strong, nonatomic) DirectiveType       * directive;
@property (strong, nonatomic) NSString            * parameter;
@property (strong, nonatomic) NSString            * message;
@property (strong, nonatomic) NSDate              * eventTime;
@property (nonatomic)         BOOL                  retrieved;
@property (strong, nonatomic) NSDate              * retrievedDate;
@property (nonatomic)         int                   senderId;
@property (strong, nonatomic) NSString            * senderUsername;
@property (strong, nonatomic) NSString            * senderFullName;
@property (strong, nonatomic) NSArray             * recipients;
@property (strong, nonatomic) NSArray             * attachments;
@property (strong, nonatomic) CommandResponseType * responseType;
@property (strong, nonatomic) NSString            * response;
@property (strong, nonatomic) NSDate              * responseDate;

@end
