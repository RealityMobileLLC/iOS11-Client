//
//  DetailArchiveDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/4/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "DetailArchiveDataSource.h"
#import "SystemUris.h"
#import "Comment.h"
#import "Session.h"
#import "CameraStatusTableViewCell.h"
#import "CommentTableViewCell.h"
#import "CommentTableViewCellProvider.h"
#import "EnterCommentViewController.h"
#import "CommentDetailViewController.h"
#import "ConfigurationManager.h"
#import "FavoritesManager.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "NSString+RealityVision.h"
#import "UIImage+RealityVision.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static const CGFloat kDefaultRowHeight = 44.0;

enum 
{
	Section_Details,
	Section_Thumbnail,
	Section_Buttons,
	Section_Session_Comments,
	Section_Frame_Comments,
	Num_Sections
};


enum 
{
	Details_Row_User,
	Details_Row_StartTime,
	Details_Row_Device,
	Details_Row_Length,
	Details_Row_Status
};


enum 
{
	Buttons_Row_Watch
};


@implementation DetailArchiveDataSource
{
	NSMutableArray * sessionComments;
	NSMutableArray * frameComments;
	UIButton       * addSessionCommentButton;
	UIButton       * addFrameCommentButton;
	UIView         * sessionCommentsHeader;
	UIView         * frameCommentsHeader;
}

- (UIButton *)createAddCommentButtonWithAction:(SEL)action
{
	UIButton * button = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	
	button.frame = CGRectMake(320 - button.bounds.size.width - 16, 
							  0, 
							  button.bounds.size.width, 
							  button.bounds.size.height);
	
	return button;
}

- (UIView *)createCommentsHeaderWithText:(NSString *)text andCommentButton:(UIButton *)button
{
	double width  = 320;
	double height = button.bounds.size.height;
	
	UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, height)];
	label.text = text;
	label.font = [UIFont systemFontOfSize:18];
	label.textColor = [UIColor darkGrayColor];
	label.backgroundColor = [UIColor clearColor];
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	headerView.backgroundColor = [UIColor clearColor];
	
	[headerView addSubview:button];
	[headerView addSubview:label];
	
	return headerView;
}

- (id)initWithCameraDetails:(CameraInfoWrapper *)theCamera
{
	NSAssert(theCamera.isArchivedSession,@"Camera must be a Session");
	
	self = [super init];
	if (self != nil)
	{
		self.camera = theCamera;
		
		// create comments header views
		addSessionCommentButton = [self createAddCommentButtonWithAction:@selector(addSessionComment:)];
		sessionCommentsHeader = [self createCommentsHeaderWithText:NSLocalizedString(@"Session Comments",
																					 @"Session comments label") 
												  andCommentButton:addSessionCommentButton];
		
		addFrameCommentButton = [self createAddCommentButtonWithAction:@selector(addFrameComment:)];
		addFrameCommentButton.hidden = YES;
		frameCommentsHeader = [self createCommentsHeaderWithText:NSLocalizedString(@"Frame Comments",
																				   @"Frame comments label") 
												andCommentButton:addFrameCommentButton];
		
		// get session and frame comments
		sessionComments = [NSMutableArray arrayWithCapacity:10];
		frameComments = [NSMutableArray arrayWithCapacity:10];
		
		Session * session = self.camera.sourceObject;
		
		for (Comment * comment in session.comments)
		{
            NSMutableArray * commentsArray = (comment.isFrameComment) ? frameComments : sessionComments;
            [commentsArray addObject:comment];
		}
        
        [sessionComments sortUsingSelector:@selector(compareEntryTime:)];
        [frameComments   sortUsingSelector:@selector(compareEntryTime:)];
	}
	return self;
}

- (NSString *)title
{
	return NSLocalizedString(@"Video History Info",@"Video history info title");
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return Num_Sections;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case Section_Details:
		case Section_Thumbnail:
		case Section_Buttons:
			break;
			
		case Section_Session_Comments:
			return sessionCommentsHeader.bounds.size.height;
			
		case Section_Frame_Comments:
			return frameCommentsHeader.bounds.size.height;
			
		default:
			DDLogWarn(@"Invalid section for DetailArchiveDataSource");
	}
	
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case Section_Details:
		case Section_Thumbnail:
		case Section_Buttons:
			break;
			
		case Section_Session_Comments:
			return sessionCommentsHeader;
			
		case Section_Frame_Comments:
			return frameCommentsHeader;
			
		default:
			DDLogWarn(@"Invalid section for DetailArchiveDataSource");
	}
	
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    Session * session = self.camera.sourceObject;
    
	switch (section)
	{
		case Section_Details:
			// assumes Status row is always the final row
			return (session.hasGps || (self.camera.numberOfComments > 0)) ? Details_Row_Status + 1 : Details_Row_Status;
			
		case Section_Thumbnail:
        case Section_Buttons:
			return 1;
			
		case Section_Session_Comments:
			return MAX([sessionComments count], 1);
			
		case Section_Frame_Comments:
			return MAX([frameComments count], 1);
			
		default:
			DDLogWarn(@"Invalid section for DetailArchiveDataSource");
	}
	
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForSessionCommentsAtRow:(NSInteger)row
{
	Comment * comment = ([sessionComments count] > 0) ? [sessionComments objectAtIndex:row] : nil;
	return [CommentTableViewCellProvider heightForRowWithSessionComment:comment
													 constrainedToWidth:tableView.bounds.size.width
														 tableViewStyle:tableView.style];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFrameCommentsAtRow:(NSInteger)row
{
	Comment * comment = ([frameComments count] > 0) ? [frameComments objectAtIndex:row] : nil;
	return [CommentTableViewCellProvider heightForRowWithFrameComment:comment
												   constrainedToWidth:tableView.bounds.size.width
													   tableViewStyle:tableView.style];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case Section_Details:
			return (indexPath.row == Details_Row_Status) ? 60.0 : 
			       (indexPath.row == Details_Row_Device) ? 60.0 : kDefaultRowHeight;
			
		case Section_Thumbnail:
			return 128.0;
			
		case Section_Frame_Comments:
			return [self tableView:tableView heightForFrameCommentsAtRow:indexPath.row];
			
		case Section_Session_Comments:
			return [self tableView:tableView heightForSessionCommentsAtRow:indexPath.row];
			
		case Section_Buttons:
			// return the default row height
			break;
			
		default:
			DDLogWarn(@"Invalid section for DetailArchiveDataSource");
	}
	
    return kDefaultRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForDetailsRow:(NSInteger)row
{
	UITableViewCell * cell    = [self tableViewCellForCameraDetails:tableView];
	Session         * session = self.camera.sourceObject;
	
	switch (row)
	{
		case Details_Row_User:
			cell.textLabel.text = NSLocalizedString(@"User",@"User full name label");
			cell.detailTextLabel.text = session.userFullName;
			break;
			
		case Details_Row_StartTime:
			cell.textLabel.text = NSLocalizedString(@"Start time",@"Start time label");
			cell.detailTextLabel.text = self.camera.name;
			break;
			
		case Details_Row_Device:
			cell.textLabel.text = NSLocalizedString(@"Device",@"Device name label");
			cell.detailTextLabel.text = session.deviceDescription;
			break;
			
		case Details_Row_Length:
			cell.textLabel.text = NSLocalizedString(@"Length",@"Length label");
			cell.detailTextLabel.text = (self.camera.length < 0) ? @"" : [NSString stringForTimeInterval:self.camera.length];
			break;
			
		default:
			DDLogWarn(@"Invalid row for DetailArchiveDataSource");
			cell = nil;
	}
	
	return cell;
}

- (UITableViewCell *)tableViewCellForCameraStatus:(UITableView *)tableView
{
	NSString * cellIdentifier = [CameraStatusTableViewCell reuseIdentifier];
	CameraStatusTableViewCell * cell = (CameraStatusTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    Session * session = self.camera.sourceObject;
	cell.locationImage.highlighted = session.hasGps;
	cell.locationLabel.hidden = ! session.hasGps;
	
    // use ptzImage view to show comments
	cell.ptzImage.highlighted = (self.camera.numberOfComments > 0);
	cell.ptzImage.highlightedImage = [UIImage imageNamed:@"ic_list_comment"];
    cell.ptzLabel.text = [NSString stringWithFormat:@"Has Comments (%d)",self.camera.numberOfComments];
	cell.ptzLabel.hidden = (self.camera.numberOfComments == 0);
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForButtonsRow:(NSInteger)row
{
	static NSString * CellIdentifier = @"ButtonCell";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor = [UIColor blueColor];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
	
    if (row == Buttons_Row_Watch)
	{
		cell.textLabel.text = NSLocalizedString(@"Watch Video",@"Watch Video button");
	}
	else 
	{
		DDLogWarn(@"Invalid button row for DetailArchiveDataSource");
		cell = nil;
	}
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForCommentsRowWithText:(NSString *)commentText
{
	static NSString * CellIdentifier = @"Cell";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.font = [UIFont systemFontOfSize:12];
	}
	
	cell.textLabel.text = commentText;
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSessionCommentsRow:(NSInteger)row
{
	if ([sessionComments count] == 0)
	{
		return [self tableView:tableView cellForCommentsRowWithText:NSLocalizedString(@"No Session Comments",@"No Session Comments")];
	}
	
	return [CommentTableViewCellProvider tableView:tableView cellForSessionComment:[sessionComments objectAtIndex:row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForFrameCommentsRow:(NSInteger)row
{
	if ([frameComments count] == 0)
	{
		return [self tableView:tableView cellForCommentsRowWithText:NSLocalizedString(@"No Frame Comments",@"No Frame Comments")];
	}
	
	return [CommentTableViewCellProvider tableView:tableView cellForFrameComment:[frameComments objectAtIndex:row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.section)
	{
		case Section_Details:
			return (indexPath.row == Details_Row_Status) ? [self tableViewCellForCameraStatus:tableView] 
			                                             : [self tableView:tableView cellForDetailsRow:indexPath.row];
			
		case Section_Thumbnail:
			return [self tableViewCellForCameraThumbnail:tableView];
			
		case Section_Buttons:
			return [self tableView:tableView cellForButtonsRow:indexPath.row];
			
		case Section_Session_Comments:
			return [self tableView:tableView cellForSessionCommentsRow:indexPath.row];
			
		case Section_Frame_Comments:
			return [self tableView:tableView cellForFrameCommentsRow:indexPath.row];
			
		default:
			DDLogWarn(@"Invalid section for DetailArchiveDataSource");
	}
	
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == Section_Buttons)
	{
		if (indexPath.row == Buttons_Row_Watch)
		{
			[self showVideo];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	Comment * comment = [frameComments objectAtIndex:indexPath.row];
 	CommentDetailViewController * commentView = [[CommentDetailViewController alloc] initWithComment:comment];
	
 	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	[appDelegate.navigationController pushViewController:commentView animated:YES];
}

#if 0  // @todo add ability to play video from comment
- (void)playVideoFromComment:(Comment *)comment
{
	[self playVideoFromTime:comment.frameTime];
}
#endif


#pragma mark - Add comment methods

- (void)addSessionComment:(id)sender
{
	DDLogVerbose(@"DetailArchiveDataSource addSessionComment");
	
	EnterCommentViewController * enterCommentViewController = 
		[[EnterCommentViewController alloc] initWithNibName:@"EnterCommentViewController" 
													  bundle:nil];
	
	enterCommentViewController.title = NSLocalizedString(@"Enter Session Comment",@"Enter session comment title");
	enterCommentViewController.delegate = self;
	
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	UIViewController * topViewController = appDelegate.navigationController.topViewController;
	[topViewController presentViewController:enterCommentViewController animated:YES completion:NULL];
}

- (void)didEnterComment:(NSString *)commentText
{
	DDLogInfo(@"DetailArchiveDataSource didEnterComment");
	
	if (! NSStringIsNilOrEmpty(commentText))
	{
		// create comment to display in table
		Comment * comment = [[Comment alloc] init];
		comment.commentId = 0;
		comment.comments = commentText;
		comment.entryTime = [NSDate date];
		comment.username = [RealityVisionClient instance].userId;
		comment.isFrameComment = NO;
		comment.thumbnail = nil;
		
		// get web service
		NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
		
		// send comment to server
		Session * session = self.camera.sourceObject;
		[clientTransaction addComment:commentText forSession:session.sessionId];
		
		// add the comment both to the session (so it shows up in browse window) and to this data source
		[session.comments addObject:comment];
		[sessionComments insertObject:comment atIndex:0];
	}
	
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	UIViewController * topViewController = appDelegate.navigationController.topViewController;
 	[topViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
