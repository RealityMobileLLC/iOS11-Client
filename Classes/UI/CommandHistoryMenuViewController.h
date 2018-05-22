//
//  CommandHistoryMenuViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/20/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuTableViewCell;


/**
 *  View Controller that allows the user to select whether to view received or sent command history.
 */
@interface CommandHistoryMenuViewController : UITableViewController

// used to load a table view cell from a nib
@property (nonatomic,strong) IBOutlet MenuTableViewCell * menuTableViewCell;

@end
