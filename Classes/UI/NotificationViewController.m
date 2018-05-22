//
//  NotificationViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/5/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "NotificationViewController.h"
#import "UILabel+Layout.h"
#import "UIView+Layout.h"
#import "MotionJpegMapViewController.h"
#import "CommandWrapper.h"
#import "Command.h"
#import "CommandResponseType.h"
#import "DirectiveType.h"
#import "Attachment.h"
#import "AttachmentPurposeType.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "Recipient.h"
#import "ClientTransaction.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static const NSInteger kOverlaySwitchLabelTag = 100;


@implementation NotificationViewController
{
	DownloadManager * downloadManager;
	
	// subview used to display command icon and info
	UIView * commandInfoView;
	
	// text message subviews
	UITextView  * messageTextView;
	UIImageView * imageView;
	UIImageView * overlayImageView;
	UISwitch    * showOverlaySwitch;
	
	// download subviews
	UIActivityIndicatorView         * activityIndicator;
	UIProgressView                  * progressIndicator;
	UIDocumentInteractionController * documentController;
}

@synthesize command;
@synthesize scrollView;
@synthesize toFromLabel;
@synthesize toFromNamesLabel;
@synthesize sentLabel;
@synthesize sentTimeLabel;
@synthesize bodyView;


#pragma mark - Initialization and cleanup

- (void)createToolbarItems
{
	NSAssert(self.command,@"Command property must be set before toolbar is created");
	
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
	
	// determine whether command requires a response
	if (self.command.requiresResponse)
	{
		// currently YES/NO is the only supported response type
		if (self.command.command.responseType.value == CR_YesNo)
		{
            static const CGFloat BUTTON_WIDTH = 70.0;
            
			[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																			target:nil 
																			action:NULL]];
			
			UIBarButtonItem * button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Yes",@"Yes") 
																		 style:UIBarButtonItemStyleBordered 
																		target:self 
																		action:@selector(didSelectYes:)];
			button1.width = BUTTON_WIDTH;
			[items addObject:button1];
			
			[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																			target:nil 
																			action:NULL]];
			
			
			UIBarButtonItem * button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"No",@"No") 
																		 style:UIBarButtonItemStyleBordered 
																		target:self 
																		action:@selector(didSelectNo:)];
			button2.width = BUTTON_WIDTH;
			[items addObject:button2];
			
			[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																			target:nil 
																			action:NULL]];
		}
	}
			
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		if ([items count] == 0)
		{
			[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																			target:nil 
																			action:NULL]];
		}
		
		UIBarButtonItem * homeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home",@"Home button") 
																		style:UIBarButtonItemStyleBordered 
																	   target:[RealityVisionAppDelegate rootViewController] 
																	   action:@selector(showRootView)];
		[items addObject:homeButton];
	}
	
    if ([items count] > 0)
    {
        self.toolbarItems = items;
    }
}

- (void)dealloc
{
	// @todo ios5 can remove this and get rid of downloadManager in viewDidDisappear
	downloadManager.delegate = nil;
	[downloadManager cancel];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	NSAssert(self.command!=nil,@"NotificationViewController requires a command to display");
	
	DDLogVerbose(@"NotificationViewController viewDidLoad");
    [super viewDidLoad];
	
    if (self.command.isSentCommand)
    {
        self.title = NSLocalizedString(@"Command Details",@"Command Details");
        self.toFromLabel.text = @"To:";
        self.toFromNamesLabel.text = [Recipient stringWithRecipients:self.command.sortedRecipients];
    }
    else
    {
        self.title = NSLocalizedString(@"Command Notification",@"Command Notification");
        self.toFromLabel.text = @"From:";
        self.toFromNamesLabel.text = self.command.senderName;
    }
    
	self.sentTimeLabel.text = self.command.eventTimeString;
    [self createBodyView];
	[self createToolbarItems];
	
	// register for new command notifications so we can dismiss this view controller
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(willDisplayCommandNotification:) 
												 name:RvWillDisplayCommandNotification 
											   object:nil];
	
	if (! self.command.requiresResponse)
	{
		// no response required so auto-accept command
		[self executeCommand];
	}
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"NotificationViewController viewDidUnload");
    [super viewDidUnload];
	scrollView = nil;
    toFromLabel = nil;
	toFromNamesLabel = nil;
    sentLabel = nil;
	sentTimeLabel = nil;
	bodyView = nil;
	commandInfoView = nil;
	messageTextView = nil;
	imageView = nil;
	overlayImageView = nil;
	showOverlaySwitch = nil;
	activityIndicator = nil;
    progressIndicator = nil;
	documentController = nil;
	
	// @todo ios5 can remove this and get rid of downloadManager in viewDidDisappear
	downloadManager.delegate = nil;
	[downloadManager cancel];
	downloadManager = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"NotificationViewController viewWillAppear");
	[super viewDidAppear:animated];
    [self layoutViewForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"NotificationViewController viewDidAppear");
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"NotificationViewController viewWillDisappear");
	[super viewWillDisappear:animated];
	
	// @todo ios5 can get rid of downloadmanager here if view is being popped
	//downloadManager.delegate = nil;
	//[downloadManager cancel];
	//downloadManager = nil;
	
	if (! command.wasAccepted)
	{
		[command dismiss];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self layoutViewForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)layoutViewForInterfaceOrientation:(UIInterfaceOrientation)newOrientation
{
    // since recipients can be > 1 line, resize label and relayout view if necessary
    CGFloat delta = [self.toFromNamesLabel resizeHeightToFitText];
    if (fabs(delta) > FLT_EPSILON)
    {
        [self.sentLabel     moveOriginYBy:delta];
        [self.sentTimeLabel moveOriginYBy:delta];
        [self.bodyView      moveOriginYBy:delta];
    }
        
    // The dimensions of bodyView during 'createBodyView' didn't take orientation into account
    [messageTextView setWidth:scrollView.bounds.size.width];
    [messageTextView setHeight:[self textFrameHeight:self.bodyView forMessage:messageTextView.text]];
    if (imageView != nil)
    {
        [imageView setOriginY:messageTextView.frame.origin.y + messageTextView.frame.size.height];
        if (overlayImageView != nil)
        {
            [overlayImageView setOriginY:imageView.frame.origin.y];
            [showOverlaySwitch setOriginY:imageView.frame.origin.y + imageView.frame.size.height + 10];
			UILabel * overlaySwitchLabel = (UILabel*)[self.bodyView viewWithTag:kOverlaySwitchLabelTag];
			[overlaySwitchLabel setOriginY:showOverlaySwitch.frame.origin.y];
        }
    }
    
    CGFloat extraHeight = bodyView.frame.origin.y + messageTextView.frame.origin.y + 
						  messageTextView.bounds.size.height + self.attachmentsHeight - 
						  self.view.frame.size.height;
	
    CGSize contentSize = self.view.bounds.size;
    contentSize.height += extraHeight > 0 ? extraHeight : 0;
    scrollView.contentSize = contentSize;
}


#pragma mark - Button action methods

- (void)didSelectYes:(id)sender
{
	[command acceptWithResponse:@"Yes"];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didSelectNo:(id)sender
{
	[command acceptWithResponse:@"No"];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didToggleOverlay:(id)sender
{
	overlayImageView.hidden = ! showOverlaySwitch.on;
}


#pragma mark - Execute command methods

- (void)executeDownload:(Command *)cmd
{
	NSURL   * baseUrl = [ConfigurationManager instance].systemUris.defaultDownloadBase;
	NSURL   * fileUrl = [baseUrl URLByAppendingPathComponent:cmd.parameter];
	NSError * error;
	
	[activityIndicator startAnimating];
	downloadManager = [[DownloadManager alloc] initWithUrl:fileUrl andDelegate:self];
	if (! [downloadManager startDownload:&error])
	{
		[self dismissAndShowErrorMessage:[error localizedDescription] 
							   withTitle:NSLocalizedString(@"Unable to Download File",@"Download file error")];
	}
}

- (void)executeCommand
{
	DirectiveType * directive = self.command.command.directive;
	DDLogInfo(@"Executing command of type %@", [directive stringValue]);
	
	// log user action on the server
	[self.command accept];
	
	if (directive.value == DT_DownloadFile || directive.value == DT_DownloadImage)
	{
		[self executeDownload:self.command.command];
	}
}


#pragma mark - DownloadDelegate methods

- (void)downloadProgress:(float)progress
{
	progressIndicator.progress = progress;
}

- (void)didFinishDownloadingFile:(NSString *)filename 
						  ofType:(NSString *)mimeType 
						   error:(NSError *)error
{
	[activityIndicator stopAnimating];
	
	if (error != nil)
	{
		[self dismissAndShowErrorMessage:[error localizedDescription] 
							   withTitle:NSLocalizedString(@"Unable to Download File",@"Download file error")];
		return;
	}
	
	[self setDocumentControllerForUrl:[NSURL fileURLWithPath:filename]];
    
    // @todo debug
    for (UIImage * anIcon in documentController.icons)
    {
        CGSize size = anIcon.size;
        DDLogVerbose(@"icon width=%f height=%f", size.width, size.height);
    }
	
    // @todo need to find an appropriately sized icon to display (for now just take first one)
	UIImage * icon = [documentController.icons objectAtIndex:0];
	UIView  * newCommandInfoView = [self newCommandInfoWithFileView:self.command.description 
															 andIcon:icon 
															 inFrame:commandInfoView.frame];
	
	[self attachGestureRecognizers:documentController.gestureRecognizers toView:newCommandInfoView];

	[commandInfoView removeFromSuperview];
	commandInfoView = newCommandInfoView;
	[self.bodyView addSubview:commandInfoView];
}


#pragma mark - UIDocumentInteractionControllerDelegate methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
	return self;
}

- (void)setDocumentControllerForUrl:(NSURL *)url
{
	documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
	documentController.delegate = self;
}

- (void)attachGestureRecognizers:(NSArray *)gestureRecognizers toView:(UIView *)view
{
	for (UIGestureRecognizer * gesture in gestureRecognizers)
	{
		[view addGestureRecognizer:gesture];
	}
	view.userInteractionEnabled = YES;
}

- (void)willDisplayCommandNotification:(NSNotification *)notification
{
	DDLogVerbose(@"NotificationViewController willDisplayCommandNotification");
	
	// a new command notification is about to display so dismiss the current one if we're on top
	if (self.navigationController.topViewController == self)
	{
		[self.navigationController popViewControllerAnimated:NO];
	}
}


#pragma mark - Perform command methods

- (void)viewCommandUrl
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.command.name]];
}

- (void)viewCamera:(CameraInfoWrapper *)camera
{
	MotionJpegMapViewController * viewController = 
		[[MotionJpegMapViewController alloc] initWithNibName:@"MotionJpegMapViewController" 
													   bundle:nil];
	viewController.camera = camera;
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void)viewCameraInfo
{
	CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithXml:self.command.command.parameter];
	[self viewCamera:camera];
}

- (void)viewCameraUri
{
	NSString * cmdParam  = command.command.parameter;
	NSRange    urlRange  = [cmdParam rangeOfString:@" "];
	NSString * urlString = [NSString stringWithString:[cmdParam substringToIndex:urlRange.location]];
	NSString * caption   = [NSString stringWithString:[cmdParam substringFromIndex:urlRange.location+1]];
	
	NSURL           * url             = [NSURL URLWithString:urlString];
	NSMutableString * urlPathAndQuery = [NSMutableString stringWithCapacity:[urlString length]];
	[urlPathAndQuery appendString:([url path] != nil) ? [url path] : @""];
	if (! NSStringIsNilOrEmpty([url query]))
	{
		[urlPathAndQuery appendFormat:@"?%@", [url query]];
	}
	
	CameraInfo * cameraInfo = [[CameraInfo alloc] init];
	cameraInfo.caption      = caption;
	cameraInfo.uri          = urlPathAndQuery;
	cameraInfo.port         = [[url port] longLongValue];
	cameraInfo.server       = [url host];
	cameraInfo.controlStub  = @"";
	
	CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithCamera:cameraInfo];
	[self viewCamera:camera];
}

- (void)viewVideoFeed
{
	NSString * cmdParam = command.command.parameter;
	NSArray  * parts    = [cmdParam componentsSeparatedByString:@"!"];
	NSString * url      = [parts objectAtIndex:2];
	NSString * caption  = [parts objectAtIndex:3];
	
	CameraInfo * cameraInfo = [[CameraInfo alloc] init];
	cameraInfo.caption      = caption;
	cameraInfo.uri          = url;
	cameraInfo.controlStub  = @"";
	
	CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithCamera:cameraInfo];
	[self viewCamera:camera];
}

- (void)placePhoneCall
{    
    [[RealityVisionClient instance] placePhoneCall:command.command.parameter fromUser:self.command.senderName];
}


#pragma mark - Private methods

- (void)dismissAndShowErrorMessage:(NSString *)message withTitle:(NSString *)title
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title
													 message:message
													delegate:nil 
										   cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
										   otherButtonTitles:nil];
	[alert show];
	[self.navigationController popViewControllerAnimated:YES];
}

- (UIView *)newDownloadProgressForFileView:(NSString *)filename 
								   inFrame:(CGRect)frame 
								 atYOffset:(CGFloat *)yOffset
{
	// create view
	CGRect viewFrame = CGRectMake(0, *yOffset, frame.size.width, frame.size.height - *yOffset);
	UIView * view = [[UIView alloc] initWithFrame:viewFrame];

	// y offset for internal view
	CGFloat newYOffset = 10;
	
	// create activity indicator
	CGRect activityFrame = CGRectMake((frame.size.width - 32) / 2,
									  newYOffset,
									  32,
									  32);

	// adjust y offset for next element
	newYOffset += activityFrame.size.height;
	
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	activityIndicator.frame = activityFrame;
	
	// create label for file name
	UIFont * labelFont = [UIFont systemFontOfSize:14];
	
	CGSize labelSize = [filename sizeWithFont:labelFont constrainedToSize:CGSizeMake(frame.size.width, 9999)];
	CGRect labelFrame = CGRectMake((frame.size.width - labelSize.width) / 2, 
								   newYOffset, 
								   labelSize.width, 
								   labelSize.height);
	
	UILabel * label = [[UILabel alloc] initWithFrame:labelFrame];
	label.text = filename;
	label.font = labelFont;
	
	// adjust y offset for next element
	newYOffset += labelSize.height + 5;
	
	// create progress indicator
	progressIndicator = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	CGRect progressFrame = CGRectMake(40, 
									  newYOffset, 
									  view.frame.size.width - 80, 
									  progressIndicator.frame.size.height);
	progressIndicator.frame = progressFrame;

	// adjust y offset for next element
	newYOffset += progressIndicator.frame.size.height;
	*yOffset += newYOffset;
	
	[view addSubview:activityIndicator];
	[view addSubview:label];
	[view addSubview:progressIndicator];
	
	return view;
}

- (UIView *)newCommandInfoWithFileView:(NSString *)filename 
							   andIcon:(UIImage *)icon 
							   inFrame:(CGRect)frame
{
	// create view
	UIView * view = [[UIView alloc] initWithFrame:frame];
	
	// y offset for internal view
	CGFloat newYOffset = 10;
	
	// create icon
	UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    [iconView setOriginX:(frame.size.width - iconView.frame.size.width) / 2];
    [iconView moveOriginYBy:newYOffset];
	
	// adjust y offset for next element
	newYOffset += iconView.frame.size.height + 10;
	
	// create label for file name
	UIFont * labelFont = [UIFont systemFontOfSize:14];
	CGSize labelSize = [filename sizeWithFont:labelFont constrainedToSize:CGSizeMake(frame.size.width, 9999)];
	CGRect labelFrame = CGRectMake((frame.size.width - labelSize.width) / 2, 
								   newYOffset, 
								   labelSize.width, 
								   labelSize.height);
	
	UILabel * label = [[UILabel alloc] initWithFrame:labelFrame];
	label.text = filename;
	label.font = labelFont;
	
	// adjust y offset for next element
	newYOffset += labelSize.height;
	
	[view addSubview:iconView];
	[view addSubview:label];
	
	
	// adjust frame size to minimum necessary to hold content
    [view increaseHeightBy:newYOffset];
	
	return view;
}

- (UIView *)newInfoForCommandWithDescriptionView:(NSString *)description 
										 andIcon:(UIImage *)icon 
										 inFrame:(CGRect)frame 
									   atYOffset:(CGFloat *)yOffset
{
	// create view
	CGRect viewFrame = CGRectMake(0, *yOffset, frame.size.width, frame.size.height - *yOffset);
	UIView * view = [[UIView alloc] initWithFrame:viewFrame];
	
	// y offset for internal view
	CGFloat newYOffset = 10;
	
	// create icon
	UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    [iconView setOriginX:(frame.size.width - iconView.frame.size.width) / 2];
    [iconView moveOriginYBy:newYOffset];
    
	// adjust y offset for next element
	newYOffset += iconView.frame.size.height + 10;
	
	// create label for command description
	UIFont * labelFont = [UIFont systemFontOfSize:14];
	
	CGSize labelSize = [description sizeWithFont:labelFont constrainedToSize:CGSizeMake(frame.size.width, 9999)];
	CGRect labelFrame = CGRectMake((frame.size.width - labelSize.width) / 2, 
								   newYOffset, 
								   labelSize.width, 
								   labelSize.height);
	
	UILabel * label = [[UILabel alloc] initWithFrame:labelFrame];
	label.text = description;
	label.font = labelFont;
	
	// adjust y offset for next element
	newYOffset += labelSize.height;
	*yOffset += newYOffset;
	
	[view addSubview:iconView];
	[view addSubview:label];
	
    view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    iconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth; 
    
    
	return view;
}

- (void)addInfoForCommand:(CommandWrapper *)cmd toView:(UIView *)view atYOffset:(CGFloat *)yOffset
{
    // add vertical padding
    *yOffset += 10;
    
	DirectiveTypeEnum directive = cmd.command.directive.value;
	
	if (directive == DT_DownloadFile || directive == DT_DownloadImage)
	{
		commandInfoView = [self newDownloadProgressForFileView:cmd.description 
														     inFrame:view.frame 
														   atYOffset:yOffset];
	}
	else 
	{
		commandInfoView = [self newInfoForCommandWithDescriptionView:cmd.description 
																  andIcon:cmd.icon 
																  inFrame:view.frame 
															    atYOffset:yOffset];
	}
	
	if (directive == DT_ViewUrl)
	{
		UIGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
																					  action:@selector(viewCommandUrl)];
		NSArray * gestures = [NSArray arrayWithObject:tapRecognizer];
		[self attachGestureRecognizers:gestures toView:commandInfoView];
	}
	else if (directive == DT_ViewCameraInfo)
	{
		UIGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
																					  action:@selector(viewCameraInfo)];
		NSArray * gestures = [NSArray arrayWithObject:tapRecognizer];
		[self attachGestureRecognizers:gestures toView:commandInfoView];
	}
	else if (directive == DT_ViewVideo)
	{
		UIGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
																					  action:@selector(viewVideo)];
		NSArray * gestures = [NSArray arrayWithObject:tapRecognizer];
		[self attachGestureRecognizers:gestures toView:commandInfoView];
	}
    else if (directive == DT_PlacePhoneCall)
    {
        UIGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
																					  action:@selector(placePhoneCall)];
		NSArray * gestures = [NSArray arrayWithObject:tapRecognizer];
		[self attachGestureRecognizers:gestures toView:commandInfoView];
    }
	
	// add more padding after command info view
	*yOffset += 10;
	
	[view addSubview:commandInfoView];
}

- (void)addMessage:(NSString *)message toView:(UIView *)view atYOffset:(CGFloat *)yOffset
{
	// add vertical padding
	*yOffset += 10;
	
	// determine height of text view
	UIFont * textFont = [UIFont systemFontOfSize:14];
    CGRect textFrame = CGRectMake(0, *yOffset, view.frame.size.width, [self textFrameHeight:view forMessage:message]);
	
	// create text view to display message
    UITextView * textView = [[UITextView alloc] initWithFrame:textFrame];
	textView.scrollEnabled = NO;
	textView.editable = NO;
	textView.text = message;
	textView.font = textFont;
    textView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.contentMode = UIViewContentModeRedraw;
	messageTextView = textView;
	
   	[view addSubview:messageTextView];
    
	// adjust y offset for next element
	*yOffset += textFrame.size.height;
}

- (CGFloat)textFrameHeight:(UIView *)view forMessage:(NSString *)message
{
    UIFont * textFont = [UIFont systemFontOfSize:14];
	CGSize textSize = [message sizeWithFont:textFont constrainedToSize:CGSizeMake(view.frame.size.width - 14, 9999)];
    return textSize.height + 20;
}

- (CGFloat)attachmentsHeight
{
    CGFloat height = 0;
    if (imageView != nil)
    {
        height += imageView.frame.size.height;
    
        if (showOverlaySwitch != nil)
        {
            height += (showOverlaySwitch.frame.origin.y - imageView.frame.origin.y - imageView.frame.size.height) + showOverlaySwitch.frame.size.height;
        }
    }
    
    return height != 0 ? height+20 : 0;
}

- (void)addAttachments:(NSArray *)attachments toView:(UIView *)view atYOffset:(CGFloat *)yOffset
{    
	// create image views for each attachment
	for (Attachment * attachment in attachments)
	{
		if (attachment.purpose.value == AP_Image) 
		{
			UIImage * image = [UIImage imageWithData:attachment.data];
			if (image != nil)
			{
				imageView = [[UIImageView alloc] initWithImage:image];
                [imageView setOrigin:CGPointMake(10, *yOffset)];
                imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
				[view addSubview:imageView];
				*yOffset += imageView.frame.size.height;
			}
			else 
			{
				DDLogError(@"Unable to decode image attachment");
			}
		}
		else if (attachment.purpose.value == AP_AnnotatedImage) 
		{
			UIImage * image = [UIImage imageWithData:attachment.data];
			if (image != nil)
			{
				overlayImageView = [[UIImageView alloc] initWithImage:image];
				
				// position overlay at the same location as the last image
				overlayImageView.frame = imageView.frame;
                overlayImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
				[view addSubview:overlayImageView];
			}
			else 
			{
				DDLogError(@"Unable to decode image attachment");
			}
		}
	}
	
	// if there's an overlay, add a switch to toggle its display
	if (overlayImageView != nil)
	{
		*yOffset += 10;
		
		// note that the width and height values are ignored for UISwitch
		showOverlaySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10, *yOffset, 94, 27)];
		showOverlaySwitch.on = YES;
		[showOverlaySwitch addTarget:self action:@selector(didToggleOverlay:) forControlEvents:UIControlEventValueChanged];
        showOverlaySwitch.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[view addSubview:showOverlaySwitch];
		
		CGFloat labelX = showOverlaySwitch.frame.origin.x + showOverlaySwitch.frame.size.width + 10;
		UILabel * overlaySwitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, *yOffset + 3, 150, 21)];
		overlaySwitchLabel.text = NSLocalizedString(@"Show Overlay",@"Show overlay label");
        overlaySwitchLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		overlaySwitchLabel.tag = kOverlaySwitchLabelTag;
		[view addSubview:overlaySwitchLabel];
		
		*yOffset += showOverlaySwitch.frame.size.height;
	}
}

- (void)createBodyView
{
	// y offset from top of body view
	CGFloat nextY = 0.0;
	
	if (self.command.command.directive.value != DT_TextMessage)
	{
		[self addInfoForCommand:self.command toView:self.bodyView atYOffset:&nextY];
	}
	
	if (! NSStringIsNilOrEmpty(self.command.messageWithResponse))
	{
		[self addMessage:self.command.messageWithResponse toView:self.bodyView atYOffset:&nextY];
	}
	
	[self addAttachments:self.command.command.attachments toView:self.bodyView atYOffset:&nextY];
	
	// adjust frame size to minimum necessary to hold content
    [self.bodyView setHeight:bodyView.bounds.size.height+nextY];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight |
	                              UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    bodyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight |
	                            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    bodyView.contentMode = UIViewContentModeRedraw;
}

@end
