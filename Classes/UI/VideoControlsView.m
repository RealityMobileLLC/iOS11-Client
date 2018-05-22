//
//  VideoControlsView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/19/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "VideoControlsView.h"
#import "NSString+RealityVision.h"
#import "UIView+Layout.h"

static const NSTimeInterval JumpTimeInterval = 5.0;


@implementation VideoControlsView
{
	UIImageView    * backgroundImageView;
	UIButton       * playPauseButton;
	UIButton       * rewindButton;
	UIButton       * forwardButton;
    UIButton       * liveButton;
	UILabel        * currentTimeLabel;
	UILabel        * totalTimeLabel;
	UISlider       * progressView;
	NSTimeInterval   currentTime;
	NSTimeInterval   totalTime;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithFrame:(CGRect)frame 
{
	UIImage * background = [UIImage imageNamed:@"video_controls_background"];
	
	static const CGFloat controlWidth   =  32.0;
	static const CGFloat controlHeight  =  32.0;
	static const CGFloat controlY       =  13.0;
	static const CGFloat progressWidth  = 188.0;
	static const CGFloat progressHeight =  23.0;
	static const CGFloat labelWidth     =  50.0;
	static const CGFloat labelHeight    =  21.0;
	static const CGFloat labelPad       =   6.0;
	
	CGFloat width      = background.size.width;
	CGFloat height     = background.size.height;
	CGFloat lineHeight = background.size.height / 2.0;
	
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, width, height)];
    if (self != nil) 
	{
		currentTime = 0;
		totalTime = 0;
		
		self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
		                        UIViewAutoresizingFlexibleRightMargin | 
		                        UIViewAutoresizingFlexibleTopMargin;
		
		backgroundImageView = [[UIImageView alloc] initWithImage:background];
		backgroundImageView.frame = self.bounds;
		[self addSubview:backgroundImageView];
		
		playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[playPauseButton setImage:[UIImage imageNamed:@"video_play"]  forState:UIControlStateNormal];
		[playPauseButton setImage:[UIImage imageNamed:@"video_pause"] forState:UIControlStateSelected];
		playPauseButton.frame = CGRectMake(134.0, controlY, controlWidth, controlHeight);
		[playPauseButton addTarget:self action:@selector(playPausePressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:playPauseButton];
		
		rewindButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[rewindButton setImage:[UIImage imageNamed:@"video_rewind"] forState:UIControlStateNormal];
		rewindButton.frame = CGRectMake(86.0, controlY, controlWidth, controlHeight);
		[rewindButton addTarget:self action:@selector(rewindPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:rewindButton];
		
		forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[forwardButton setImage:[UIImage imageNamed:@"video_forward"] forState:UIControlStateNormal];
		forwardButton.frame = CGRectMake(182.0, controlY, controlWidth, controlHeight);
		[forwardButton addTarget:self action:@selector(forwardPressed) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:forwardButton];
		
		progressView = [[UISlider alloc] initWithFrame:CGRectMake(CENTER(background.size.width,progressWidth),
																  CENTER(lineHeight,progressHeight) + lineHeight, 
																  progressWidth, 
																  progressHeight)];
		progressView.continuous = NO;
		[progressView addTarget:self action:@selector(progressChanged) forControlEvents:UIControlEventValueChanged];
		[self addSubview:progressView];
		
		currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 
																	 CENTER(lineHeight, labelHeight) + lineHeight, 
																	 labelWidth, 
																	 labelHeight)];
		currentTimeLabel.textAlignment = UITextAlignmentRight;
		currentTimeLabel.textColor = [UIColor whiteColor];
		currentTimeLabel.backgroundColor = [UIColor clearColor];
		currentTimeLabel.text = @"0:00";
		[self addSubview:currentTimeLabel];
		
		totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(progressView.frame.origin.x + progressView.frame.size.width + labelPad, 
																   CENTER(lineHeight, labelHeight) + lineHeight, 
																   labelWidth, 
																   labelHeight)];
		totalTimeLabel.textColor = [UIColor whiteColor];
		totalTimeLabel.backgroundColor = [UIColor clearColor];
		totalTimeLabel.text = @"0:00";
		[self addSubview:totalTimeLabel];
        
        liveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [liveButton setTitle:NSLocalizedString(@"Live",@"Video controls Live button") forState:UIControlStateNormal];
        liveButton.frame = CGRectMake(232.0, controlY, 60.0, controlHeight);
        [liveButton addTarget:self action:@selector(livePressed) forControlEvents:UIControlEventTouchUpInside];
        liveButton.hidden = YES;
        [self addSubview:liveButton];
	}
    return self;
}


#pragma mark - Properties

- (BOOL)isPlaying
{
	return playPauseButton.selected;
}

- (void)setIsPlaying:(BOOL)isPlaying
{
	playPauseButton.selected = isPlaying;
}

- (NSTimeInterval)totalTime
{
	return totalTime;
}

- (void)setTotalTime:(NSTimeInterval)newTotalTime
{
	totalTime = newTotalTime;
	totalTimeLabel.text = [NSString stringForTimeInterval:totalTime];
	totalTimeLabel.hidden = (totalTime <= FLT_EPSILON);
	progressView.maximumValue = totalTime;
}

- (NSTimeInterval)currentTime
{
	return currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)newCurrentTime
{
	currentTime = newCurrentTime;
	currentTimeLabel.text = [NSString stringForTimeInterval:currentTime];
	progressView.value = currentTime;
}

- (void)enableRewindButton:(BOOL)enable
{
    rewindButton.enabled = enable;
}

- (void)enableForwardButton:(BOOL)enable
{
    forwardButton.enabled = enable;
}

- (void)showLiveButton:(BOOL)showLiveButton
{
    liveButton.hidden = ! showLiveButton;
}


#pragma mark - Button actions

- (void)playPausePressed
{
	if (self.isPlaying)
	{
		[self.delegate pause];
	}
	else 
	{
		[self.delegate playFromTimeOffset:currentTime andRemainPaused:NO];
	}
}

- (void)rewindPressed
{
	[self.delegate playFromTimeOffset:MAX(currentTime-JumpTimeInterval,0) andRemainPaused:(! self.isPlaying)];
}

- (void)forwardPressed
{
	[self.delegate playFromTimeOffset:MIN(currentTime+JumpTimeInterval,totalTime-1) andRemainPaused:(! self.isPlaying)];
}

- (void)progressChanged
{
	[self.delegate playFromTimeOffset:progressView.value andRemainPaused:(! self.isPlaying)];
}

- (void)livePressed
{
    [self.delegate playLiveFeedAndRemainPaused:NO];
}

@end
