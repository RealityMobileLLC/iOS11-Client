//
//  PushToTalkBar.m
//  Cannonball
//
//  Created by Thomas Aylesworth on 3/23/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import "PushToTalkBar.h"
#import "Reachability.h"
#import "PttChannelInteractions.h"
#import "RVPressGestureRecognizer.h"
#import "RVReleaseGestureRecognizer.h"
#import "UIView+Layout.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface PushToTalkBar ()
@property (nonatomic,strong) NSObject <PttChannelInteractions> * channel;
@end


@implementation PushToTalkBar
{
	UIColor                 * baseTintColor;
	UISegmentedControl      * muteButton;
	UISegmentedControl      * talkButton;
	UISegmentedControl      * channelButton;
	UIActivityIndicatorView * activityIndicator;
	UIImage                 * muteButtonImage;
	UIImage                 * talkButtonImage;
	UIImage                 * channelButtonImage;
	BOOL                      talkButtonToggles;
	NSString                * talkButtonTitle;
	CGFloat                   portraitHeight;
	BOOL                      pttBarHidden;
}

@synthesize delegate;
@synthesize channel;


#pragma mark - Initialization and cleanup

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.backgroundColor = [UIColor colorWithRed:0.482 green:0.576 blue:0.686 alpha:1.0];
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		portraitHeight = MIN(frame.size.height,frame.size.width);
		
		muteButtonImage = [UIImage imageNamed:@"ic_call_mute"];
		talkButtonImage = [UIImage imageNamed:@"ic_speak_now_32px"];
		channelButtonImage = [UIImage imageNamed:@"ic_call_settings_32px"];
		
		muteButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:muteButtonImage, nil]];
		muteButton.segmentedControlStyle = UISegmentedControlStyleBar;
		muteButton.momentary = YES;
		baseTintColor = muteButton.tintColor;
		[muteButton addTarget:self action:@selector(muteWasPressed) forControlEvents:UIControlEventValueChanged];
		muteButton.enabled = NO;
		[self addSubview:muteButton];
		
		talkButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:talkButtonImage, nil]];
		talkButton.segmentedControlStyle = UISegmentedControlStyleBar;
		talkButton.momentary = YES;
		talkButton.enabled = NO;
		[self addSubview:talkButton];
		
		channelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:channelButtonImage, nil]];
		channelButton.segmentedControlStyle = UISegmentedControlStyleBar;
		channelButton.momentary = YES;
		[channelButton addTarget:self action:@selector(channelWasPressed) forControlEvents:UIControlEventValueChanged];
		channelButton.enabled = YES;
		[self addSubview:channelButton];
		
		activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[self addSubview:activityIndicator];
		
		// need to use gesture recognizers to implement both push-to-talk modes (toggle and press-and-hold)
		RVPressGestureRecognizer   * pressRecognizer   = [[RVPressGestureRecognizer alloc] initWithTarget:self 
																								   action:@selector(talkWasPressed)];
		RVReleaseGestureRecognizer * releaseRecognizer = [[RVReleaseGestureRecognizer alloc] initWithTarget:self 
																									 action:@selector(talkWasReleased)];
		[talkButton addGestureRecognizer:pressRecognizer];
		[talkButton addGestureRecognizer:releaseRecognizer];
		
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
	self.delegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)defaultsChanged:(NSNotification *)notification
{
	talkButtonToggles = [[NSUserDefaults standardUserDefaults] boolForKey:@"TalkButtonToggles"];
}


#pragma mark - UIView methods

- (void)layoutSubviews
{
	if (self.bounds.size.width > self.bounds.size.height)
	{
		// layout horizontally
		const CGFloat padx = 10.0;
		const CGFloat pady = 6.0;
		CGFloat width1 = (self.bounds.size.width - 4 * padx) / 4;
		CGFloat width2 = (self.bounds.size.width - 4 * padx) / 2;
		
		CGRect buttonFrame = self.bounds;
		buttonFrame.origin.y += pady + 1;
		buttonFrame.size.height -= pady * 2;
		
		buttonFrame.origin.x = self.bounds.origin.x + padx;
		buttonFrame.size.width = width1;
		muteButton.frame = buttonFrame;
		activityIndicator.frame = muteButton.frame;
		
		buttonFrame.origin.x += width1 + padx;
		buttonFrame.size.width = width2;
		talkButton.frame = buttonFrame;
		
		buttonFrame.origin.x += width2 + padx;
		buttonFrame.size.width = width1;
		channelButton.frame = buttonFrame;
		
		CGFloat maxWidth = talkButton.bounds.size.width - 10;
		[talkButton setImage:[self talkButtonImageWithTitle:talkButtonTitle forWidth:maxWidth] forSegmentAtIndex:0];
	}
	else 
	{
		// layout vertically
		const CGFloat padx = 6.0;
		const CGFloat pady = 10.0;
		CGFloat height1 = (self.bounds.size.height - 4 * pady) / 4;
		CGFloat height2 = (self.bounds.size.height - 4 * pady) / 2;
		
		CGRect buttonFrame = self.bounds;
		buttonFrame.origin.x += padx + 1;
		buttonFrame.size.width -= padx * 2;
		
		buttonFrame.origin.y = self.bounds.origin.y + pady;
		buttonFrame.size.height = height1;
		channelButton.frame = buttonFrame;
		
		buttonFrame.origin.y += height1 + pady;
		buttonFrame.size.height = height2;
		talkButton.frame = buttonFrame;
		
		buttonFrame.origin.y += height2 + pady;
		buttonFrame.size.height = height1;
		muteButton.frame = buttonFrame;
		activityIndicator.frame = muteButton.frame;
		
		[talkButton setImage:talkButtonImage forSegmentAtIndex:0];
	}
}

/*
 *  Sets the pttFrame and adjacentFrame output parameters for the desired interfaceOrientation.
 *  The pttFrame is output only and its value will be overwritten by this method.
 *  The adjacentFrame is input and output and only its size is changed by this method.
 */
- (void)getPttFrame:(CGRect *)pttFrame 
   andAdjacentFrame:(CGRect *)adjacentFrame 
		   inBounds:(CGRect)bounds 
interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	NSAssert(pttFrame,@"pttFrame must be provided");
	NSAssert(adjacentFrame,@"adjacentFrame must be provided");
	
	if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
	{
		adjacentFrame->origin.x    = 0;
		adjacentFrame->size.width  = bounds.size.width;
		adjacentFrame->size.height = bounds.size.height - (pttBarHidden ? 0 : portraitHeight);
		
		*pttFrame = CGRectMake(0, adjacentFrame->size.height, 
							   bounds.size.width, portraitHeight);
	}
	else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight)
	{
		adjacentFrame->origin.x    = 0;
		adjacentFrame->size.width  = bounds.size.width - (pttBarHidden ? 0 : portraitHeight);
		adjacentFrame->size.height = bounds.size.height;
		
		*pttFrame = CGRectMake(adjacentFrame->size.width, 0, 
							   portraitHeight, bounds.size.height);
	}
	else if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
	{
		adjacentFrame->origin.x    = pttBarHidden ? 0 : portraitHeight;
		adjacentFrame->size.width  = bounds.size.width - (pttBarHidden ? 0 : portraitHeight);
		adjacentFrame->size.height = bounds.size.height;
		
		*pttFrame = CGRectMake(adjacentFrame->origin.x - portraitHeight, 0, 
							   portraitHeight, bounds.size.height);
	}
}


#pragma mark - Public methods

- (void)layoutPttBarAndResizeView:(UIView *)adjacentView 
		  forInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	NSAssert(self.superview,@"PushToTalkBar must have a superview");
	NSAssert(adjacentView.superview==self.superview,@"adjacentView and PushToTalkBar must share the same superview");
	
	CGRect newFrame;
	CGRect newAdjacentFrame = adjacentView.frame;
	[self getPttFrame:&newFrame andAdjacentFrame:&newAdjacentFrame 
			 inBounds:self.superview.bounds interfaceOrientation:interfaceOrientation];
	
	self.frame = newFrame;
	adjacentView.frame = newAdjacentFrame;
}

- (void)hide:(BOOL)hidden andResizeView:(UIView *)adjacentView interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
    animated:(BOOL)animated
{
	NSAssert(self.superview,@"PushToTalkBar must have a superview");
	NSAssert(adjacentView.superview==self.superview,@"adjacentView and PushToTalkBar must share the same superview");
	
	if (pttBarHidden == hidden)
		return;
	
	// if ptt bar was hidden, go ahead and show it now before animating it into view
	if (self.hidden) 
		self.hidden = NO;
	
	pttBarHidden = hidden;
	
	CGRect newFrame;
	CGRect newAdjacentFrame = adjacentView.frame;
	
	[self getPttFrame:&newFrame andAdjacentFrame:&newAdjacentFrame 
			 inBounds:self.superview.bounds interfaceOrientation:interfaceOrientation];
	
	if (animated)
	{
		[UIView animateWithDuration:0.3 
						 animations:^{ self.frame = newFrame; adjacentView.frame = newAdjacentFrame; }
						 completion:^(BOOL finished){ self.hidden = pttBarHidden; }];
	}
	else 
	{
		self.frame = newFrame; 
		adjacentView.frame = newAdjacentFrame;
	}
}

- (void)resetTalkButton
{
	if ((! self.hidden) && (! talkButtonToggles) && (channel.talking))
	{
		[self talkWasReleased];
	}
}

- (void)setHidden:(BOOL)hidden
{
	pttBarHidden = hidden;
	[super setHidden:hidden];
}

- (BOOL)enabled
{
	return channelButton.enabled;
}

- (void)setEnabled:(BOOL)enabled
{
	channelButton.enabled = enabled;
}

- (void)setDelegate:(NSObject<PushToTalkBarDelegate> *)newDelegate
{
	if (delegate == newDelegate)
		return;
	
	[delegate removeObserver:self forKeyPath:@"channel"];
	delegate = newDelegate;
	[delegate addObserver:self forKeyPath:@"channel" options:NSKeyValueObservingOptionNew context:NULL];
	self.channel = delegate.channel;
}

- (void)setChannel:(NSObject<PttChannelInteractions> *)newChannel
{
	[self stopObservingCurrentChannel];
	
	channel = newChannel;
	if (channel == nil)
	{
		[self noChannelJoined];
	}
	else 
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

- (void)channelWasPressed
{
	[delegate pttBarChannelButtonPressed];
}

- (void)setTalkButtonTitle:(NSString *)title
{
	talkButtonTitle = title;
	
	// only update button image with title in portrait orientation
	if (self.frame.size.width > self.frame.size.height)
	{
		CGFloat maxWidth = talkButton.bounds.size.width - 10;
		[talkButton setImage:[self talkButtonImageWithTitle:talkButtonTitle forWidth:maxWidth] forSegmentAtIndex:0];
	}
}


#pragma mark - Connection status methods

- (void)noChannelJoined
{
	NSAssert(channel==nil,@"noChannelJoined can only be called if channel property is nil");
	DDLogInfo(@"PushToTalkBar noChannelJoined");
	muteButton.enabled = NO;
	talkButton.enabled = NO;
	[self setMuted:NO];
	[self setTalking:NO];
	[self setTalkButtonTitle:NSLocalizedString(@"Off",@"No Push To Talk channel joined")];
	[self showActivity:NO];
}

- (void)channelDisconnected
{
	if (channel == nil)
		return;
	
	DDLogInfo(@"PushToTalkBar channelDisconnected");
	muteButton.enabled = NO;
	talkButton.enabled = NO;
	[self setMuted:NO];
	[self setTalking:NO];
	[self setTalkButtonTitle:channel.channelName];
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
	[self setTalkButtonTitle:channel.channelName];
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
	[self setTalkButtonTitle:NSLocalizedString(@"Connecting",@"Connecting")];
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
	[self setTalkButtonTitle:NSLocalizedString(@"Disconnecting",@"Disconnecting")];
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
	[channel addObserver:self
			  forKeyPath:@"connectionStatus"
				 options:NSKeyValueObservingOptionNew
				 context:NULL];
	
	[channel addObserver:self forKeyPath:@"talking" options:NSKeyValueObservingOptionNew context:NULL];
	[channel addObserver:self forKeyPath:@"muted"   options:NSKeyValueObservingOptionNew context:NULL];
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
	self.enabled = (networkStatus != NotReachable);
}

- (void)logReachability:(Reachability *)networkReachability
{
	NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
	NSString * statusString = (networkStatus == NotReachable)     ? @"Not Reachable" :
	                          (networkStatus == ReachableViaWiFi) ? @"WiFi"
	                                                              : @"WWAN";
	DDLogVerbose(@"PushToTalkBar network status is %@", statusString);
}


#pragma mark - Private methods

- (UIImage *)talkButtonImageWithTitle:(NSString *)title forWidth:(CGFloat)maxWidth
{
	// calculate size of image and title
	const CGFloat pad = 3;
	UIFont * font = [UIFont systemFontOfSize:12];
	CGSize imageSize = CGSizeMake(24, 24);
	CGSize nameSize = [title sizeWithFont:font forWidth:maxWidth lineBreakMode:UILineBreakModeTailTruncation];
	CGSize newImageSize = CGSizeMake(MAX(imageSize.width, nameSize.width), imageSize.height + nameSize.height + pad);
	
	// create a graphics context
	UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [UIScreen mainScreen].scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// draw the image
	CGFloat imageX = CENTER(newImageSize.width, imageSize.width);
	CGRect imageRect = CGRectMake(imageX, 0, imageSize.height, imageSize.width);
	[talkButtonImage drawInRect:imageRect];
	
	// draw the title
	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	CGFloat nameX = CENTER(newImageSize.width, nameSize.width);
	CGPoint nameOrigin = CGPointMake(nameX, imageSize.height + pad);
	[title drawAtPoint:nameOrigin forWidth:maxWidth withFont:font lineBreakMode:UILineBreakModeTailTruncation];
	
	// get the combined image and title
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end
