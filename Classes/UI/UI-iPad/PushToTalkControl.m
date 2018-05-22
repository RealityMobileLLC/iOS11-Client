//
//  PushToTalkControl.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "PushToTalkControl.h"
#import "Reachability.h"
#import "PttChannelInteractions.h"
#import "PushToTalkController.h"
#import "RVPressGestureRecognizer.h"
#import "RVReleaseGestureRecognizer.h"
#import "UIView+Layout.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// define to snap the control to one of the four corners after dragging
//#define RV_PTT_CONTROL_SNAPS_TO_CORNER


static const CGFloat kTopPadding        = 32;
static const CGFloat kButtonOuterHeight = 46;
static const CGFloat kButtonOuterWidth  = 52;
static const CGFloat kButtonInnerHeight = 40;
static const CGFloat kButtonInnerWidth  = 40;


#ifdef RV_PTT_CONTROL_SNAPS_TO_CORNER
// location of control within superview
enum 
{
	kPCTop         = 0,
	kPCLeft        = 0,
	kPCBottom      = 0x01,
	kPCRight       = 0x10,
	kPCTopLeft     = kPCTop | kPCLeft,
	kPCBottomLeft  = kPCBottom | kPCLeft,
	kPCTopRight    = kPCTop | kPCRight,
	kPCBottomRight = kPCBottom | kPCRight
};
#endif


@implementation PushToTalkControl
{
	UIColor                 * baseTintColor;
	UISegmentedControl      * muteButton;
	UISegmentedControl      * talkButton;
	UIActivityIndicatorView * activityIndicator;
	UIImage                 * muteButtonImage;
	UIImage                 * talkButtonImage;
	BOOL                      talkButtonToggles;
#ifdef RV_PTT_CONTROL_SNAPS_TO_CORNER
	NSUInteger                controlLocation;
#else
	BOOL                      anchorLeft;        // indicates whether control is on left or right
#endif
	CGRect                    currentFrame;      // used for dragging
}

@synthesize channel;


- (id)initWithSuperview:(UIView *)superview;
{
#ifdef RV_PTT_CONTROL_SNAPS_TO_CORNER
	controlLocation = kPCBottomLeft;
#else
	anchorLeft = YES;
#endif
	
	currentFrame = [self frameForCurrentLocationInSuperview:superview yOffset:0 initialFrame:YES];
    self = [super initWithFrame:currentFrame];
    if (self) 
	{
		//self.backgroundColor = [UIColor colorWithRed:0.75 green:0.76 blue:0.80 alpha:1.0];
		UIImage * background = [UIImage imageNamed:@"ptt_control_background"];
		UIImageView * backgroundView = [[UIImageView alloc] initWithImage:background];
		[self addSubview:backgroundView];
		
		muteButtonImage = [UIImage imageNamed:@"ic_call_mute"];
		talkButtonImage = [UIImage imageNamed:@"ic_speak_now_32px"];
		
		muteButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:muteButtonImage, nil]];
		muteButton.frame = CGRectMake(CENTER(kButtonOuterWidth, kButtonInnerWidth), 
									  kTopPadding, 
									  kButtonInnerWidth, 
									  kButtonInnerHeight);
		muteButton.segmentedControlStyle = UISegmentedControlStyleBar;
		muteButton.momentary = YES;
		baseTintColor = muteButton.tintColor;
		[muteButton addTarget:self action:@selector(muteWasPressed) forControlEvents:UIControlEventValueChanged];
		muteButton.enabled = NO;
		[self addSubview:muteButton];
		
		talkButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:talkButtonImage, nil]];
		talkButton.frame = CGRectMake(CENTER(kButtonOuterWidth, kButtonInnerWidth), 
									  kTopPadding + kButtonOuterHeight, 
									  kButtonInnerWidth, 
									  kButtonInnerHeight);
		talkButton.segmentedControlStyle = UISegmentedControlStyleBar;
		talkButton.momentary = YES;
		talkButton.enabled = NO;
		[self addSubview:talkButton];
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityIndicator.frame = muteButton.frame;
		[self addSubview:activityIndicator];
		
		// need to use gesture recognizers to implement both push-to-talk modes (toggle and press-and-hold)
		RVPressGestureRecognizer   * pressRecognizer   = [[RVPressGestureRecognizer alloc] initWithTarget:self 
																								   action:@selector(talkWasPressed)];
		RVReleaseGestureRecognizer * releaseRecognizer = [[RVReleaseGestureRecognizer alloc] initWithTarget:self 
																									 action:@selector(talkWasReleased)];
		[talkButton addGestureRecognizer:pressRecognizer];
		[talkButton addGestureRecognizer:releaseRecognizer];
		[superview addSubview:self];
		
		// add a pan gesture recognizer to allow the user to drag the control
		UIPanGestureRecognizer * dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self 
																						  action:@selector(controlDragged:)];
		[self addGestureRecognizer:dragRecognizer];
		
		// add a tap gesture recognizer solely to prevent taps from being sent to other controls
		UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlTapped:)];
		tapRecognizer.numberOfTapsRequired = 2;
		[self addGestureRecognizer:tapRecognizer];
		
		PushToTalkController * pttController = [PushToTalkController instance];
		self.channel = pttController.channel;
		[pttController addObserver:self forKeyPath:@"channel" options:NSKeyValueObservingOptionNew context:NULL];
		
		// get preferences from user defaults and register for change notifications
		talkButtonToggles = [[NSUserDefaults standardUserDefaults] boolForKey:@"TalkButtonToggles"];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(defaultsChanged:)
													 name:NSUserDefaultsDidChangeNotification
												   object:nil];
		
		// monitor network availability to disable buttons when no network
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(networkReachabilityChanged:)
													 name:kReachabilityChangedNotification 
												   object:nil];
		
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)defaultsChanged:(NSNotification *)notification
{
	talkButtonToggles = [[NSUserDefaults standardUserDefaults] boolForKey:@"TalkButtonToggles"];
}

- (void)layoutSubviews
{
	if (self.superview)
	{
		self.frame = currentFrame = [self frameForCurrentLocationInSuperview:self.superview yOffset:0 initialFrame:NO];
	}
}

- (CGRect)frameForCurrentLocationInSuperview:(UIView *)superview yOffset:(CGFloat)deltaY initialFrame:(BOOL)initialFrame
{
	const CGFloat xOffset = 25;
	const CGFloat yOffset = 25;
	
	CGFloat w = kButtonOuterWidth;
	CGFloat h = kButtonOuterHeight * 2 + kTopPadding;
	
#ifdef RV_PTT_CONTROL_SNAPS_TO_CORNER
	CGFloat x = (controlLocation & kPCRight)  == 0 ? xOffset : superview.bounds.size.width - w - xOffset;
	CGFloat y = (controlLocation & kPCBottom) == 0 ? yOffset : superview.bounds.size.height - h - yOffset * 2;
#else
	CGFloat x = anchorLeft ? xOffset : superview.bounds.size.width - w - xOffset;
	CGFloat maxY = superview.bounds.size.height - h - yOffset * 2;
	CGFloat y = initialFrame ? maxY : MIN(MAX(self.frame.origin.y + deltaY, yOffset), maxY);
#endif
	
	return CGRectMake(x, y, w, h);
}


#pragma mark - Public methods

- (void)setChannel:(NSObject<PttChannelInteractions> *)newChannel
{
	[self stopObservingCurrentChannel];
	
	channel = newChannel;
	self.hidden = (channel == nil);
	
	if (channel)
	{
		[self updateChannelState:channel.connectionStatus];
	}
	
	[self startObservingCurrentChannel];
}

- (void)showActivity:(BOOL)showActivity
{
	if (showActivity)
	{
		[muteButton setImage:nil forSegmentAtIndex:0];
		[activityIndicator startAnimating];
	}
	else 
	{
		[muteButton setImage:muteButtonImage forSegmentAtIndex:0];
		[activityIndicator stopAnimating];
	}
}

- (void)setMuted:(BOOL)muted
{
	muteButton.tintColor = (muted) ? [UIColor orangeColor] : baseTintColor;
}

- (void)setTalking:(BOOL)talking
{
	talkButton.tintColor = (talking) ? [UIColor colorWithRed:0.0 green:0.7 blue:0.0 alpha:1.0] : baseTintColor;
}

- (void)resetTalkButton
{
	if ((! self.hidden) && (! talkButtonToggles) && (channel.talking))
	{
		[self talkWasReleased];
	}
}


#pragma mark - Button actions

- (void)muteWasPressed
{
	NSAssert(channel,@"Mute button should be disabled when not connected");
	channel.muted = ! channel.muted;
}

- (void)talkWasPressed
{
	NSAssert(channel.connectionStatus==PttChannelConnected,@"Talk button should be disabled when not connected");
	channel.talking = (talkButtonToggles) ? (! channel.talking) : YES;
}

- (void)talkWasReleased
{
	NSAssert(channel.connectionStatus==PttChannelConnected,@"Talk button should be disabled when not connected");
	if (! talkButtonToggles)
	{
		channel.talking = NO;
	}
}

- (IBAction)controlTapped:(UITapGestureRecognizer *)sender
{
	// don't do anything ... we just want to prevent the tap from being forwarded to other views
}

- (IBAction)controlDragged:(UIPanGestureRecognizer *)sender 
{
    CGPoint translate = [sender translationInView:self.superview];
	
    CGRect newFrame = currentFrame;
    newFrame.origin.x += translate.x;
    newFrame.origin.y += translate.y;
    self.frame = newFrame;
	
    if (sender.state == UIGestureRecognizerStateEnded)
	{
#ifdef RV_PTT_CONTROL_SNAPS_TO_CORNER
		BOOL snapToRight = (newFrame.origin.x > self.superview.bounds.size.width / 2);
		BOOL snapToBottom = (newFrame.origin.y > self.superview.bounds.size.height / 2);
		controlLocation = (snapToRight ? kPCRight : kPCLeft) | (snapToBottom ? kPCBottom : kPCTop);
#else
		anchorLeft = (newFrame.origin.x <= self.superview.bounds.size.width / 2);
#endif
		
		// while animating, keep the control moving along the y axis based on its current velocity
		const NSTimeInterval animationDuration = 0.3;
		CGPoint dragVelocity = [sender velocityInView:self.superview];
		CGFloat animationYDelta = [self deltaForVelocity:dragVelocity.y duringTime:animationDuration];
		CGRect snapToFrame = [self frameForCurrentLocationInSuperview:self.superview yOffset:animationYDelta initialFrame:NO];
		
		[UIView animateWithDuration:animationDuration 
						 animations:^{ self.frame = currentFrame = snapToFrame; } 
						 completion:NULL];
	}
}

- (CGFloat)deltaForVelocity:(CGFloat)velocity duringTime:(NSTimeInterval)duration
{
	CGFloat absoluteDistance = fabs(velocity) * duration;
	
	if (absoluteDistance <= 1 + FLT_EPSILON)
		return absoluteDistance;
	
	CGFloat sign = (velocity < 0) ? -1 : 1;
	CGFloat delta = sqrtf(absoluteDistance * 10) * sign;
	return delta;
}


#pragma mark - Connection status methods

- (void)channelDisconnected
{
	if (channel == nil)
		return;
	
	DDLogInfo(@"PushToTalkBar channelDisconnected");
	muteButton.enabled = NO;
	talkButton.enabled = NO;
	[self setMuted:NO];
	[self setTalking:NO];
	[self showActivity:NO];
}

- (void)channelConnected
{
	if (channel == nil)
		return;
	
	DDLogInfo(@"PushToTalkBar channelConnected");
	muteButton.enabled = YES;
	talkButton.enabled = YES;
	[self setMuted:channel.muted];
	[self setTalking:channel.talking];
	[self showActivity:NO];
}

- (void)channelConnecting
{
	if (channel == nil)
		return;
	
	DDLogInfo(@"PushToTalkBar channelConnecting");
	muteButton.enabled = NO;
	talkButton.enabled = NO;
	[self setMuted:NO];
	[self setTalking:NO];
	[self showActivity:YES];
}

- (void)channelDisconnecting
{
	if (channel == nil)
		return;
	
	DDLogInfo(@"PushToTalkBar channelDisconnecting");
	muteButton.enabled = NO;
	talkButton.enabled = NO;
	[self setMuted:NO];
	[self setTalking:NO];
	[self showActivity:YES];
}

- (void)updateChannelState:(PttChannelStatus)connectState
{
	switch (connectState) 
	{
		case PttChannelDisconnected:
		{
			dispatch_async(dispatch_get_main_queue(), ^{ [self channelDisconnected]; });
			break;
		}
			
		case PttChannelConnected:
		{
			dispatch_async(dispatch_get_main_queue(), ^{ [self channelConnected]; });
			break;
		}
			
		case PttChannelConnecting:
		{
			dispatch_async(dispatch_get_main_queue(), ^{ [self channelConnecting]; });
			break;
		}	
			
		case PttChannelDisconnecting:
		{
			dispatch_async(dispatch_get_main_queue(), ^{ [self channelDisconnecting]; });
			break;
		}
			
		default:
			DDLogError(@"PushToTalkBar unknown connection state: %d", connectState);
			break;
	}
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if ([keyPath isEqual:@"channel"])
	{
		id channelValue = [change objectForKey:NSKeyValueChangeNewKey];
		self.channel = [channelValue isKindOfClass:[NSNull class]] ? nil : channelValue;
	}
	else if ([keyPath isEqual:@"connectionStatus"]) 
	{
		PttChannelStatus newConnectState;
		NSValue * connectionStatusValue = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (connectionStatusValue != nil)
		{
			[connectionStatusValue getValue:&newConnectState];
			[self updateChannelState:newConnectState];
		}
    }
    else if ([keyPath isEqual:@"muted"]) 
	{
		BOOL isMuted;
		NSValue * isMutedValue = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (isMutedValue != nil)
		{
			[isMutedValue getValue:&isMuted];
			dispatch_async(dispatch_get_main_queue(), ^{ [self setMuted:isMuted]; });
		}
	}
    else if ([keyPath isEqual:@"talking"]) 
	{
		BOOL isTalking;
		NSValue * isTalkingValue = [change objectForKey:NSKeyValueChangeNewKey];
		
		if (isTalkingValue != nil)
		{
			[isTalkingValue getValue:&isTalking];
			dispatch_async(dispatch_get_main_queue(), ^{ [self setTalking:isTalking]; });
		}
	}
}

- (void)startObservingCurrentChannel
{
	[channel addObserver:self forKeyPath:@"connectionStatus" options:NSKeyValueObservingOptionNew context:NULL];
	[channel addObserver:self forKeyPath:@"talking"          options:NSKeyValueObservingOptionNew context:NULL];
	[channel addObserver:self forKeyPath:@"muted"            options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)stopObservingCurrentChannel
{
	[channel removeObserver:self forKeyPath:@"connectionStatus"];
	[channel removeObserver:self forKeyPath:@"talking"];
	[channel removeObserver:self forKeyPath:@"muted"];
}


#pragma mark - Network reachability monitoring

- (void)networkReachabilityChanged:(NSNotification *)notification
{
	NSParameterAssert([[notification object] isKindOfClass:[Reachability class]]);
	[self logReachability:(Reachability *)[notification object]];
	
	Reachability * networkReachability = (Reachability *)[notification object];
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	// @todo self.enabled = (networkStatus != NotReachable);
}

- (void)logReachability:(Reachability *)networkReachability
{
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	NSString * statusString = (networkStatus == NotReachable)     ? @"Not Reachable" :
	                          (networkStatus == ReachableViaWiFi) ? @"WiFi"
	                                                              : @"WWAN";
	DDLogVerbose(@"PushToTalkBar network status is %@", statusString);
}

@end
