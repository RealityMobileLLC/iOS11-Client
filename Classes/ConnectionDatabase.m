//
//  ConnectionDatabase.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ConnectionDatabase.h"
#import "ConnectionProfile.h"

#import "QueryString.h"


// Preferences key values
static NSString * const HostNameKey = @"host_preference";
static NSString * const PathNameKey = @"path_preference";
static NSString * const SslKey      = @"secure_preference";
static NSString * const ExternalKey = @"external_preference";
static NSString * const PortKey     = @"port_preference";


@interface ConnectionDatabase ()
+ (NSDictionary *)defaults;
+ (id)valueOrDefaultForKey:(NSString *)key defaults:(NSDictionary *)defaults;
@end


@implementation ConnectionDatabase


#pragma mark -
#pragma mark Public methods

+ (ConnectionProfile *)activeProfile
{
	ConnectionProfile * profile = nil;

	NSString * host = [[NSUserDefaults standardUserDefaults] stringForKey:HostNameKey];
	if (! NSStringIsNilOrEmpty(host))
	{
		NSDictionary * defaults = [self defaults];
		
		NSString * path          = [self valueOrDefaultForKey:PathNameKey defaults:defaults];
		NSNumber * portValue     = [self valueOrDefaultForKey:PortKey     defaults:defaults];
		NSNumber * useSslValue   = [self valueOrDefaultForKey:SslKey      defaults:defaults];
		NSNumber * externalValue = [self valueOrDefaultForKey:ExternalKey defaults:defaults];
		
		int  port     = [portValue intValue];
		BOOL useSsl   = [useSslValue boolValue];
		BOOL external = [externalValue boolValue];
		
		profile = [[ConnectionProfile alloc] initWithHost:host 
												    useSsl:useSsl 
											    isExternal:external 
													  port:port 
													  path:[QueryString urlEncodeString:path]];
	}
	
	return profile;
}


+ (void)setActiveProfile:(ConnectionProfile *)newProfile
{
	// save new profile to settings bundle
	[[NSUserDefaults standardUserDefaults] setObject:newProfile.host     forKey:HostNameKey];
	[[NSUserDefaults standardUserDefaults] setObject:newProfile.path     forKey:PathNameKey];
	[[NSUserDefaults standardUserDefaults] setInteger:newProfile.port    forKey:PortKey];
	[[NSUserDefaults standardUserDefaults] setBool:newProfile.useSsl     forKey:SslKey];
	[[NSUserDefaults standardUserDefaults] setBool:newProfile.isExternal forKey:ExternalKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -
#pragma mark Private methods

+ (NSDictionary *)defaults
{
	// create dictionary for defaults
	NSMutableDictionary * defaults = [NSMutableDictionary dictionaryWithCapacity:4];
	
	// read defaults property list file
	NSString * bundlePath   = [[NSBundle mainBundle] bundlePath];
	NSString * settingsPath = [bundlePath stringByAppendingPathComponent:@"Settings.bundle"];
	NSString * plistPath    = [settingsPath stringByAppendingPathComponent:@"Root.plist"];
	NSDictionary * settings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	
	// place default values in dictionary
	for (NSDictionary * prefItem in [settings objectForKey:@"PreferenceSpecifiers"])
	{
		NSString * key  = [prefItem objectForKey:@"Key"];
		id defaultValue = [prefItem objectForKey:@"DefaultValue"];
		
		if ((key != nil) && (defaultValue != nil))
		{
			[defaults setObject:defaultValue forKey:key];
		}
	}
	
	return defaults;
}


+ (id)valueOrDefaultForKey:(NSString *)key defaults:(NSDictionary *)defaults
{
	id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
	
	if (value == nil)
	{
		value = [defaults objectForKey:key];
	}
	
	return value;
}

@end
