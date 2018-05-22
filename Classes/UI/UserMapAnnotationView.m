//
//  UserMapAnnotationView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/22/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserMapAnnotationView.h"
#import "Device.h"
#import "UserDevice.h"


@implementation UserMapAnnotationView
{
    BOOL useCalloutAccessories;
}

- (id)initWithUser:(UserDevice *)userDevice andCalloutAccessories:(BOOL)calloutAccessories reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithAnnotation:userDevice reuseIdentifier:reuseIdentifier];
	if (self != nil)
	{
		self.canShowCallout = YES;
        useCalloutAccessories = calloutAccessories;
		
		if (useCalloutAccessories)
		{
			[self updateCalloutAccessoryViewsForUserDevice:userDevice];
		}
	}
	return self;
}

- (void)updateCalloutAccessoryViewsForUserDevice:(UserDevice *)userDevice
{
	NSAssert(useCalloutAccessories,@"updateCalloutAccessoryViewsForUserDevice should not be called if not using callout accesory views");
	
	// if user is transmitting, show play button
    if (userDevice.camera != nil)
    {
		if (self.leftCalloutAccessoryView == nil)
		{
			UIButton * leftCalloutButton = [UIButton buttonWithType:UIButtonTypeCustom];
			[leftCalloutButton setImage:[UIImage imageNamed:@"map_video_play"] forState:UIControlStateNormal];
			leftCalloutButton.frame = CGRectMake(0, 0, 32, 32);
			self.leftCalloutAccessoryView  = leftCalloutButton;
		}
    }
	else
	{
		self.leftCalloutAccessoryView = nil;
	}
	
	// if user is viewing video feeds, show detail disclosure button to access them
	if ([userDevice.device.viewers count] > 0)
	{
		if (self.rightCalloutAccessoryView == nil)
		{
			self.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		}
	}
	else 
	{
		self.rightCalloutAccessoryView = nil;
	}
}

- (UserDevice *)userDevice
{
	return (UserDevice *)self.annotation;
}

- (void)update
{
	if (useCalloutAccessories)
	{
		[self updateCalloutAccessoryViewsForUserDevice:self.userDevice];
	}
    [super update];
}

- (UIImage *)sourceImage
{
    Device * device = self.userDevice.device;
    
    NSString * imageNamePrefix = (device.gpsLockStatus.value == GL_Lock) ? @"gps-on-with-a-lock" : @"gps-on-with-old-location";
    NSString * imageNameStatus = @"";
    
    if (device.isPanic)
    {
        imageNameStatus = @"-n-alert";
    }
    else if (device.isCamera)
    {
        imageNameStatus = @"-n-transmitting";
    }
    else if (device.isViewer)
    {
        imageNameStatus = @"-n-watching";
    }
    
    NSString * imageName = [NSString stringWithFormat:@"%@%@", imageNamePrefix, imageNameStatus];
    return [UIImage imageNamed:imageName];
}

- (NSString *)sourceName
{
    return self.userDevice.device.fullName;
}

@end
