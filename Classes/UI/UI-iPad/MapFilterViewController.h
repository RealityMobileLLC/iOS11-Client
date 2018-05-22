//
//  MapFilterViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainMapViewController;


/**
 *  View Controller that provides a menu of camera filters used to turn on or
 *  off the display of sets of cameras.
 */
@interface MapFilterViewController : UITableViewController 

/**
 *  View Controller that displays the map of camera locations.
 */
@property (nonatomic,weak) IBOutlet MainMapViewController * mapViewController;

/**
 *  Popover Controller that contains this view controller.
 */
@property (nonatomic,weak) UIPopoverController * popoverController;

@end
