//
//  CommandResponseType.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The type of response expected from a command.
 */
typedef enum 
{
	CR_None = 1,
	CR_YesNo
} CommandResponseTypeEnum;


/**
 *  Wrapper around the CommandResponseTypeEnum allowing for easy
 *  conversion to and from an NSString.
 */
@interface CommandResponseType : NSObject 

/**
 *  Value as a CommandResponseTypeEnum.
 */
@property (nonatomic) CommandResponseTypeEnum value;

/**
 *  Initializes a CommandResponseType object.
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a CommandResponseType object.
 */
- (id)initWithValue:(CommandResponseTypeEnum)value;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Gets the string value for the given CommandResponseTypeEnum.
 */
+ (NSString *)stringValueForEnum:(CommandResponseTypeEnum)value;

@end
