//
//  DeviceCapabilities.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/9/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "DeviceCapabilities.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#if TARGET_OS_EMBEDDED
#import <AVFoundation/AVFoundation.h>
#endif

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


//
// Keys for capabilities dictionary.
//
NSString * const KEY_PLATFORM           = @"Platform";
NSString * const KEY_OS_VERSION         = @"OSVersion";
NSString * const KEY_APP_VERSION        = @"ApplicationVersion";
NSString * const KEY_PHONE_NUMBER       = @"PhoneNumber";
NSString * const KEY_DEVICE_NAME        = @"Name";
NSString * const KEY_SUPPORT_GPS        = @"SupportsGps";
NSString * const KEY_SUPPORT_VIDEO      = @"SupportsVideo";
NSString * const KEY_SUPPORT_PHONE      = @"SupportsPhoneCall";
NSString * const KEY_SUPPORT_COMMANDS   = @"SupportsCommandReceipt";
NSString * const KEY_MANUFACTURER       = @"Manufacturer";
NSString * const KEY_CARRIER            = @"Carrier";
NSString * const KEY_PUSH_SERVICE       = @"PushService";
NSString * const KEY_PUSH_TOKEN         = @"PushToken";
NSString * const KEY_PLATFORM_DEVICE_ID = @"PlatformDeviceId";

//
// Constant values used as capabilities values.
//
static const NSString * const PLATFORM     = @"iOS";
static const NSString * const MANUFACTURER = @"Apple";
static const NSString * const BOOL_TRUE    = @"true";
static const NSString * const BOOL_FALSE   = @"false";

#ifdef RV_DISTRIBUTION
static const NSString * const PUSH_SERVICE = @"Apple";
#else
static const NSString * const PUSH_SERVICE = @"Apple-Sandbox";
#endif


@implementation DeviceCapabilities

@synthesize values;


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		UIDevice * device     = [UIDevice currentDevice];
		NSString * appVersion = [RealityVisionAppDelegate versionString];
		
        const NSString * const supportsPhone = [DeviceCapabilities supportsPhone] ? BOOL_TRUE : BOOL_FALSE;
        const NSString * const supportsVideo = [DeviceCapabilities supportsVideo] ? BOOL_TRUE : BOOL_FALSE;
		
		// Initializes dictionary with pairs of objects and keys.
		// Note that each pair has the object first followed by the key.
		values = 
			[NSMutableDictionary dictionaryWithObjectsAndKeys:
				PLATFORM,              KEY_PLATFORM,
				device.name,           KEY_DEVICE_NAME,
				device.systemVersion,  KEY_OS_VERSION,
				MANUFACTURER,          KEY_MANUFACTURER,
				supportsPhone,         KEY_SUPPORT_PHONE,
				BOOL_TRUE,             KEY_SUPPORT_GPS,
				supportsVideo,         KEY_SUPPORT_VIDEO,
				BOOL_TRUE,             KEY_SUPPORT_COMMANDS,
				appVersion,            KEY_APP_VERSION,
				PUSH_SERVICE,          KEY_PUSH_SERVICE,
				self.uniqueIdentifier, KEY_PLATFORM_DEVICE_ID,
				nil];

#ifdef RV_CARRIER_IN_DEVICE_CAPABILITIES
		CTCarrier * carrier = [[CTCarrier alloc] init];
		if (carrier != nil)
		{
			[values setValue:carrier.carrierName forKey:KEY_CARRIER];
		}
#endif
		
	}
	return self;
}

- (NSString *)uniqueIdentifier
{

	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version < 7.0)
    {
		// use mac address of wifi as the unique device identifier
		int mgmtInfoBase[6];
		mgmtInfoBase[0] = CTL_NET;
		mgmtInfoBase[1] = AF_ROUTE;
		mgmtInfoBase[2] = 0;
		mgmtInfoBase[3] = AF_LINK;
		mgmtInfoBase[4] = NET_RT_IFLIST;
		mgmtInfoBase[5] = if_nametoindex("en0");  // index for wifi adapter
		
		if (mgmtInfoBase[5] == 0)
		{
			DDLogWarn(@"DeviceCapabilities uniqueIdentifier: unable to get index for wifi adapter");
			return nil;
		}
		
		size_t length;
		if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
		{
			DDLogWarn(@"DeviceCapabilities uniqueIdentifier: unable to determine buffer size");
			return nil;
		}
		
		char * msgBuffer = malloc(length);
		if (msgBuffer == NULL)
		{
			DDLogWarn(@"DeviceCapabilities uniqueIdentifier: unable to allocate buffer");
			return nil;
		}
		
		if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
		{
			DDLogWarn(@"DeviceCapabilities uniqueIdentifier: sysctl failed to get network interface list");
			free(msgBuffer);
			return nil;
		}
		
		struct if_msghdr * interfaceMsgStruct = (struct if_msghdr *)msgBuffer;
		struct sockaddr_dl * socketStruct = (struct sockaddr_dl *)(interfaceMsgStruct + 1);
		unsigned char * macAddress = (unsigned char *)socketStruct->sdl_data + socketStruct->sdl_nlen;
		
		NSString * uniqueIdentifier = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
																 macAddress[0], macAddress[1], macAddress[2],
																 macAddress[3], macAddress[4], macAddress[5]];
		free(msgBuffer);
		
		
		DDLogVerbose(@"DeviceCapabilities uniqueIdentifier: %@", uniqueIdentifier);
		return uniqueIdentifier;
	}
	else
	{
		return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
	}
}

- (void)setValue:(NSString *)value forKey:(NSString *)key
{
	[values setValue:value forKey:key];
}

- (NSDictionary *)pushNotificationValues
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[values objectForKey:KEY_PUSH_TOKEN], KEY_PUSH_TOKEN,
				PUSH_SERVICE,                         KEY_PUSH_SERVICE,
				nil];
}

+ (BOOL)supportsVideo
{
#if TARGET_OS_EMBEDDED
	
#if 0 // debug code to enumerate the available A/V devices 
	NSArray * devices = [AVCaptureDevice devices];
	DDLogVerbose(@"There are %d AV devices available:", [devices count]);
	
	for (AVCaptureDevice * device in devices)
	{
		DDLogVerbose(@"  Unique ID: %@", device.uniqueID);
		DDLogVerbose(@"  Name     : %@", device.localizedName);
		DDLogVerbose(@"  Model ID : %@", device.modelID);
		DDLogVerbose(@"  Connected: %d", device.connected);
		DDLogVerbose(@"");
	}
#endif
	
	return ([AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] != nil);
#else
    // on simulator, say we support video even though it doesn't
    return YES;
#endif
}

+ (BOOL)supportsPhone
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://5555555555"]];
}

@end 
