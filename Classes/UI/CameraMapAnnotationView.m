//
//  CameraMapAnnotationView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CameraMapAnnotationView.h"
#import "CameraInfoWrapper.h"
#import "TransmitterInfo.h"
#import "GpsLockStatus.h"


@implementation CameraMapAnnotationView
{
    BOOL useCalloutAccessories;
}


-    (id)initWithCamera:(CameraInfoWrapper *)camera 
  andCalloutAccessories:(BOOL)calloutAccessories 
		reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:camera reuseIdentifier:reuseIdentifier];
	if (self != nil)
	{
        useCalloutAccessories = calloutAccessories;
		self.canShowCallout = YES;
		self.rightCalloutAccessoryView = (useCalloutAccessories) ? [UIButton buttonWithType:UIButtonTypeDetailDisclosure] : nil;
	}
	return self;
}


- (CameraInfoWrapper *)camera
{
	return (CameraInfoWrapper *)self.annotation;
}


- (void)update
{
    if (useCalloutAccessories)
    {
        // show play button only if camera is available
        UIImage * playButtonImage = self.camera.isAvailable ? [UIImage imageNamed:@"map_video_play"] 
		                                                    : [UIImage imageNamed:@"ic_list_inactive"];
		
        UIButton * playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [playButton setImage:playButtonImage forState:UIControlStateNormal];
        playButton.frame = CGRectMake(0, 0, 32, 32);
        self.leftCalloutAccessoryView = playButton;
    }
    
    [super update];
}


- (UIImage *)sourceImage
{
    if (self.camera.isTransmitter)
    {
        // on the iPad, transmitters should only be displayed as UserMapAnnotationViews but we need to support iPhone too
        TransmitterInfo * transmitter = self.camera.sourceObject;
        NSString * imageNamePrefix = (transmitter.gpsLockStatus.value == GL_Lock) ? @"gps-on-with-a-lock" 
		                                                                          : @"gps-on-with-old-location";
        return [UIImage imageNamed:[NSString stringWithFormat:@"%@-n-transmitting", imageNamePrefix]];
    }
    else if (self.camera.isScreencast)
	{
		return [UIImage imageNamed:@"screencast"];
	} 
	else if (self.camera.isVideoFile)
	{
		return [UIImage imageNamed:@"video_file"];
	}
	else
	{
		return self.camera.isAvailable ? [UIImage imageNamed:@"fixed-camera-with-heartbeat"] 
		                               : [UIImage imageNamed:@"fixed-camera"];
	}
}


- (NSString *)sourceName
{
    return self.camera.name;
}

@end
