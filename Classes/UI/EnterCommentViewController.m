//
//  EnterCommentViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "EnterCommentViewController.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

const int kMaxCommentLength = 1024;


@implementation EnterCommentViewController

@synthesize delegate;
@synthesize title;
@synthesize commentTextView;
@synthesize navigationBar;
@synthesize restrictToLandscapeOrientation;


- (void)viewDidLoad
{
	DDLogVerbose(@"EnterCommentViewController viewDidLoad");
	[super viewDidLoad];
	
	if (self.title != nil)
	{
		self.navigationBar.topItem.title = self.title;
	}
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"EnterCommentViewController viewDidUnload");
    [super viewDidUnload];
	self.commentTextView = nil;
	self.navigationBar = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"EnterCommentViewController viewWillAppear");
	[super viewWillAppear:animated];
	[self.commentTextView becomeFirstResponder];
}


- (void)viewDidDisappear:(BOOL)animated
{
	DDLogVerbose(@"EnterCommentViewController viewDidDisappear");
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (self.restrictToLandscapeOrientation)
		return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (IBAction)done
{
	DDLogVerbose(@"EnterCommentViewController done");
	
	NSString * comment = [self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if ([comment length] > kMaxCommentLength)
	{
		comment = [comment substringToIndex:kMaxCommentLength];
	}
	
	[self.delegate didEnterComment:comment];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return textView.text.length - range.length + text.length <= kMaxCommentLength;
}

@end
