//
//  WatchOptionsView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "WatchOptionsView.h"
#import "UIView+Layout.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// specify whether to use tap or swipe gesture to activate
#define RV_WATCH_OPTIONS_USES_TAP_GESTURE


static const CGFloat kActivatedY = 1;
static const CGFloat kBorder = 6;
static const CGFloat kPad = 2;
static const CGFloat kButtonSize = 48;
static const CGFloat kActivateButtonWidth = 60;
static const CGFloat kActivateButtonHeight = 32;
static const CGFloat kFirstRowY = kBorder;
static const CGFloat kSecondRowY = kFirstRowY + kButtonSize + kPad;
static const CGFloat kControlsWidth = (kButtonSize * 5) + (kPad * 4) + (kBorder * 2);
static const CGFloat kControlsHeight = kSecondRowY + kButtonSize + kBorder;


@implementation WatchOptionsView
{
	UIImageView * background;
	UIImageView * activateButton;
	UIView      * controlsView;
	UIImageView * showVideoButton;
	UIImageView * showMapFullScreenButton;
	UIImageView * showMapHalfScreenButton;
	UIImageView * showCommentsFullScreenButton;
	UIImageView * showCommentsHalfScreenButton;
	UIImageView * selectionIndicator;
	BOOL          activated;
}

@synthesize delegate;
@synthesize selectedOption;


- (id)init
{
	CGRect frame = CGRectMake(0, kActivatedY, kControlsWidth, kControlsHeight + kActivateButtonHeight);
    self = [super initWithFrame:frame];
    if (self) 
	{
		background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_background"] 
									   highlightedImage:[UIImage imageNamed:@"viewer_display_setting_background_3_btn"]];
		background.opaque = NO;
		background.contentMode = UIViewContentModeTop;
		background.userInteractionEnabled = YES;
		
		activateButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_settings_more"] 
										   highlightedImage:[UIImage imageNamed:@"viewer_display_settings_less"]];
		activateButton.frame = CGRectMake(CENTER(background.bounds.size.width, kActivateButtonWidth), 
										  background.bounds.size.height, 
										  kActivateButtonWidth, 
										  kActivateButtonHeight);
		activateButton.userInteractionEnabled = YES;
		
#ifdef RV_WATCH_OPTIONS_USES_TAP_GESTURE
		[activateButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(toggleActivate:)]];
#else
		UISwipeGestureRecognizer * activateGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
																										 action:@selector(activate:)];
		activateGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
		
		UISwipeGestureRecognizer * dismissGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
																										action:@selector(dismiss:)];
		dismissGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
		
		[activateButton addGestureRecognizer:activateGestureRecognizer];
		[activateButton addGestureRecognizer:dismissGestureRecognizer];
#endif
		
		controlsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kControlsWidth, kControlsHeight)];
		controlsView.backgroundColor = [UIColor clearColor];
		controlsView.opaque = NO;
		
		selectionIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_btn_selected"]];
		selectionIndicator.userInteractionEnabled = YES;
		
		showVideoButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_video"]];
		showVideoButton.userInteractionEnabled = YES;
		[showVideoButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					  action:@selector(showVideoFullScreen:)]];
		
		showMapHalfScreenButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_map_video"]];
		showMapHalfScreenButton.userInteractionEnabled = YES;
		[showMapHalfScreenButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																							  action:@selector(showMapHalfScreen:)]];
		
		showMapFullScreenButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_map"]];
		showMapFullScreenButton.userInteractionEnabled = YES;
		[showMapFullScreenButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																							  action:@selector(showMapFullScreen:)]];
		
		showCommentsHalfScreenButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_comments_video"]];
		showCommentsHalfScreenButton.userInteractionEnabled = YES;
		[showCommentsHalfScreenButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																								   action:@selector(showCommentsHalfScreen:)]];
		
		showCommentsFullScreenButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewer_display_setting_comments"]];
		showCommentsFullScreenButton.userInteractionEnabled = YES;
		[showCommentsFullScreenButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																								   action:@selector(showCommentsFullScreen:)]];
		
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		
		[self addSubview:background];
		[self addSubview:activateButton];
		[self addSubview:controlsView];
		[controlsView addSubview:selectionIndicator];
		[controlsView addSubview:showVideoButton];
    }
    return self;
}

- (id)initWithSelectedOption:(WatchOptions)selected
{
	self = [self init];
	if (self)
	{
		selectedOption = selected;
	}
	return self;
}

- (void)layoutSubviews
{
	self.frame = CGRectMake(self.frame.origin.x, 
							activated ? kActivatedY : -background.bounds.size.height, 
							self.frame.size.width, 
							self.frame.size.height);
	
	CGFloat x = kBorder;
	showVideoButton.frame = CGRectMake(x, kFirstRowY, kButtonSize, kButtonSize);
	
	if (delegate.canShowMap)
	{
		if (showMapHalfScreenButton.superview == nil)
		{
			[controlsView addSubview:showMapHalfScreenButton];
			[controlsView addSubview:showMapFullScreenButton];
		}
		
		x += kButtonSize + kPad;
		showMapHalfScreenButton.frame = CGRectMake(x, kSecondRowY, kButtonSize, kButtonSize);
		
		x += kButtonSize + kPad;
		showMapFullScreenButton.frame = CGRectMake(x, kFirstRowY, kButtonSize, kButtonSize);
	}
	
	if (delegate.canShowComments)
	{
		if (showCommentsHalfScreenButton.superview == nil)
		{
			[controlsView addSubview:showCommentsHalfScreenButton];
			[controlsView addSubview:showCommentsFullScreenButton];
		}
		
		x += kButtonSize + kPad;
		showCommentsHalfScreenButton.frame = CGRectMake(x, kSecondRowY, kButtonSize, kButtonSize);
		
		x += kButtonSize + kPad;
		showCommentsFullScreenButton.frame = CGRectMake(x, kFirstRowY, kButtonSize, kButtonSize);
	}
	
	CGRect newControlsFrame = controlsView.frame;
	newControlsFrame.size.width = x + kButtonSize + kBorder;
	newControlsFrame.origin.x = CENTER(self.frame.size.width, newControlsFrame.size.width);
	controlsView.frame = newControlsFrame;
	
	// use either the 3-button or 5-button version of the background depending on the number of controls
	background.highlighted = (newControlsFrame.size.width < kControlsWidth);
	
	// the first time we're called, initialize the selection indicator frame
	if (selectionIndicator.frame.origin.x == 0)
	{
		self.selectedOption = self.selectedOption;
	}
}

- (void)setSelectedOption:(WatchOptions)theSelectedOption
{
	selectedOption = theSelectedOption;
	[self updateSelectionIndicatorFrame];
}

#ifdef RV_WATCH_OPTIONS_USES_TAP_GESTURE
- (void)toggleActivate:(UIGestureRecognizer *)sender
{
	activated = ! activated;
	[self animateActivateOrDismiss];
}
#else
- (void)activate:(UIGestureRecognizer *)sender
{
	if (! activated)
	{
		activated = YES;
		[self animateActivateOrDismiss];
	}
}

- (void)dismiss:(UIGestureRecognizer *)sender
{
	if (activated)
	{
		activated = NO;
		[self animateActivateOrDismiss];
	}
}
#endif

- (void)animateActivateOrDismiss
{
	CGRect newFrame = CGRectMake(self.frame.origin.x, 
								 activated ? kActivatedY : -background.bounds.size.height, 
								 self.frame.size.width, 
								 self.frame.size.height);
	
	[UIView animateWithDuration:0.3 
					 animations:^{ self.frame = newFrame; } 
					 completion:^(BOOL finished){ activateButton.highlighted = activated; }];
}

- (void)showVideoFullScreen:(UIGestureRecognizer *)sender
{
	selectedOption = WO_ShowVideo;
	[self animateSelectionIndicatorFrame:showVideoButton.frame];
	[delegate showVideoFullScreen];
}

- (void)showMapHalfScreen:(UIGestureRecognizer *)sender
{
	selectedOption = WO_ShowMapHalfScreen;
	[self animateSelectionIndicatorFrame:showMapHalfScreenButton.frame];
	[delegate showMapFullScreen:NO];
}

- (void)showMapFullScreen:(UIGestureRecognizer *)sender
{
	selectedOption = WO_ShowMapFullScreen;
	[self animateSelectionIndicatorFrame:showMapFullScreenButton.frame];
	[delegate showMapFullScreen:YES];
}

- (void)showCommentsHalfScreen:(UIGestureRecognizer *)sender
{
	selectedOption = WO_ShowCommentsHalfScreen;
	[self animateSelectionIndicatorFrame:showCommentsHalfScreenButton.frame];
	[delegate showCommentsFullScreen:NO];
}

- (void)showCommentsFullScreen:(UIGestureRecognizer *)sender
{
	selectedOption = WO_ShowCommentsFullScreen;
	[self animateSelectionIndicatorFrame:showCommentsFullScreenButton.frame];
	[delegate showCommentsFullScreen:YES];
}

- (void)animateSelectionIndicatorFrame:(CGRect)newFrame
{
	[UIView animateWithDuration:0.2 
					 animations:^{ selectionIndicator.frame = newFrame; } 
					 completion:NULL];	
}

- (void)updateSelectionIndicatorFrame
{
	switch (selectedOption) 
	{
		case WO_ShowVideo:
			selectionIndicator.frame = showVideoButton.frame;
			break;
			
		case WO_ShowMapHalfScreen:
			selectionIndicator.frame = showMapHalfScreenButton.frame;
			break;
			
		case WO_ShowMapFullScreen:
			selectionIndicator.frame = showMapFullScreenButton.frame;
			break;
			
		case WO_ShowCommentsHalfScreen:
			selectionIndicator.frame = showCommentsHalfScreenButton.frame;
			break;
			
		case WO_ShowCommentsFullScreen:
			selectionIndicator.frame = showCommentsFullScreenButton.frame;
			break;
			
		default:
			DDLogError(@"WatchOptionsView setSelectedOption: invalid option %d", selectedOption);
			selectedOption = WO_ShowVideo;
			selectionIndicator.frame = showVideoButton.frame;
			break;
	}
}

@end
