//
//  PttChannelManager.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/24/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "PttChannelManager.h"
#import "Channel.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "RealityVisionAppDelegate.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

static NSString * const kChannelListKey     = @"Channels";
static NSString * const kSelectedChannelKey = @"Selected";


@interface PttChannelManager ()

@property (nonatomic,strong) NSArray * channels;

@end


@implementation PttChannelManager
{
	BOOL updateInProgress;
}

@synthesize channels;
@synthesize selectedChannel;


#pragma mark - Initialization and cleanup

static PttChannelManager * instance;

+ (PttChannelManager *)instance
{
	if (instance == nil) 
	{
		@try 
		{
			// Restore channels from file, if it exists.
			NSString * filename = [self channelsFilename];
			BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
			instance =  fileExists ? [NSKeyedUnarchiver unarchiveObjectWithFile:filename] 
			                       : [[PttChannelManager alloc] init];
		}
		@catch (NSException * exception) 
		{
			DDLogWarn(@"Exception creating PttChannelManager: %@", exception);
			instance = nil;
		}
	}
	return instance;
}

- (id)init
{
	NSAssert(instance==nil,@"PttChannelManager singleton should only be instantiated once");
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	channels = [coder decodeObjectForKey:kChannelListKey];
	selectedChannel = [coder decodeObjectForKey:kSelectedChannelKey];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:channels forKey:kChannelListKey];
	[coder encodeObject:selectedChannel forKey:kSelectedChannelKey];
}


#pragma mark - Public methods

- (void)updateChannelList
{
	@synchronized(self)
	{
		if (updateInProgress)
			return;
		
		updateInProgress = YES;
	}
	
	NSURL * callConfigurationUrl = [ConfigurationManager instance].systemUris.messagingAndRouting;
	CallConfigurationService * callConfigurationService = [[CallConfigurationService alloc] initWithUrl:callConfigurationUrl];
	callConfigurationService.delegate = self;
	[callConfigurationService getChannelList];
}

- (void)invalidate
{
	@synchronized(self)
	{
		updateInProgress = NO;
		self.channels = nil;
		[self saveChannels];
	}
}


#pragma mark - CallConfigurationServiceDelegate methods

- (void)onGetChannelListResult:(NSArray *)result error:(NSError *)error
{
	@synchronized(self)
	{
		if (! updateInProgress)
			return;
		
		updateInProgress = NO;
	
		if ((result == nil) && (error == nil))
		{
			error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of channels."];
		}
		
		if (error)
		{
			DDLogError(@"PttChannelManager could not get PTT channels: %@", [error localizedDescription]);
			return;
		}
		
		self.channels = result;
		[self saveChannels];
	}
}


#pragma mark - Serialization

+ (NSString *)channelsFilename
{
	return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"PttChannels.prefs"];	
}

- (void)saveChannels
{
	NSString * filename = [PttChannelManager channelsFilename];
	if (! [NSKeyedArchiver archiveRootObject:self toFile:filename])
	{
		DDLogError(@"Could not save PTT channels");
	}
}

@end
