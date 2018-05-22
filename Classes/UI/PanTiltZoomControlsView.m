//
//  PanTiltZoomControlsView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "PanTiltZoomControlsView.h"
#import "UIView+Layout.h"
#import "CameraInfoWrapper.h"
#import "WebService.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation PanTiltZoomControlsView
{
	UIImageView * panLeftButton;
	UIImageView * panRightButton;
	UIImageView * tiltUpButton;
	UIImageView * tiltDownButton;
	UIImageView * homeButton;
	UIImageView * zoomInButton;
	UIImageView * zoomOutButton;
	
	UIImageView * panLeftGlowButton;
	UIImageView * panRightGlowButton;
	UIImageView * tiltUpGlowButton;
	UIImageView * tiltDownGlowButton;
	UIImageView * homeGlowButton;
	UIImageView * zoomInGlowButton;
	UIImageView * zoomOutGlowButton;
}

@synthesize camera;
@synthesize hideControlsTimerDelegate;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		
		panLeftButton  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_left"]];
		panRightButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_right"]];
		tiltUpButton   = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_up"]];
		tiltDownButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_down"]];
		homeButton     = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_center"]];
		zoomInButton   = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zoom_in"]];
		zoomOutButton  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zoom_out"]];
		
		panLeftButton.userInteractionEnabled  = YES;
		panRightButton.userInteractionEnabled = YES;
		tiltUpButton.userInteractionEnabled   = YES;
		tiltDownButton.userInteractionEnabled = YES;
		homeButton.userInteractionEnabled     = YES;
		zoomInButton.userInteractionEnabled   = YES;
		zoomOutButton.userInteractionEnabled  = YES;
		
		[panLeftButton  addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(panCameraLeft:)]];
		[panRightButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(panCameraRight:)]];
		[tiltUpButton   addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(tiltCameraUp:)]];
		[tiltDownButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(tiltCameraDown:)]];
		[homeButton     addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(centerCamera:)]];
		[zoomInButton   addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(zoomCameraIn:)]];
		[zoomOutButton  addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self 
																					 action:@selector(zoomCameraOut:)]];
		
		[self addSubview:panLeftButton];
		[self addSubview:panRightButton];
		[self addSubview:tiltUpButton];
		[self addSubview:tiltDownButton];
		[self addSubview:homeButton];
		[self addSubview:zoomInButton];
		[self addSubview:zoomOutButton];
		
		panLeftGlowButton  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_left_glow"]];
		panRightGlowButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_right_glow"]];
		tiltUpGlowButton   = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_up_glow"]];
		tiltDownGlowButton = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_down_glow"]];
		homeGlowButton     = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"directional_center_glow"]];
		zoomInGlowButton   = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zoom_in_glow"]];
		zoomOutGlowButton  = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"zoom_out_glow"]];
		
		panLeftGlowButton.hidden  = YES;
		panRightGlowButton.hidden = YES;
		tiltUpGlowButton.hidden   = YES;
		tiltDownGlowButton.hidden = YES;
		homeGlowButton.hidden     = YES;
		zoomInGlowButton.hidden   = YES;
		zoomOutGlowButton.hidden  = YES;
		
		[self addSubview:panLeftGlowButton];
		[self addSubview:panRightGlowButton];
		[self addSubview:tiltUpGlowButton];
		[self addSubview:tiltDownGlowButton];
		[self addSubview:homeGlowButton];
		[self addSubview:zoomInGlowButton];
		[self addSubview:zoomOutGlowButton];
    }
    return self;
}

- (void)layoutSubviews
{
//	CGRect ptzFrame = self.navigationController.topViewController.view.frame;
//	
//	if (self.navigationController.toolbar.hidden)
//	{
//		// accommodate the nav bar and toolbar when they are shown
//		ptzFrame.size.height -= (self.navigationController.toolbar.bounds.size.height + self.navigationController.navigationBar.bounds.size.height);
//	}
//	
//	ptzView.frame = ptzFrame;
	
	const CGFloat kTopBorder = 32;
	const CGFloat kBottomBorder = 16;
	const CGFloat kPtzButtonSize = 32;
	
	panLeftButton.frame = panLeftGlowButton.frame =
		CGRectMake(0, 
				   CENTER(self.bounds.size.height, kPtzButtonSize), 
				   kPtzButtonSize, 
				   kPtzButtonSize);
	
	panRightButton.frame = panRightGlowButton.frame =
		CGRectMake(self.bounds.size.width - kPtzButtonSize, 
				   CENTER(self.bounds.size.height, kPtzButtonSize), 
				   kPtzButtonSize, 
				   kPtzButtonSize);
	
	tiltUpButton.frame = tiltUpGlowButton.frame =
		CGRectMake(CENTER(self.bounds.size.width, kPtzButtonSize), 
				   kTopBorder, 
				   kPtzButtonSize, 
				   kPtzButtonSize);
	
	tiltDownButton.frame = tiltDownGlowButton.frame =
		CGRectMake(CENTER(self.bounds.size.width, kPtzButtonSize), 
				   self.bounds.size.height - kPtzButtonSize - kBottomBorder, 
				   kPtzButtonSize, 
				   kPtzButtonSize);
	
	homeButton.frame = homeGlowButton.frame =
		CGRectMake(CENTER(self.bounds.size.width, kPtzButtonSize), 
				   CENTER(self.bounds.size.height, kPtzButtonSize), 
				   kPtzButtonSize, 
				   kPtzButtonSize);
		
	zoomInButton.frame = zoomInGlowButton.frame =
		CGRectMake(0, 
				   self.bounds.size.height - kPtzButtonSize - kBottomBorder, 
				   kPtzButtonSize, 
				   kPtzButtonSize);
	
	zoomOutButton.frame = zoomOutGlowButton.frame = 
		CGRectMake(self.bounds.size.width - kPtzButtonSize,
				   self.bounds.size.height - kPtzButtonSize - kBottomBorder, 
				   kPtzButtonSize, 
				   kPtzButtonSize);
}


#pragma mark - Button callbacks

- (void)panCameraLeft:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"pan left");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_LEFT]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:panLeftGlowButton];
}

- (void)panCameraRight:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"pan right");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_RIGHT]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:panRightGlowButton];
}

- (void)tiltCameraUp:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"tilt up");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_UP]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:tiltUpGlowButton];
}

- (void)tiltCameraDown:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"tilt down");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_DOWN]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:tiltDownGlowButton];
}

- (void)centerCamera:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"center");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_HOME]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:homeGlowButton];
}

- (void)zoomCameraIn:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"zoom in");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_ZOOM_IN]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:zoomInGlowButton];
}

- (void)zoomCameraOut:(UIGestureRecognizer *)gestureRecognizer 
{
	DDLogVerbose(@"zoom out");
	[self sendPtzToUrl:[camera panTiltZoomUrl:PTZ_ZOOM_OUT]];
	[hideControlsTimerDelegate resetControlsTimer];
    [self highlightPtzButton:zoomOutGlowButton];
}


#pragma mark - Private methods

- (void)highlightPtzButton:(UIView *)button
{
    button.alpha = 1.0;
    button.hidden = NO;
    
    [UIView animateWithDuration:1.0
                          delay:0.0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{ button.alpha = 0.0; }
                     completion:^(BOOL finished){ button.hidden = YES; }];
}

- (void)sendPtzToUrl:(NSURL *)url
{
	DDLogVerbose(@"ptz: %@", url);
	
	NSURLRequest * request = [NSURLRequest requestWithURL:url 
                                              cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
                                          timeoutInterval:60];
	
	WebService * httpConnection = [[WebService alloc] init];
	[httpConnection doHttpRequest:request];
}

@end
