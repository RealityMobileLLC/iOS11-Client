//
//  CommandMessageViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/23/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CommandMessageViewController.h"
#import "UILabel+Layout.h"
#import "UIView+Layout.h"
#import "Recipient.h"
#import "RecipientSelectionViewController.h"
#import "RootViewController.h"
#import "RealityVisionClient.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

const NSUInteger kRVMaxMessageLength = 1024;


@interface CommandMessageViewController()
@property (nonatomic) NSRange selectedRange;
@end


@implementation CommandMessageViewController

@synthesize recipientViewController;
@synthesize recipientLabel;
@synthesize messageTextView;
@synthesize selectedRange;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DDLogVerbose(@"CommandMessageViewController viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Add Message",@"Add message title");
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 320.0);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send",@"Send button") 
                                                                               style:UIBarButtonItemStyleDone 
                                                                              target:self 
                                                                              action:@selector(send)];
    
    self.selectedRange = NSMakeRange(0, 0);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
											   object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillBeHidden:) 
                                                 name:UIKeyboardWillHideNotification
											   object:nil];
}

- (void)viewDidUnload
{
    DDLogVerbose(@"CommandMessageViewController viewDidUnload");
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    self.recipientLabel = nil;
    self.messageTextView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSAssert(self.recipientViewController,@"RecipientViewController must be specified");
    NSAssert([recipientViewController.recipients count]>0,@"There must be at least 1 recipient");
    
    DDLogVerbose(@"CommandMessageViewController viewWillAppear");
    [super viewWillAppear:animated];
    
    self.recipientLabel.text = [Recipient stringWithRecipients:recipientViewController.recipients];    
    [self.messageTextView becomeFirstResponder];
    self.messageTextView.selectedRange = self.selectedRange;
    
    [self layoutViewForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    DDLogVerbose(@"CommandMessageViewController viewDidAppear");
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    DDLogVerbose(@"CommandMessageViewController viewWillDisappear");
    self.selectedRange = self.messageTextView.selectedRange;
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    DDLogVerbose(@"CommandMessageViewController viewDidDisappear");
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.recipientViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self layoutViewForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)layoutViewForInterfaceOrientation:(UIInterfaceOrientation)newOrientation
{
    CGFloat maxLines = UIInterfaceOrientationIsPortrait(newOrientation) ? 3.0 : 2.0;
    CGFloat maxHeight = DefaultLabelHeight * maxLines;
    
    CGFloat delta = [self.recipientLabel resizeHeightToFitTextWithMaxHeight:maxHeight];
    if (fabs(delta) > FLT_EPSILON)
    {
        [self.messageTextView moveOriginYBy:delta];
        [self.messageTextView increaseHeightBy:delta];
    }
}

- (void)send
{
    DDLogVerbose(@"CommandMessageViewController send");
	
	NSString * message = [self.messageTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([message length] > kRVMaxMessageLength)
	{
		message = [message substringToIndex:kRVMaxMessageLength];
	}
    
    if (self.recipientViewController.camera)
    {
        [[RealityVisionClient instance] shareVideo:self.recipientViewController.camera 
                                          fromTime:self.recipientViewController.shareVideoStartTime 
                                    withRecipients:self.recipientViewController.recipients 
                                           message:message];
    }
    else if (self.recipientViewController.shareCurrentTransmitSession)
    {
        [[RealityVisionClient instance] shareCurrentTransmitSessionFromBeginning:self.recipientViewController.shareCurrentTransmitSessionFromBeginning 
                                                                  withRecipients:self.recipientViewController.recipients 
                                                                         message:message];
    }
    else
    {
        DDLogWarn(@"CommandMessageViewController send: Video feed to share was not specified");
        NSAssert(NO,@"Video feed to share was not specified");
    }
    
    [self.recipientViewController done];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{    
	NSDictionary * info = [aNotification userInfo];
	CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGFloat kbHeight = [self.view convertRect:keyboardFrame fromView:nil].size.height;
	CGRect selfFrame = [self.view convertRect:self.view.bounds toView:nil];
	CGPoint kbOrigin = CGPointMake(selfFrame.origin.x, selfFrame.size.height - keyboardFrame.size.height);
	
	if (CGRectContainsPoint(selfFrame, kbOrigin))
	{        
		UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbHeight, 0.0);
		messageTextView.contentInset = contentInsets;
		messageTextView.scrollIndicatorInsets = contentInsets;
		messageTextView.contentSize = messageTextView.bounds.size;
	}
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	UIEdgeInsets contentInsets = UIEdgeInsetsZero;
	messageTextView.contentInset = contentInsets;
	messageTextView.scrollIndicatorInsets = contentInsets;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	return (textView.text.length - range.length + text.length) <= kRVMaxMessageLength;
}

@end
