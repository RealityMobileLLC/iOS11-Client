//
//  MenuTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell for displaying a menu item with an image and an optional badge count 
 *  label.
 */
@interface MenuTableViewCell : UITableViewCell 

/**
 *  Sets the value to display in the badge.
 *  
 *  @param badgeCount Value to display in the badge. If 0, badge is hidden.
 */
- (void)setBadgeCount:(NSUInteger)badgeCount;

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView * imageView;
@property (weak, nonatomic) IBOutlet UILabel     * textLabel;
@property (weak, nonatomic) IBOutlet UIImageView * badgeImage;
@property (weak, nonatomic) IBOutlet UILabel     * badgeLabel;

@end
