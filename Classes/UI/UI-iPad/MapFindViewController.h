//
//  MapFindViewController.h
//  RealityVision
//
//  Created by Valerie Smith on 4/10/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainMapViewController;


/**
 *  View Controller that provides a live updated Find menu used to center the map on a camera or user.
 */
@interface MapFindViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource,
                                                          UISearchBarDelegate, UISearchDisplayDelegate>

/**
 *  View Controller that displays the map of camera locations.
 */
@property (nonatomic,weak) MainMapViewController * mapViewController;

/**
 *  Popover Controller that contains this view controller.
 */
@property (nonatomic,weak) UIPopoverController * popoverController;


// Interface Builder outlets
@property (nonatomic,weak) IBOutlet UISearchBar * searchBar;

@end
