//
//  CommentTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommentTableViewCell.h"
#import "UIView+Layout.h"

static const CGFloat kGroupTableMarginsPhone = 20;
static const CGFloat kGroupTableMarginsPad = 90;
static const CGFloat kCommentLabelLeftMargin = 77;
static const CGFloat kCommentLabelRightMargin = 49;
static const CGFloat kInfoLabelHeight = 21;


@implementation CommentTableViewCell

@synthesize tableViewStyle;
@synthesize thumbnailView;
@synthesize commentTextLabel;
@synthesize infoTextLabel;

+ (NSString *)reuseIdentifier
{
	return @"CommentCell";
}

+ (CGSize)commentTextLabelSizeWithText:(NSString *)comment
					constrainedToWidth:(NSInteger)rowWidth
						tableViewStyle:(UITableViewStyle)tableViewStyle
{
	// determine maximum width of label
	CGFloat maxWidth = rowWidth - kCommentLabelLeftMargin - kCommentLabelRightMargin;
	
	if (tableViewStyle == UITableViewStyleGrouped)
		maxWidth -= (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kGroupTableMarginsPad : kGroupTableMarginsPhone;
	
	// determine size needed to fit label text within that width
	CGSize size = [comment sizeWithFont:[UIFont systemFontOfSize:12]
					  constrainedToSize:CGSizeMake(maxWidth, 20000)
						  lineBreakMode:UILineBreakModeWordWrap];
	
	// restore the width to its maximum
	size.width = maxWidth;
	return size;
}

+ (CGFloat)infoTextLabelHeight
{
	return kInfoLabelHeight;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// size the comment label to fit its text
	CGSize commentSize = [CommentTableViewCell commentTextLabelSizeWithText:self.commentTextLabel.text
														 constrainedToWidth:self.bounds.size.width
															 tableViewStyle:self.tableViewStyle];
	[self.commentTextLabel setSize:commentSize];
	
	// place the info label below the comment label
	CGFloat infoY = self.commentTextLabel.frame.origin.y + self.commentTextLabel.frame.size.height - 4;
	[infoTextLabel setOriginY:infoY];
}

@end
