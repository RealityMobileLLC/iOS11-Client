//
//  CommentTableViewCellProvider.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "CommentTableViewCellProvider.h"
#import "Comment.h"
#import "CommentTableViewCell.h"
#import "UIImage+RealityVision.h"

static const CGFloat kDefaultCommentTableViewCellHeight = 44;
static const CGFloat kSessionCommentMargins = 20;
static const CGFloat kSessionCommentGroupedMarginsPhone = 18;
static const CGFloat kSessionCommentGroupedMarginsPad = 88;
static const CGFloat kSessionCommentBottomMargin = 21;
static const CGFloat kFrameCommentBottomMargin = 5;
static const CGFloat kMinimumFrameCommentTableViewCellHeight = 74;


@implementation CommentTableViewCellProvider

+ (CGFloat)heightForRowWithSessionComment:(Comment *)comment
					   constrainedToWidth:(NSInteger)rowWidth
						   tableViewStyle:(UITableViewCellStyle)tableViewStyle
{
	if (comment == nil)
		return kDefaultCommentTableViewCellHeight;
	
	// determine maximum width of label
	CGFloat maxWidth = rowWidth - kSessionCommentMargins;
	
	if (tableViewStyle == UITableViewStyleGrouped)
		maxWidth -= (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kSessionCommentGroupedMarginsPad : kSessionCommentGroupedMarginsPhone;
	
	// determine size needed to fit label text within that width
	NSString * text = comment.comments;
	CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:12]
				   constrainedToSize:CGSizeMake(maxWidth, 20000)
					   lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat height = MAX(size.height + kSessionCommentBottomMargin, kDefaultCommentTableViewCellHeight);
	return height;
}

+ (CGFloat)heightForRowWithFrameComment:(Comment *)comment
					 constrainedToWidth:(NSInteger)rowWidth
						 tableViewStyle:(UITableViewCellStyle)tableViewStyle
{
	if (comment == nil)
		return kDefaultCommentTableViewCellHeight;
	
	CGSize commentLabelSize = [CommentTableViewCell commentTextLabelSizeWithText:comment.comments
															  constrainedToWidth:rowWidth
																  tableViewStyle:tableViewStyle];
	CGFloat infoLabelHeight = [CommentTableViewCell infoTextLabelHeight];
	CGFloat height = MAX(commentLabelSize.height + infoLabelHeight + kFrameCommentBottomMargin, kMinimumFrameCommentTableViewCellHeight);
	return height;
}

+ (UITableViewCell *)tableView:(UITableView *)tableView cellForSessionComment:(Comment *)comment
{
	static NSString * CellIdentifier = @"SessionCommentCell";
	
	NSString * commentEntryTime = [NSDateFormatter localizedStringFromDate:comment.entryTime
																 dateStyle:NSDateFormatterMediumStyle
																 timeStyle:NSDateFormatterShortStyle];
	
	NSString * infoText = [NSString stringWithFormat:@"%@ - %@", comment.username, commentEntryTime];
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [UIFont systemFontOfSize:12];
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
	}
	
	cell.textLabel.text = comment.comments;
	cell.detailTextLabel.text = infoText;
	
	return cell;
}

+ (UITableViewCell *)tableView:(UITableView *)tableView cellForFrameComment:(Comment *)comment
{
	NSString * commentEntryTime = [NSDateFormatter localizedStringFromDate:comment.entryTime
																 dateStyle:NSDateFormatterMediumStyle
																 timeStyle:NSDateFormatterShortStyle];
	
	NSString * infoText = [NSString stringWithFormat:@"%@ - %@", comment.username, commentEntryTime];
	
	NSString * cellIdentifier = [CommentTableViewCell reuseIdentifier];
	CommentTableViewCell * cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	cell.commentTextLabel.text = comment.comments;
	cell.infoTextLabel.text = infoText;
	cell.thumbnailView.image = [UIImage image:comment.thumbnail resizedToFit:cell.thumbnailView.bounds.size];
	cell.tableViewStyle = tableView.style;
	
	return cell;
}

@end
