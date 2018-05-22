//
//  TransmitPreferences.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "TransmitPreferences.h"


// Keys used for serialization
static NSString * const KEY_CAMERA_RESOLUTION = @"CameraResolution";
static NSString * const KEY_JPEG_COMPRESSION  = @"JpegCompression";
static NSString * const KEY_BANDWIDTH_LIMIT   = @"BandwidthLimit";
static NSString * const KEY_SHOW_STATISTICS   = @"ShowStatistics";


@implementation TransmitPreferences
{
	TransmitCameraResolution cameraResolution;
	TransmitJpegCompression  jpegCompression;
	TransmitBandwidthLimit   bandwidthLimit;
	BOOL                     showStatistics;
}

@synthesize cameraResolution;
@synthesize jpegCompression;
@synthesize bandwidthLimit;
@synthesize showStatistics;


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		cameraResolution = TR_Medium;
		jpegCompression  = TC_Medium;
		bandwidthLimit   = TB_Unlimited;
		showStatistics   = NO;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder 
{
	cameraResolution = [coder decodeIntForKey:KEY_CAMERA_RESOLUTION];
	jpegCompression  = [coder decodeIntForKey:KEY_JPEG_COMPRESSION];
	bandwidthLimit   = [coder decodeIntForKey:KEY_BANDWIDTH_LIMIT];
	showStatistics   = [coder decodeBoolForKey:KEY_SHOW_STATISTICS];
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeInt:cameraResolution forKey:KEY_CAMERA_RESOLUTION];
    [coder encodeInt:jpegCompression  forKey:KEY_JPEG_COMPRESSION];
	[coder encodeInt:bandwidthLimit   forKey:KEY_BANDWIDTH_LIMIT];
	[coder encodeBool:showStatistics  forKey:KEY_SHOW_STATISTICS];
}


@end
