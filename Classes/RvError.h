//
//  RvError.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/17/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  RvError domain.
 */
extern NSString * const RV_DOMAIN;


/**
 *  RvError codes.
 */
enum  
{
	RV_ERROR = 1,        /**< Internal RealityVision error */
	RV_HTTP_ERROR,       /**< HTTP error                   */
	RV_USER_CANCEL,      /**< User cancelled request       */
    RV_NOT_SIGNED_ON,    /**< Client not signed on         */
};


/**
 *  A subclass of NSError used to encapsulate RealityVision-specific errors.
 */
@interface RvError : NSError 

/**
 *  Returns a string containing non-localized, error-specific information.
 */
@property (strong, nonatomic,readonly) NSString * message;

/**
 *  Returns the HTTP Status for RV_HTTP_ERRORs.
 */
@property (strong, nonatomic,readonly) NSNumber * httpStatus;

/**
 *  Returns an RvError object initialized for the RV_DOMAIN with the given code and userInfo dictionary.
 *
 *  @param code     The error code for the error.
 *  @param userInfo The userInfo dictionary for the error. userInfo may be nil.
 */
- (id)initWithCode:(int)code userInfo:(NSDictionary *)userInfo;

/**
 *  Creates a new RvError object with error code set to RV_ERROR and the given 
 *  description.
 *
 *  @param description A localized description of the error.
 */
+ (RvError *)rvErrorWithLocalizedDescription:(NSString *)description;

/**
 *  Creates a new RvError object with error code set to RV_HTTP_ERROR for the given
 *  HTTP status code.  Message should contain the body of the HTTP response.
 *
 *  @param status  HTTP status
 *  @param message HTTP body
 */
+ (RvError *)rvErrorWithHttpStatus:(UInt32)status message:(NSString *)message;

/**
 *  Creates a new RvError object with error code set to RV_USER_CANCEL.
 */
+ (RvError *)rvUserCancelled;

/**
 *  Creates a new RvError object with error code set to RV_NOT_SIGNED_ON.
 */
+ (RvError *)rvNotSignedOn;

@end
