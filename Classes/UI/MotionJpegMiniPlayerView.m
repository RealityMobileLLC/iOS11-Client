//
//  MotionJpegMiniPlayerView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/7/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "MotionJpegMiniPlayerView.h"
#import "CameraInfoWrapper.h"
#import "MotionJpegStream.h"
#import "UIView+Layout.h"
#import "RootViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

// a border around the background image so that the close and share buttons can extend outside of it
static const CGFloat kInvisibleBorder = 12.0;


@implementation MotionJpegMiniPlayerView
{
	CLLocationCoordinate2D lastViewerCoordinate;
	CGPoint                offset;
	MotionJpegStream     * stream;
	BOOL                   streamIsClosing;
	UIImageView          * backgroundImageView;
	UIImageView          * cameraImageView;
	MKMapView            * mapView;
}

@synthesize delegate;
@synthesize camera;
@synthesize viewer;
@synthesize mapAnnotationView;


#pragma mark - Initialization and cleanup

- (id)initWithCamera:(CameraInfoWrapper *)theCamera
		   forViewer:(NSObject<MapObject> *)theViewer
   mapAnnotationView:(MKAnnotationView *)theAnnotationView
			   onMap:(MKMapView *)theMapView
{
	static const CGFloat imageWidth  = 160.0;
	static const CGFloat imageHeight = 120.0;
	static const CGFloat arrowHeight =  20.0;
	static const CGFloat labelHeight =  12.0;
	static const CGFloat labelPad    =   2.0;
	
	UIImage * background = [UIImage imageNamed:@"video_popover"];
	lastViewerCoordinate = theViewer.coordinate;
	offset = CGPointMake(-0.5, -theAnnotationView.frame.size.height + 8.0);
	CGPoint viewerPoint = [theMapView convertCoordinate:lastViewerCoordinate toPointToView:theMapView];
    
	// note that changes to the formula used to create the frame must also be made in updateLocation
	CGFloat selectedYOffset = [theAnnotationView isSelected] ? -52 : 0;
	CGRect frame = CGRectMake(viewerPoint.x + offset.x - background.size.width / 2.0 - kInvisibleBorder,
							  viewerPoint.y + offset.y - background.size.height + selectedYOffset - kInvisibleBorder,
							  background.size.width + kInvisibleBorder * 2.0, 
							  background.size.height + kInvisibleBorder);
	
	CGRect cameraImageFrame = CGRectMake(CENTER(frame.size.width, imageWidth), 
										 CENTER(background.size.height-arrowHeight-labelHeight-labelPad,imageHeight)+kInvisibleBorder,
										 imageWidth, 
										 imageHeight);
	
	CGRect labelFrame = CGRectMake(cameraImageFrame.origin.x, 
								   cameraImageFrame.origin.y + imageHeight + labelPad, 
								   cameraImageFrame.size.width, 
								   labelHeight);
	
    self = [super initWithFrame:frame];
	if (self != nil) 
	{
		self.autoresizingMask = UIViewAutoresizingNone;
		
		backgroundImageView = [[UIImageView alloc] initWithImage:background];
        backgroundImageView.frame = CGRectMake(kInvisibleBorder, kInvisibleBorder, background.size.width, background.size.height);
		[self addSubview:backgroundImageView];
		
		cameraImageView = [[UIImageView alloc] initWithFrame:cameraImageFrame];
		cameraImageView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:cameraImageView];
		
		UIButton * closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[closeButton setImage:[UIImage imageNamed:@"close_button"] forState:UIControlStateNormal];
		closeButton.frame = CGRectMake(-4, -4, 32, 32);
		[self addSubview:closeButton];
        
        UIButton * shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareButton setImage:[UIImage imageNamed:@"share_button"] forState:UIControlStateNormal];
        shareButton.frame = CGRectMake(frame.size.width - 28, -4, 32, 32);
        [self addSubview:shareButton];
		
		UILabel * cameraLabel = [[UILabel alloc] initWithFrame:labelFrame];
		cameraLabel.text = theCamera.name;
		cameraLabel.font = [UIFont systemFontOfSize:11.0];
		cameraLabel.textAlignment = UITextAlignmentCenter;
		cameraLabel.textColor = [UIColor whiteColor];
		cameraLabel.backgroundColor = [UIColor clearColor];
		[self addSubview:cameraLabel];
		
		camera = theCamera;
		viewer = theViewer;
		mapAnnotationView = theAnnotationView;
		mapView = theMapView;
		
		[mapAnnotationView addObserver:self forKeyPath:@"selected"   options:NSKeyValueObservingOptionNew context:NULL];
		[viewer            addObserver:self forKeyPath:@"coordinate" options:NSKeyValueObservingOptionNew context:NULL];
		
		[self openStream];
		if ((stream != nil) && (! stream.isClosed))
		{
			// set watching status on server
			[[RealityVisionClient instance] startWatchSession];
		}
		
		UIGestureRecognizer * gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
		[closeButton addGestureRecognizer:gesture];
        
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shareVideo:)];
        [shareButton addGestureRecognizer:gesture];
		
		gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullScreen:)];
		[self addGestureRecognizer:gesture];
        
        gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shareVideo:)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

- (void)dealloc
{
	[self closeStream];
	[mapAnnotationView removeObserver:self forKeyPath:@"selected"];
	[viewer            removeObserver:self forKeyPath:@"coordinate"];
}


#pragma mark - Public properties

- (void)updateLocation
{
	if (RVLocationCoordinate2DIsValid(viewer.coordinate))
	{
		lastViewerCoordinate = viewer.coordinate;
	}
	
	CGPoint viewerPoint = [mapView convertCoordinate:lastViewerCoordinate toPointToView:mapView];
	CGFloat selectedYOffset = [mapAnnotationView isSelected] ? -52 : 0;
	self.frame  = CGRectMake(viewerPoint.x + offset.x - backgroundImageView.image.size.width / 2.0 - kInvisibleBorder,
							 viewerPoint.y + offset.y - backgroundImageView.image.size.height + selectedYOffset - kInvisibleBorder,
							 backgroundImageView.image.size.width + kInvisibleBorder * 2.0,
							 backgroundImageView.image.size.height + kInvisibleBorder);
}


#pragma mark - MotionJpegStreamDelegate methods

- (void)didGetImage:(UIImage *)image 
		   location:(CLLocation *)location 
			   time:(NSDate *)timestamp 
		  sessionId:(int)sessionId 
			frameId:(int)frameId
{
	cameraImageView.image = image;
}

- (void)didGetSession:(Session *)session
{
	// ignore session data for video in popover - currently popovers don't support archive feeds
}

- (void)streamDidEnd
{
    // if the stream ended because we are closing it, don't do anything
	if (streamIsClosing)
    {
        return;
    }
    
    if (camera.isVideoServerFeed)
    {
        // stop playback of video server feeds
        [self dismiss:nil];
    }
    else
    {
        // retry non-video server feeds
		stream.delegate = nil;
		stream = nil;
        [self openStream];
    }
}

- (void)streamClosedWithError:(NSError *)error
{
	// stream is closed but still needs cleaning up
	[self closeStream];
	
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to View Camera",@"Unable to view camera title")
													 message:[error localizedDescription]
													delegate:nil
										   cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
										   otherButtonTitles:nil];
	[alert show];
	[delegate dismissVideoPlayer:self];
}


#pragma mark - Gesture callbacks

- (void)dismiss:(id)sender
{
	[self closeStream];
	[delegate dismissVideoPlayer:self];
}

- (void)showFullScreen:(id)sender
{
	// @todo we need a way to pause and restart mini-players when the map disappears / reappears
	//[self dismiss:sender];
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	RootViewController * rootViewController = (RootViewController *)appDelegate.rootViewController;
	[rootViewController showVideo:camera];
}

- (void)shareVideo:(id)sender
{
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	RootViewController * rootViewController = (RootViewController *)appDelegate.rootViewController;
	[rootViewController shareVideo:camera fromView:self];
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
    if ([keyPath isEqualToString:@"selected"] || [keyPath isEqualToString:@"coordinate"])
	{
		[self updateLocation];
    }
}


#pragma mark - Private methods

- (void)openStream
{
    @synchronized(self)
    {
        NSAssert(stream==nil,@"Stream already exists");
        NSAssert(!streamIsClosing,@"Stream is not finished closing");
		
        DDLogInfo(@"MotionJpegMiniPlayerView: Requesting camera feed at %@", camera.sourceUrl);
        stream = [[MotionJpegStream alloc] initWithUrl:camera.sourceUrl];
        stream.delegate = self;
        stream.allowCredentials = ! camera.isDirect;
        
        NSError * error = nil;
        if (! [stream open:&error])
        {
            NSString * errorMsg = [NSString stringWithFormat:@"Error opening motion jpeg stream: %@", error];
            [self streamClosedWithError:[RvError rvErrorWithLocalizedDescription:errorMsg]];
            stream.delegate = nil;
            stream = nil;
        }
    }
}

- (void)closeStream
{
    @synchronized(self)
    {
        // streamIsClosing is used to prevent reentrancy ... calling [stream close] can result in this being called again
        if ((stream != nil) && (! streamIsClosing))
        {
            DDLogInfo(@"MotionJpegMiniPlayerView: Closing camera feed at %@", camera.sourceUrl);
            streamIsClosing = YES;
            
			if (! stream.isClosed)
            {
                [stream close];
            }
            
            // turn off watching status on server
            [[RealityVisionClient instance] stopWatchSession];
            stream.delegate = nil;
            stream = nil;
            streamIsClosing = NO;
        }
    }
}

@end
