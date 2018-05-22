//
//  WatchOptionsView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum
{
	WO_ShowVideo,
	WO_ShowMapFullScreen,
	WO_ShowMapHalfScreen,
	WO_ShowCommentsFullScreen,
	WO_ShowCommentsHalfScreen
} WatchOptions;


@protocol WatchOptionsDelegate <NSObject>

@property (nonatomic,readonly) BOOL canShowMap;

@property (nonatomic,readonly) BOOL canShowComments;

- (void)showVideoFullScreen;

- (void)showMapFullScreen:(BOOL)fullScreen;

- (void)showCommentsFullScreen:(BOOL)fullScreen;

@end


@interface WatchOptionsView : UIView

@property (nonatomic,weak) id <WatchOptionsDelegate> delegate;

@property (nonatomic) WatchOptions selectedOption;

- (id)init;

- (id)initWithSelectedOption:(WatchOptions)selected;

@end
