//
//  PushToTalkController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "PushToTalkController.h"
#import "Reachability.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "PttChannel.h"
#import "PttChannelManager.h"
#import "PushToTalkCall.h"
#import "RVMediaError.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

// define to have the current PTT channel deselected when unable to connect
//#define RV_PTT_DESELECTS_CHANNEL_ON_FAILURE


@interface PushToTalkController ()
@property (nonatomic,strong) NSObject<PttChannelInteractions> * channel;
@end


@implementation PushToTalkController
{
	PushToTalkCall   * pttCall;    // always set this via setChannel: so that observers are notified
	UIViewController * channelSelectionPresenter;
	BOOL               monitoringNetwork;
	BOOL               reconnect;
	BOOL               didPresentChannelSelection;
}


#pragma mark - Initialization and cleanup

static PushToTalkController * instance;

+ (PushToTalkController *)instance
{
	if (instance == nil)
	{
		instance = [[PushToTalkController alloc] init];
	}
	return instance;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		// register for state changes in realityvision client
		[[RealityVisionClient instance] addObserver:self
										 forKeyPath:@"isSignedOn"
											options:NSKeyValueObservingOptionNew
											context:NULL];
	}
	return self;
}


#pragma mark - Properties

- (NSObject<PttChannelInteractions> *)channel
{
	return pttCall;
}

- (void)setChannel:(NSObject<PttChannelInteractions> *)channel
{
	NSAssert((channel==nil)||[channel isKindOfClass:[PushToTalkCall class]],@"Channel must be a PushToTalkCall object");
	pttCall = (PushToTalkCall *)channel;
}


#pragma mark - PushToTalkBarDelegate

- (void)pttBarChannelButtonPressed
{
	[self showChannelSelectionViewController];
}


#pragma mark - Push-To-Talk call state updates

- (void)pttCallIsActive:(BOOL)active
{
	if (active)
	{
		DDLogVerbose(@"PushToTalkController pttCallIsActive:YES");
#ifdef RV_PTT_DESELECTS_CHANNEL_ON_FAILURE
		reconnect = NO;
#endif
	}
	else 
	{
		DDLogVerbose(@"PushToTalkController pttCallIsActive:NO");
		if (reconnect && [RealityVisionClient instance].networkStatus != NotReachable)
		{
			DDLogVerbose(@"PushToTalkController attempting reconnect");
			[pttCall connect];
		}
	}
}

- (void)pttCallDidFail:(NSError *)error
{
	NSString * innerError;
	
	if ([error.domain isEqualToString:RVMediaErrorDomain] && error.code == RVMediaErrorSipInviteFailed)
	{
		innerError = [[error userInfo] objectForKey:RVMediaSipMessageKey];
	}
	else 
	{
		innerError = [error localizedDescription];
	}
	
	DDLogError(@"PushToTalkController pttCallDidFail: unable to connect to %@ at %@: %@", 
			   pttCall.channel.name, pttCall.channel.sipUri, innerError);
	
	NSString * errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Unable to connect to %@: %@",
																		   @"Unable to connect to PTT channel error message format"),
							   pttCall.channel.name, innerError];
	
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Connect",
																			   @"Cannot connect to PTT channel error title") 
													 message:errorMessage 
													delegate:nil 
										   cancelButtonTitle:@"OK" 
										   otherButtonTitles:nil];
	[alert show];
	
#ifdef RV_PTT_DESELECTS_CHANNEL_ON_FAILURE
	if (! reconnect)
	{
		DDLogVerbose(@"PushToTalkController pttCallDidFail: deselecting channel due to failure and reconnect = NO");
		[self deselectChannel];
	}
#endif
}


#pragma mark - Channel selection

- (void)showChannelSelectionViewController
{
	PttChannelSelectViewController * viewController = 
		[[PttChannelSelectViewController alloc] initWithAvailableChannels:[PttChannelManager instance].channels 
														  selectedChannel:[PttChannelManager instance].selectedChannel];
	viewController.showCancelButton = YES;
	viewController.delegate = self;
	
	UIViewController * topViewController = [RealityVisionAppDelegate rootViewController].navigationController.topViewController;
	UIViewController * activeModal = topViewController.presentedViewController;
	
	channelSelectionPresenter = (activeModal == nil) ? topViewController : activeModal;
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	[channelSelectionPresenter presentViewController:navigationController animated:YES completion:NULL];
	didPresentChannelSelection = YES;
}

- (void)hideChannelSelectionViewController
{
	[channelSelectionPresenter dismissViewControllerAnimated:YES completion:NULL];
	channelSelectionPresenter = nil;
	didPresentChannelSelection = NO;
}

- (void)pttChannelSelectionCancelled
{
	[self hideChannelSelectionViewController];
}

- (void)pttChannelSelected:(NSString *)channelName
{
	if (didPresentChannelSelection)
	{
		[self hideChannelSelectionViewController];
	}
	
	if (pttCall.channel != nil)
	{
		// leave existing channel 
		[self leavePttChannel];
	}
	
	[PttChannelManager instance].selectedChannel = channelName;
	
	if (channelName != nil)
	{
		// get new channel endpoint
		NSURL * callConfigurationUrl = [ConfigurationManager instance].systemUris.messagingAndRouting;
		CallConfigurationService * callConfigurationService = [[CallConfigurationService alloc] initWithUrl:callConfigurationUrl];
		callConfigurationService.delegate = self;
		[callConfigurationService getSipEndpointForChannel:channelName];
	}
}

- (void)onGetSipEndpointResult:(SipEndPoint *)endpoint error:(NSError *)error
{
	if ((endpoint == nil) && (error == nil))
	{
		error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the channel's endpoint."];
	}
	
	if (error)
	{
		NSString * errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Unable to connect to %@: %@",
																			   @"Unable to get PTT endpoint error message format"),
								   [PttChannelManager instance].selectedChannel, [error localizedDescription]];
		
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Connect",
																				   @"Could not get PTT endpoint title") 
														 message:errorMessage 
														delegate:nil 
											   cancelButtonTitle:NSLocalizedString(@"OK",@"OK") 
											   otherButtonTitles: nil];
		[alert show];
		[PttChannelManager instance].selectedChannel = nil;
		return;
	}
	
	NSString * protocol = ([endpoint.endpoint rangeOfString:@"transport=tls"].location == NSNotFound) ? @"sip" : @"sips";
	NSString * address = [NSString stringWithFormat:@"%@:%@",protocol,endpoint.endpoint];
	PttChannel * pttChannel = [[PttChannel alloc] initWithName:[PttChannelManager instance].selectedChannel 
													   address:address
														 codec:endpoint.codec 
														   pin:endpoint.pin];
	[self joinPttChannel:pttChannel];
}

- (void)joinPttChannel:(PttChannel *)channel
{
	self.channel = [[PushToTalkCall alloc] initWithChannel:channel];
	pttCall.delegate = self;
	[pttCall connect];
	[self startNetworkMonitoring];
}

- (void)leavePttChannel
{
	[pttCall disconnect];
	[self deselectChannel];
}

- (void)deselectChannel
{
	[PttChannelManager instance].selectedChannel = nil;
	self.channel = nil;
	[self stopNetworkMonitoring];
}


#pragma mark - Network reachability monitoring

- (void)startNetworkMonitoring
{
	if (! monitoringNetwork)
	{
		monitoringNetwork = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(networkReachabilityChanged:)
													 name:kReachabilityChangedNotification 
												   object:nil];
	}
}

- (void)stopNetworkMonitoring
{
	if (monitoringNetwork)
	{
		monitoringNetwork = NO;
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
}

- (void)networkReachabilityChanged:(NSNotification *)notification
{
	NSParameterAssert([[notification object] isKindOfClass:[Reachability class]]);
	
	if (self.channel == nil)
		return;
	
	NetworkStatus networkStatus = [(Reachability *)[notification object] currentReachabilityStatus];
	[self logNetworkStatus:networkStatus];
	
	reconnect = (networkStatus != NotReachable);
	if (pttCall.connectionStatus != PttChannelDisconnected && pttCall.connectionStatus != PttChannelDisconnecting)
	{
		// disconnect from channel and attempt to reconnect on new network, if available
		DDLogInfo(@"PushToTalkController networkReachabilityChanged: disconnecting from call; reconnect = %@",
					 reconnect ? @"YES" : @"NO");
		[pttCall disconnect];
	}
	else if (reconnect && pttCall.connectionStatus != PttChannelConnected && pttCall.connectionStatus != PttChannelConnecting)
	{
		// we regained our network connection so try to reconnect
		DDLogInfo(@"PushToTalkController networkReachabilityChanged: reconnecting");
		[pttCall connect];
	}
}

- (void)logNetworkStatus:(NetworkStatus)networkStatus
{
	NSString * statusString = (networkStatus == NotReachable)     ? @"Not Reachable" :
	                          (networkStatus == ReachableViaWiFi) ? @"WiFi"
	                                                              : @"WWAN";
	DDLogVerbose(@"PushToTalkController network status is %@", statusString);
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"isSignedOn"]) 
	{
		BOOL isSignedOn;
		NSValue * isSignedOnValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (isSignedOnValue != nil)
		{
			[isSignedOnValue getValue:&isSignedOn];
			
			if (! isSignedOn)
			{
				[self leavePttChannel];
			}
		}
    }
}

@end
