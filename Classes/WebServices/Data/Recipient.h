//
//  Recipient.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Selectable.h"
#import "RecipientType.h"

@class Device;
@class Group;
@class User;


/**
 *  A recipient of a RealityVision Command.
 *  
 *  @todo this should be immutable (i.e., all properties should be readonly)
 */
@interface Recipient : NSObject <Selectable>

/**
 *  The type of recipient (i.e., group or user).
 */
@property (strong, nonatomic) RecipientType * recipientType;

/**
 *  The unique identifier for the recipient, depending on recipient type.
 *  If recipientType is RT_Group, this is the unique group ID.
 *  For all other recipient types, it is the unique user ID.
 */
@property (nonatomic) int recipientId;

/**
 *  The name of the user or group.
 */
@property (strong, nonatomic) NSString * name;

/**
 *  Identifies the recipient device.
 *  This is only set when recipientType is RT_UserDevice.
 */
@property (strong, nonatomic) NSString * deviceId;

/**
 *  The name of the recipient device.
 *  This is only set when recipientType is RT_UserDevice.
 */
@property (strong, nonatomic) NSString * deviceName;

/**
 *  Initializes a Recipient object for a group.
 *  The recipientType is set to RT_Group.
 */
- (id)initWithGroup:(Group *)group;

/**
 *  Initializes a Recipient object for a user.
 *  The recipientType is set to RT_User.
 */
- (id)initWithUser:(User *)user;

/**
 *  Initializes a Recipient object for the user of a device.
 *  The recipientType is set to RT_User.
 */
- (id)initWithUserOfDevice:(Device *)user;

/**
 *  Initializes a Recipient object for a user at a particular device.
 *  The recipientType is set to RT_UserDevice.
 */
- (id)initWithDevice:(Device *)device;

/**
 *  Returns an NSComparisonResult value that indicates the lexical ordering of 
 *  the receiver and another Recipient object.  The comparison is performed on
 *  the name property of the two objects.
 *  
 *  @param recipient The recipient with which to compare the receiver.
 *  @return NSOrderedAscending if the receiver precedes recipient; 
 *          NSOrderedSame if the receiver and recipient are equivalent;
 *          and NSOrderedDescending if the receiver follows recipient.
 */
- (NSComparisonResult)compare:(Recipient *)recipient;

/**
 *  Returns a string with the name of each Recipient in the given array.
 */
+ (NSString *)stringWithRecipients:(NSArray *)recipients;

@end
