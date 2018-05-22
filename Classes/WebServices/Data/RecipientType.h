//
//  RecipientType.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The type of recipients for a command.
 */
typedef enum 
{
    RT_Group,
    RT_User,
    RT_UserDevice
} RecipientTypeEnum;


/**
 *  Wrapper around the RecipientTypeEnum allowing for easy conversion to and from an NSString.
 */
@interface RecipientType : NSObject

/**
 *  Value as a RecipientTypeEnum.
 */
@property (nonatomic) RecipientTypeEnum value;

/**
 *  Initializes a RecipientType object.
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a RecipientType object.
 */
- (id)initWithValue:(RecipientTypeEnum)value;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Gets the string value for the given RecipientTypeEnum.
 */
+ (NSString *)stringValueForEnum:(RecipientTypeEnum)recipientType;

@end
