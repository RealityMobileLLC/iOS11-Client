//
//  MainMenuViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright Reality Mobile LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"


/**
 *  View Controller for RealityVision's main menu.
 *
 *  This is the root view controller for the iPhone.
 */
@interface MainMenuViewController : RootViewController <UIActionSheetDelegate>

// Interface Builder outlets
@property (nonatomic,weak) IBOutlet UITableView * tableView;

@end
