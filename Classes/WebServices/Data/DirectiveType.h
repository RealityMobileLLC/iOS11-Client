//
//  DirectiveType.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The command directive.
 */
typedef enum 
{
	DT_Error = -1,
	DT_None,
	DT_TextMessage,
	DT_TurnOnCamera,
	DT_PlacePhoneCall,
	DT_ViewVideo,
	DT_DownloadFile,
	DT_TurnOffCamera,
	DT_KillPill,
	DT_ViewCameraUri,
	DT_ViewCameraInfo,
	DT_ViewUrl,
	DT_GoOffDuty,
	DT_DownloadImage
} DirectiveTypeEnum;


/**
 *  Wrapper around the DirectiveTypeEnum allowing for easy
 *  conversion to and from an NSString.
 */
@interface DirectiveType : NSObject 

/**
 *  Value as a DirectiveTypeEnum.
 */
@property (nonatomic) DirectiveTypeEnum value;

/**
 *  Initializes a DirectiveType object from the given string.  If the string
 *  does not map to a valid DirectiveTypeEnum, the returned object is 
 *  initialized with the value DT_Error.
 *
 *  @param stringValue String representation of one of the DirectiveTypeEnum values.
 *  @return initialized DirectiveType
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a DirectiveType object with the given value.
 *  
 *  @param value Initial value
 *  @return initialized DirectiveType
 */
- (id)initWithValue:(DirectiveTypeEnum)value;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Gets the string value for the given DirectiveTypeEnum.
 */
+ (NSString *)stringValueForEnum:(DirectiveTypeEnum)value;

@end
