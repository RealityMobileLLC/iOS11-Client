//
//  SwitchTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/21/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell containing a label and a switch.
 */
@interface SwitchTableViewCell : UITableViewCell 

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UILabel  * label;
@property (weak, nonatomic) IBOutlet UISwitch * switchField;

@end
