//
//  CommentTableViewCellProvider.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Comment;


/**
 *  CommentTableViewCellProvider is a static factory class for creating and formatting
 *  tableview cells objects used to display RealityVision session and frame comments.
 */
@interface CommentTableViewCellProvider : NSObject

/**
 *  Returns the height of a UITableViewCell object with the given session comment.
 *  
 *  @param comment        The comment to be displayed by the cell.
 *  @param rowWidth       The width of the tableview in its current orientation. Note that this
 *                        method attempts to derive the actual label width from this value based
 *                        on the tableViewStyle.
 *  @param tableViewStyle The style of the table in which this comment will appear.
 *  @return the height required to display the session comment in a CommentTableViewCell
 */
+ (CGFloat)heightForRowWithSessionComment:(Comment *)comment
					   constrainedToWidth:(NSInteger)rowWidth
						   tableViewStyle:(UITableViewCellStyle)tableViewStyle;

/**
 *  Returns the height of a CommentTableViewCell object with the given frame comment.
 *
 *  @param comment        The comment to be displayed by the cell.
 *  @param rowWidth       The width of the tableview in its current orientation. Note that this
 *                        method attempts to derive the actual label width from this value based
 *                        on the tableViewStyle.
 *  @param tableViewStyle The style of the table in which this comment will appear.
 *  @return the height required to display the frame comment in a CommentTableViewCell
 */
+ (CGFloat)heightForRowWithFrameComment:(Comment *)comment
					 constrainedToWidth:(NSInteger)rowWidth
						 tableViewStyle:(UITableViewCellStyle)tableViewStyle;

/**
 *  Returns a UITableViewCell object formatted to display the given session comment.
 */
+ (UITableViewCell *)tableView:(UITableView *)tableView cellForSessionComment:(Comment *)comment;

/**
 *  Returns a CommentTableViewCell object formatted to display the given frame comment.
 */
+ (UITableViewCell *)tableView:(UITableView *)tableView cellForFrameComment:(Comment *)comment;

@end
