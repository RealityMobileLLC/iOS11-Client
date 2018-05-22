//
//  Base64.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "Base64.h"

static const int EncodeTableLength = 64;
static const int DecodeTableLength = 123;


/**
 *  A lookup table used to translate a 6-bit unsigned integer into its Base 64 
 *  equivalent as specified in Table 1 of RFC 2045.
 */
static char EncodeTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


/**
 *  A lookup table used to translate a 6-bit unsigned integer into its URL-safe 
 *  Base 64 equivalent.
 */
static char UrlEncodeTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";


/**
 *  A lookup table used to translate a UTF-8 Base 64 character into its 6-bit 
 *  unsigned integer equivalent as specified in Table 1 of RFC 2045.  UTF-8 
 *  characters that are not in the Base 64 alphabet translate to -1.
 * 
 *  Note: '+' and '-' both decode to 62. '/' and '_' both decode to 63. This 
 *  allows the decoder to seamlessly handle both URL_SAFE and RFC 2045 
 *  encodings.
 */
static int8_t DecodeTable[] = 
{
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, 62, -1, 63, 
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, 
	-1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, 63, 
	-1, 26, 27, 28, 29, 30, 31, 32, 33, 34,	35, 36, 37, 38, 39, 40, 
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
};

/**
 *  Pad character used to terminate encoded data.
 */
static const char PadByte = '=';


@implementation Base64


+ (NSString *)encodeBuffer:(const void *)data ofSize:(NSInteger)length urlSafe:(BOOL)urlSafe
{
	const uint8_t * input = data;
	const char    * encodeTable = urlSafe ? UrlEncodeTable : EncodeTable;
	
	// every 3 bytes requires 4 characters to encode (3 * 8 bits = 4 * 6 bits)
    NSMutableData * buffer = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    char          * output = buffer.mutableBytes;
	
	int outputIndex = 0;
    for (int i = 0; i < length; i += 3) 
    {
        int32_t value = 0;
		
        for (int j = i; j < (i + 3); j++) 
		{
            value <<= 8;
			
            if (j < length) 
			{
                value |= (input[j] & 0xFF);
            }
        }
		
        output[outputIndex++] =                    encodeTable[(value >> 18) & 0x3F];
        output[outputIndex++] =                    encodeTable[(value >> 12) & 0x3F];
        output[outputIndex++] = (i + 1) < length ? encodeTable[(value >> 6)  & 0x3F] : PadByte;
        output[outputIndex++] = (i + 2) < length ? encodeTable[value         & 0x3F] : PadByte;
    }
	
    return [[NSString alloc] initWithData:buffer encoding:NSASCIIStringEncoding];
}


+ (NSString *)encodeCString:(const char *)data urlSafe:(BOOL)urlSafe
{
	return [Base64 encodeBuffer:data ofSize:strlen(data) urlSafe:urlSafe];
}


+ (NSString *)encode:(NSData *)data  urlSafe:(BOOL)urlSafe
{
	return [Base64 encodeBuffer:[data bytes] ofSize:[data length] urlSafe:urlSafe];
}


/**
 *  Based on Java version found in:
 *  http://svn.apache.org/viewvc/commons/proper/codec/trunk/src/java/org/apache/commons/codec/binary/Base64.java?revision=801706&view=markup
 */
+ (NSData *)decodeFromBuffer:(const void *)encodedBytes ofSize:(NSUInteger)encodedSize
{
	NSAssert(encodedBytes!=NULL,@"encodedBytes parameter must not be NULL");
	
	// every 4 encoded characters represent 3 decoded bytes (4 * 6 bits = 3 * 8 bits)
	NSMutableData * buffer = [NSMutableData dataWithLength:(encodedSize * 3) / 4];
	const char    * input  = encodedBytes;
	uint8_t       * output = buffer.mutableBytes;
	
	int outputIndex = 0;
	int modulus = 0;
	uint32_t accumulator = 0;
	
	for (int inputIndex = 0; inputIndex < encodedSize; inputIndex++) 
	{
		char base64Char = input[inputIndex];
		
		// pad character means we're done
		if (base64Char == PadByte) 
			break;
		
		if ((base64Char >= 0) && (base64Char < DecodeTableLength)) 
		{
			// translate base 64 character to 6 bit integer
			int8_t value = DecodeTable[base64Char];
			if (value >= 0)
			{
				accumulator = (accumulator << 6) | value;
				modulus = (++modulus) % 4;
				if (modulus == 0) 
				{
					output[outputIndex++] = (uint8_t) ((accumulator >> 16) & 0xFF);
					output[outputIndex++] = (uint8_t) ((accumulator >> 8)  & 0xFF);
					output[outputIndex++] = (uint8_t) (accumulator         & 0xFF);
				}
			}
		}
	}
	
	// see if we still have data to place in output array
	if (modulus != 0)
	{
		switch (modulus) 
		{
			case 1:
				// each encoded character represents 6 bits so if we end up
				// with only a single remaining character we don't have enough
				// information to decode it.  this will never happen with 
				// validly encoded data.
				break;
				
			case 2:
				accumulator <<= 12;
				output[outputIndex++] = (uint8_t) ((accumulator >> 16) & 0xFF);
				break;
				
			case 3:
				accumulator <<= 6;
				output[outputIndex++] = (uint8_t) ((accumulator >> 16) & 0xFF);
				output[outputIndex++] = (uint8_t) ((accumulator >> 8)  & 0xFF);
				break;
		}
	}
	
	// final result may be smaller than initially allocated buffer
	return [NSData dataWithBytes:output length:outputIndex];
}


+ (NSData *)decodeFromCString:(const char *)encodedBytes
{
	return [Base64 decodeFromBuffer:encodedBytes ofSize:strlen(encodedBytes)];
}


+ (NSData *)decode:(NSString *)encodedData
{
	const char * utf8EncodedData = [encodedData cStringUsingEncoding:NSUTF8StringEncoding];
	return [Base64 decodeFromCString:utf8EncodedData];
}


@end
