//
//  VideoControlsView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/19/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  Protocol used to notify delegate when the user selects a video control.
 */
@protocol VideoControlsDelegate

/**
 *  Used to notify the delegate that the user wants the video to play 
 *  starting at the given offset.
 */
- (void)playFromTimeOffset:(NSTimeInterval)offset andRemainPaused:(BOOL)remainPaused;

/**
 *  Used to notify the delegate that the user wants to switch back to a
 *  live feed.
 */
- (void)playLiveFeedAndRemainPaused:(BOOL)remainPaused;

/**
 *  Used to notify the delegate that the user selected the Pause button.
 */
- (void)pause;

@end


/**
 *  View with video playback information and controls.
 */
@interface VideoControlsView : UIView 

/**
 *  Delegate to notify when the user selects a video control.
 */
@property (nonatomic,weak) id <VideoControlsDelegate> delegate;

/**
 *  Whether the video is playing or paused.
 */
@property (nonatomic) BOOL isPlaying;

/**
 *  The total playback time of the video in seconds.
 */
@property (nonatomic) NSTimeInterval totalTime;

/**
 *  The time offset of the current frame in seconds.
 */
@property (nonatomic) NSTimeInterval currentTime;

/**
 *  Specifies whether the Rewind button should be enabled.
 */
- (void)enableRewindButton:(BOOL)enable;

/**
 *  Specifies whether the Forward button should be enabled.
 */
- (void)enableForwardButton:(BOOL)enable;

/**
 *  Specifies whether the Live button should be shown or hidden.
 */
- (void)showLiveButton:(BOOL)showLiveButton;

@end
