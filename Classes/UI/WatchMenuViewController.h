//
//  WatchMenuViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoritesManager.h"

/**
 *  View Controller that displays the Watch menu.
 */
@interface WatchMenuViewController : UITableViewController <FavoritesObserver>

@end
