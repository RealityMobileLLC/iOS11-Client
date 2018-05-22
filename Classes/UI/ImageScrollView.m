//
//  ImageScrollView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ImageScrollView.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ImageScrollView
{
    UIImageView * imageView;
	float         zoomScaleToFit;
	float         zoomTapMedium;
	float         zoomTapMax;
}

@synthesize doubleTapGesture;


#pragma mark - Initialization and cleanup

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
    if (self != nil) 
	{
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor blackColor];
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.maximumZoomScale = 3.0;
        self.delegate = self;
		
		zoomScaleToFit = 1.0;
		zoomTapMedium = 1.0;
		zoomTapMax = 2.0;
		
		doubleTapGesture = [self addTapGestureAction:@selector(zoomOnTap:) 
											  toView:self 
												taps:2 
											 touches:1];
	}
    return self;
}


#pragma mark - View lifecycle

- (void)layoutSubviews 
{
    [super layoutSubviews];
	
	if (imageView != nil)
	{
		// reset zoom for new bounds
		[self resetMinimumZoomScale];
		
		// center the image as it becomes smaller than the size of the screen
		CGSize boundsSize = self.bounds.size;
		CGRect frameToCenter = imageView.frame;
		
		frameToCenter.origin.x = (frameToCenter.size.width < boundsSize.width)   ? (boundsSize.width  - frameToCenter.size.width)  / 2 : 0;
		frameToCenter.origin.y = (frameToCenter.size.height < boundsSize.height) ? (boundsSize.height - frameToCenter.size.height) / 2 : 0;
		
		imageView.frame = frameToCenter;
	}
}


#pragma mark - UIScrollView delegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}


#pragma mark - Public methods

- (UIImage *)image
{
	return (imageView == nil) ? nil : imageView.image;
}

- (void)setImage:(UIImage *)image
{
	if (imageView == nil)
	{
		// first time we've received an image so create a view for it
		imageView = [[UIImageView alloc] initWithImage:image];
		imageView.userInteractionEnabled = YES;
		
		// add to scroll view
		self.contentSize = imageView.frame.size;
		[self addSubview:imageView];
		
		// set zoom to fit image to screen
		[self resetMinimumZoomScale];
		self.zoomScale = self.minimumZoomScale;
	}
	else 
	{
		imageView.image = image;
	}
}

- (void)toggleZoom
{
	if (imageView != nil)
	{
		if (self.zoomScale < zoomTapMedium * 0.9)
		{
			self.zoomScale = zoomTapMedium;
		}
		else if (self.zoomScale < zoomTapMax * 0.9)
		{
			self.zoomScale = zoomTapMax;
		}
		else 
		{
			self.zoomScale = self.minimumZoomScale;
		}
	}
}

- (void)resetMinimumZoomScale
{
	BOOL wasAtMinimumZoom = self.zoomScale <= self.minimumZoomScale + FLT_EPSILON;
	
	// find scaling value needed to fit image inside scrollview frame
	zoomScaleToFit = MIN(self.bounds.size.width  / imageView.image.size.width, 
						 self.bounds.size.height / imageView.image.size.height);
	
	// if image is smaller than scrollview frame, allow it to be viewed in original size
	self.minimumZoomScale = MIN(zoomScaleToFit, 1.0);
	zoomTapMedium = MAX(zoomScaleToFit, 1.0);
	
	if (wasAtMinimumZoom)
	{
		self.zoomScale = self.minimumZoomScale;
	}
}


#pragma mark - Private methods

- (UIGestureRecognizer *)addTapGestureAction:(SEL)action 
									  toView:(UIView *)theView 
										taps:(NSUInteger)taps 
									 touches:(NSUInteger)touches
{
	UITapGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self 
																				action:action];
	gesture.numberOfTapsRequired = taps;
	gesture.numberOfTouchesRequired = touches;
	[theView addGestureRecognizer:gesture];
	return gesture;
}

- (void)zoomOnTap:(UIGestureRecognizer *)gestureRecognizer
{
	[self toggleZoom];
}

@end
