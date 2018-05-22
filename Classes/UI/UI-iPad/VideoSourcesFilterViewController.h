//
//  VideoSourcesFilterViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 12/22/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//


#import <UIKit/UIKit.h>

@class MainMapViewController;


/**
 *  View Controller that provides a menu of camera filters used to turn on or
 *  off the display of sets of cameras.
 */
@interface VideoSourcesFilterViewController : UITableViewController

/**
 *  View Controller that displays the map of camera locations.
 */
@property (nonatomic,weak) IBOutlet MainMapViewController * mapViewController;

@end
