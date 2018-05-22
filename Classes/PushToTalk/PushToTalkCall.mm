//
//  PushToTalkCall.mm
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/11/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "PushToTalkCall.h" 
#import "AudioToolbox/AudioToolbox.h"
#import "RVAudioFormat.h"
#import "RVSipAudioConnection.h"
#import "PttChannel.h"
#import "ConfigurationManager.h"
#import "ClientConfiguration.h"
#import "RealityVisionClient.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface PushToTalkCall () <RVAudioConnectionDelegate>
@property (nonatomic) PttChannelStatus connectionStatus;
@end


@implementation PushToTalkCall
{
	RVSipAudioConnection * session;
	NSTimer              * talkWatchdog;
	BOOL                   halfDuplex;
	BOOL                   isObservingSession;
	SystemSoundID          connectSound;
	SystemSoundID          disconnectSound;
}

@synthesize delegate;
@synthesize channel;
@synthesize connectionStatus;
@synthesize muted;
@synthesize talking;


#pragma mark - Initialization and cleanup

- (id)initWithChannel:(PttChannel *)theChannel
{
	NSAssert(theChannel!=nil,@"Channel is required");
	
	self = [super init];
	if (self != nil)
	{
		// @todo validate channel and codec here?
		channel = theChannel;
		connectionStatus = PttChannelDisconnected;
		halfDuplex = YES;         // @todo use full duplex if on headset
		
		NSURL * connectSoundFile = [[NSBundle mainBundle] URLForResource:@"prompt" 
														   withExtension:@"wav"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)connectSoundFile, &connectSound);

		NSURL * disconnectSoundFile = [[NSBundle mainBundle] URLForResource:@"double-beep" 
															  withExtension:@"wav"];
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)disconnectSoundFile, &disconnectSound);
	}
	return self;
}

- (void)dealloc
{
	if (connectionStatus != PttChannelDisconnected)
	{
		AudioServicesPlaySystemSound(disconnectSound);
	}
	
	if (session)
	{
		[self stopObservingSession];
	}
}


#pragma mark - Public methods

- (NSString *)channelName
{
	return [channel name];
}

- (void)setMuted:(BOOL)isMuted
{
	muted = isMuted;
	
	// update the session to enable or disable audio rendering
	if (session != nil) 
	{
		session.receiveEnabled = ! muted;
		
		if (talking && ! muted)
		{
			self.talking = NO;
		}
	}
}

- (void)setTalking:(BOOL)isTalking
{
	talking = isTalking;
	
	if (session != nil)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
					   ^{
						   // always enable speaker if call is full duplex; for half duplex enable speaker when not talking
						   self.muted = talking && halfDuplex;
						   [session setTransmitEnabled:talking error:NULL];
					   });
		
		[talkWatchdog invalidate];
		
		if (talking)
		{
			NSTimeInterval maxTalkTime = [ConfigurationManager instance].clientConfiguration.maximumPushToTalkTimeSeconds;
			talkWatchdog = [NSTimer scheduledTimerWithTimeInterval:maxTalkTime 
															target:self 
														  selector:@selector(maxTalkTimeout) 
														  userInfo:nil 
														   repeats:NO];
		}
	}
}

- (BOOL)connect
{
	NSAssert(![session isActive],@"Can not connect to a PTT channel while one is already active");
	NSAssert(channel!=nil,@"No channel selected");
	DDLogInfo(@"Connecting to PTT channel %@", channel.name);
	
	RVAudioFormat * audioFormat = [RVAudioFormat audioFormat:channel.codec];
	if (audioFormat == nil)
	{
		DDLogError(@"Invalid audio codec: %@", channel.codec);
		return NO;
	}
	
	// defensive ... just in case we were still registered as an observer for a previous session
	if (session)
	{
		[self stopObservingSession];
	}
	
	session = [[RVSipAudioConnection alloc] initWithSipUri:channel.sipUri 
											   audioFormat:audioFormat 
													   pin:channel.pin];
	session.username = [RealityVisionClient instance].userId;
	session.delegate = self;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
				   ^{ 
					   self.connectionStatus = PttChannelConnecting;
					   [session start]; 
				    });
	
	return YES;
}

- (void)disconnect
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
				   ^{
					   if ([session isActive])
					   {
						   self.connectionStatus = PttChannelDisconnecting;
					   }
					   
					   [session stop]; 
					   
					   if (! [session isActive])
					   {
						   self.connectionStatus = PttChannelDisconnected;
					   }
				    });
}

- (void)sendDtmf:(NSUInteger)dtmfCode
{
	[session sendDtmf:dtmfCode];
}


#pragma mark - Talk timeout

- (void)maxTalkTimeout
{
	self.talking = NO;
}


#pragma mark - RVAudioConnectionDelegate

- (void)connectionDidStart:(RVSipAudioConnection *)connection
{
	DDLogInfo(@"connectionDidStart");
	dispatch_async(dispatch_get_main_queue(), 
				   ^{ 
					   [self startObservingSession];
					   self.connectionStatus = PttChannelConnected;
					   [delegate pttCallIsActive:YES]; 
					   AudioServicesPlaySystemSound(connectSound);
				   });
}

- (void)connectionDidStop:(RVSipAudioConnection *)connection
{
	DDLogInfo(@"connectionDidStop");
	dispatch_async(dispatch_get_main_queue(), 
				   ^{
					   [self stopObservingSession];
					   self.connectionStatus = PttChannelDisconnected;
					   [delegate pttCallIsActive:NO]; 
					   AudioServicesPlaySystemSound(disconnectSound);
				    });
}

- (void)connection:(RVSipAudioConnection *)connection didFailWithError:(NSError *)error
{
	DDLogWarn(@"connectionDidFailWithError: %@", [error localizedDescription]);
	dispatch_async(dispatch_get_main_queue(), 
				   ^{ 
					   [self stopObservingSession];
					   self.connectionStatus = PttChannelDisconnected;
					   [delegate pttCallDidFail:error];
					   AudioServicesPlaySystemSound(disconnectSound);
				    });
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"receiveEnabled"])
	{
		BOOL receiveEnabled;
		NSValue * receiveEnabledValue = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (receiveEnabledValue != nil)
		{
			[receiveEnabledValue getValue:&receiveEnabled];
			if (receiveEnabled == muted)
			{
				dispatch_async(dispatch_get_main_queue(), ^{ [self setMuted:(! receiveEnabled)]; });
			}
		}
	}
    else if ([keyPath isEqual:@"transmitEnabled"])
	{
		BOOL transmitEnabled;
		NSValue * transmitEnabledValue = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (transmitEnabledValue != nil)
		{
			[transmitEnabledValue getValue:&transmitEnabled];
			if (transmitEnabled != talking)
			{
				dispatch_async(dispatch_get_main_queue(), ^{ [self setTalking:transmitEnabled]; });
			}
		}
	}
}

- (void)startObservingSession
{
	if (! isObservingSession)
	{
		isObservingSession = YES;
		[session addObserver:self forKeyPath:@"transmitEnabled" options:NSKeyValueObservingOptionNew context:NULL];
		[session addObserver:self forKeyPath:@"receiveEnabled"  options:NSKeyValueObservingOptionNew context:NULL];
	}
}

- (void)stopObservingSession
{
	if (isObservingSession)
	{
		isObservingSession = NO;
		[session removeObserver:self forKeyPath:@"transmitEnabled"];
		[session removeObserver:self forKeyPath:@"receiveEnabled"];
	}
}

@end
