//
//  AttachmentPurposeType.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The purpose type of an attachment.
 */
typedef enum 
{
	AP_Image,
	AP_AnnotatedImage
} AttachmentPurposeTypeEnum;


/**
 *  Wrapper around the AttachmentPurposeTypeEnum allowing for easy
 *  conversion to and from an NSString.
 */
@interface AttachmentPurposeType : NSObject 

/**
 *  Value as a AttachmentPurposeTypeEnum.
 */
@property (nonatomic) AttachmentPurposeTypeEnum value;

/**
 *  Initializes a AttachmentPurposeType object.
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a AttachmentPurposeType object.
 */
- (id)initWithValue:(AttachmentPurposeTypeEnum)value;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Gets the string value for the given AttachmentPurposeTypeEnum.
 */
+ (NSString *)stringValueForEnum:(AttachmentPurposeTypeEnum)value;

@end
