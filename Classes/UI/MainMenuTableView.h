//
//  MainMenuTableView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuTableViewCell;


/**
 *  MainMenuTableView provides the data source and delegate for displaying the main menu.
 */
@interface MainMenuTableView : NSObject <UITableViewDataSource, UITableViewDelegate>

/**
 *  Indicates whether main menu is enabled.
 */
@property (nonatomic) BOOL mainMenuEnabled;

/**
 *  The number of items in the menu.
 */
@property (nonatomic,readonly) NSInteger menuItemCount;

@end
