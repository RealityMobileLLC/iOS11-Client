//
//  QueryString.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  An HTTP query string containing one or more parameters and values.
 */
@interface QueryString : NSObject 

/**
 *  The query string.
 */
@property (readonly,nonatomic) NSString * query;

/**
 *  Initializes an empty QueryString.
 *
 *  @return An initialized QueryString object or nil if the object could not
 *           be initialized.
 */
- (id)init;

/**
 *  Initializes a QueryString with the elements of the given array.  The first
 *  element of the array is a prefix (which may be an empty string).  Each
 *  additional element of the array is a parameter for the query.
 *  
 *  The resulting string is created by taking the prefix and then appending a 
 *  "?" followed by the parameters.  Each parameter is added by separating it 
 *  into its name and value components and then calling -append:stringValue: to 
 *  add it to the QueryString.
 *
 *  @param parameters An array whose first element is a prefix (which may be
 *                    an empty string) and whose remaining elements, if any,
 *                    are non-encoded parameters of the form "name=value".
 *                    The array must have at least one element, the prefix.
 *  
 *  @return An initialized QueryString object or nil if the object could not
 *           be initialized.
 */
- (id)initWithParameters:(NSArray *)parameters;

/**
 *  Appends a parameter to the QueryString with a string value.
 *
 *  @param name  The name of the parameter to append.
 *  @param value The value of the parameter to append.
 */
- (void)append:(NSString *)name stringValue:(NSString *)value;

/**
 *  Appends a parameter to the QueryString with a boolean value.
 *
 *  @param name  The name of the parameter to append.
 *  @param value The value of the parameter to append.
 */
- (void)append:(NSString *)name boolValue:(BOOL)value;

/**
 *  Appends a parameter to the QueryString with an integer value.
 *
 *  @param name  The name of the parameter to append.
 *  @param value The value of the parameter to append.
 */
- (void)append:(NSString *)name intValue:(int)value;

/**
 *  Appends a parameter to the QueryString with a date value.
 *
 *  @param name  The name of the parameter to append.
 *  @param value The value of the parameter to append.
 */
- (void)append:(NSString *)name dateValue:(NSDate *)value;

/**
 *  Gets the value for a parameter from a query string.
 *
 *  @param name  The name of the desired parameters.
 *  @param query A URL encoded query string.
 *  
 *  @return the value of the parameter or nil if the query string does not
 *           contain a parameter with that name
 */
+ (NSString *)getParameter:(NSString *)name fromQuery:(NSString *)query;

/**
 *  Gets an array containing an optional prefix followed by each of the 
 *  parameters from a query string.  Each parameter in the array has been 
 *  percent-decoded to its original form.
 *
 *  Given the URL: http://rv.domain.com/service?param1=foo&param2=bar
 *
 *  The resulting array will contain the following elements:
 *    0 : http://rv.domain.com/service
 *    1 : param1=foo
 *    2 : param2=bar
 *
 *  @param query A string containing a relative or absolute URL.
 *
 *  @return an array containing a prefix and one or more parameters
 */
+ (NSMutableArray *)getParametersFromQuery:(NSString *)query;

/**
 *  Uses percent-encoding to make a URL-safe version of the given string.
 *
 *  @param string The string to encode.
 *  
 *  @return URL-safe representation of the given string
 */
+ (NSString *)urlEncodeString:(NSString *)string;

/**
 *  Decodes a percent-encoded string back to readable form.
 *
 *  @param string The string to decode.
 *  
 *  @return decoded version of the given URL-safe string
 */
+ (NSString *)urlDecodeString:(NSString *)string;

@end
