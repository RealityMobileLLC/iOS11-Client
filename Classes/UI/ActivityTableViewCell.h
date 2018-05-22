//
//  ActivityTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell containing an activity indicator and a label.
 */
@interface ActivityTableViewCell : UITableViewCell 

/**
 *  Creates an ActivityTableViewCell with the given text and optionally starts
 *  it animating.
 *
 *  @param text  Text to display in the cell.
 *  @param start Indicates whether the activity indicator should be animating.
 */
+ (ActivityTableViewCell *)activityTableViewCellWithText:(NSString *)text 
												andStart:(BOOL)start;

/**
 *  Starts animating the activity indicator.
 */
- (void)startActivityIndicator;

/**
 *  Stops animating the activity indicator.
 */
- (void)stopActivityIndicator;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView * activityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel                 * textLabel;

@end


/**
 *  Factory for loading an ActivityTableViewCell from a NIB.
 */
@interface ActivityTableViewCellLoader : NSObject
@property (nonatomic,strong) IBOutlet ActivityTableViewCell * activityTableViewCell;
@end



