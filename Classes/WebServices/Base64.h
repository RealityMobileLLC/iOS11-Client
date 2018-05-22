//
//  Base64.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Provides Base64 encoding and decoding using either MIME (RFC 2045) or 
 *  URL-safe encoding.
 *
 *  @see <a href="http://www.ietf.org/rfc/rfc2045.txt">RFC 2045</a>
 */
@interface Base64 : NSObject

/**
 *  Returns a Base 64 encoded representation of the given data.
 *
 *  @param data data to encode
 *  @param urlSafe whether to use RFC 2045 or URL-safe encoding
 *  @return string containing Base 64 representation of data
 */
+ (NSString *)encode:(NSData *)data urlSafe:(BOOL)urlSafe;

/**
 *  Returns a Base 64 encoded representation of the given C string.
 *
 *  @param data null-terminated C string to encode
 *  @param urlSafe whether to use RFC 2045 or URL-safe encoding
 *  @return string containing Base 64 representation of data
 */
+ (NSString *)encodeCString:(const char *)data urlSafe:(BOOL)urlSafe;

/**
 *  Returns a Base 64 encoded representation of the given data.
 *
 *  @param data pointer to data to encode
 *  @param size size of data to encode in bytes
 *  @param urlSafe whether to use RFC 2045 or URL-safe encoding
 *  @return string containing Base 64 representation of data
 */
+ (NSString *)encodeBuffer:(const void *)data ofSize:(NSInteger)size urlSafe:(BOOL)urlSafe;

/**
 *  Returns a buffer containing the decoded data from the Base 64 encoded string.
 *
 *  @param encodedData string containing Base 64 encoded data
 *  @return data object containing decoded data
 */
+ (NSData *)decode:(NSString *)encodedData;

/**
 *  Returns a buffer containing the decoded data from the Base 64 encoded C string.
 *
 *  @param encodedData C string containing Base 64 encoded data
 *  @return data object containing decoded data
 */
+ (NSData *)decodeFromCString:(const char *)encodedData;

/**
 *  Returns a buffer containing the decoded data from the Base 64 encoded data.
 *
 *  @param encodedData pointer to Base 64 encoded data
 *  @param encodedSize size of encoded data in bytes
 *  @return data object containing decoded data
 */
+ (NSData *)decodeFromBuffer:(const void *)encodedData ofSize:(NSUInteger)encodedSize;

@end
