//
//  ClientStatus.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//


/**
 *  The client status.
 */
typedef enum
{
	CS_Connected    = 0x01,  /**< The client is connected to a server.  */
	CS_Transmitting = 0x02,  /**< The client is currently transmitting. */
	CS_Watching     = 0x04,  /**< The client is currently watching.     */
	CS_Panic        = 0x08   /**< The client is currently in alert.     */
} ClientStatusEnum;


/**
 *  Wrapper around the ClientStatusEnum allowing for easy
 *  conversion to and from an NSString.
 */
@interface ClientStatus : NSObject 

/**
 *  Value as a ClientStatusEnum.
 */
@property (nonatomic) ClientStatusEnum value;

/**
 *  Initializes a ClientStatus object from the given string.  If the string
 *  does not map to a valid ClientStatusEnum, the returned object is 
 *  initialized with the value 0.
 *
 *  @param stringValue String representation of one of the ClientStatusEnum values.
 *  @return initialized ClientStatus
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a ClientStatus object with the given value.
 *  
 *  @param clientStatus Initial value
 *  @return initialized ClientStatus
 */
- (id)initWithValue:(ClientStatusEnum)clientStatus;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Returns a ClientStatus object with the given string value.
 *
 *  @param stringValue String representation of one of the ClientStatusEnum values.
 *  @return initialized ClientStatus
 */
+ (ClientStatus *)clientStatusWithString:(NSString *)stringValue;

/**
 *  Returns a ClientStatus object with the given value.
 *  
 *  @param clientStatus Initial value
 *  @return initialized ClientStatus
 */
+ (ClientStatus *)clientStatusWithValue:(ClientStatusEnum)clientStatus;

/**
 *  Gets the string value for the given ClientStatusEnum.
 */
+ (NSString *)stringValueForEnum:(ClientStatusEnum)clientStatus;

@end
