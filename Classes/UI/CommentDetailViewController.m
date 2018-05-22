//
//  CommentDetailViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/13/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommentDetailViewController.h"
#import "Comment.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommentDetailViewController
{
	Comment * comment;
}

@synthesize delegate;
@synthesize imageView;
@synthesize commentView;
@synthesize infoLabel;


- (id)initWithComment:(Comment *)aComment
{
	NSAssert(aComment,@"Comment must not be nil");
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
	self = [super initWithNibName:@"CommentDetailViewController" bundle:nil];
	if (self != nil)
	{
		comment = aComment;
	}
	return self;
}

- (void)viewDidLoad
{
	NSAssert(comment,@"CommentDetailViewController must be initialized using initWithComment");
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
    [super viewDidLoad];
	imageView.image = comment.thumbnail;
	commentView.text = comment.comments;
	
	NSString * commentEntryTime = [NSDateFormatter localizedStringFromDate:comment.entryTime
																 dateStyle:NSDateFormatterShortStyle
																 timeStyle:NSDateFormatterShortStyle];
	infoLabel.text = [NSString stringWithFormat:@"%@ - %@", comment.username, commentEntryTime];
	
	if (delegate)
	{
		UIBarButtonItem * flexibleSpace =
			[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
														  target:nil
														  action:nil];
		
		UIBarButtonItem * playFromHereButton =
			[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Play From Here",@"Play video from here button")
											 style:UIBarButtonItemStyleBordered
											target:self
											action:@selector(playFromHere:)];
		
		self.toolbarItems = [NSArray arrayWithObjects:flexibleSpace, playFromHereButton, flexibleSpace, nil];
	}
}

- (void)viewDidUnload
{
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)playFromHere:(id)sender
{
	DDLogInfo(@"CommentDetailViewController playFromHere");
	[self.navigationController popViewControllerAnimated:YES];
	[delegate playVideoFromComment:comment];
}

@end
