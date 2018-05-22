//
//  TransmitPreferences.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  iPhone camera resolution.
 */
typedef enum
{
	TR_Low,          /**<     192x144            */
	TR_Medium,       /**<     480x360            */
	TR_High          /**< 3GS:640x480 4:1280x720 */
} TransmitCameraResolution;


/**
 *  JPEG compression level.
 */
typedef enum
{
	TC_Low,          
	TC_Medium,
	TC_High
} TransmitJpegCompression;


/**
 *  Transmit bandwidth limit in kilobits per second.
 */
typedef enum
{
	TB_100,
	TB_200,
	TB_300,
	TB_500,
	TB_Unlimited
} TransmitBandwidthLimit;


/**
 *  Transmit preferences
 */
@interface TransmitPreferences : NSObject <NSCoding>

@property (nonatomic) TransmitCameraResolution cameraResolution;
@property (nonatomic) TransmitJpegCompression  jpegCompression;
@property (nonatomic) TransmitBandwidthLimit   bandwidthLimit;
@property (nonatomic) BOOL                     showStatistics;

@end
