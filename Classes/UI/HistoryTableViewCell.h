//
//  HistoryTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/9/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell for displaying information about a Command in the command history 
 *  table view.
 */
@interface HistoryTableViewCell : UITableViewCell 

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView * iconImageView;
@property (weak, nonatomic) IBOutlet UILabel     * titleTextLabel;
@property (weak, nonatomic) IBOutlet UILabel     * fromTextLabel;
@property (weak, nonatomic) IBOutlet UILabel     * dateTextLabel;

@end
