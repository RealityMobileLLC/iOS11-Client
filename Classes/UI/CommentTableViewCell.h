//
//  CommentTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell for displaying information about a Comment in the comment table view.
 */
@interface CommentTableViewCell : UITableViewCell 

/**
 *  The reuseIdentifier used by UITableView for maintaining a list of reusable cells.
 *  Note that this MUST match the reuseIdentifier in the NIB.
 */
+ (NSString *)reuseIdentifier;

/**
 *  Returns the size needed to display a commentTextLabel with the given comment for the given
 *  tableview width and style.
 *  
 *  @param comment The text to be displayed in the label.
 *  @param rowWidth The width of the tableview.
 *  @param tableViewStyle The style of the tableview.
 */
+ (CGSize)commentTextLabelSizeWithText:(NSString *)comment
					constrainedToWidth:(NSInteger)rowWidth
						tableViewStyle:(UITableViewStyle)tableViewStyle;

/**
 *  Returns the height of an infoTextLabel.
 *  Note that this MUST match the height of the infoTextLabel in the NIB.
 */
+ (CGFloat)infoTextLabelHeight;

/**
 *  The style of the tableview in which this cell will be displayed.
 */
@property (nonatomic) UITableViewStyle tableViewStyle;

// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UIImageView * thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel     * commentTextLabel;
@property (weak, nonatomic) IBOutlet UILabel     * infoTextLabel;

@end
