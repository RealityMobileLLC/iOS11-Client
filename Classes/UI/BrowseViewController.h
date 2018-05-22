//
//  BrowseViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "BrowseCameraCategory.h"
#import "CameraCatalogDataSource.h"

@class ActivityTableViewCell;


/**
 *  View Controller responsible for displaying a searchable list of cameras.
 *  
 *  Before this View Controller is loaded, the caller must set the
 *  cameraDataSource property to an object that will retrieve the list of
 *  cameras to be displayed.
 */
@interface BrowseViewController : UIViewController < MKMapViewDelegate, 
                                                     UIActionSheetDelegate, 
                                                     CameraDataSourceDelegate,
                                                     UIAlertViewDelegate >

/**
 *  Category of cameras to display.
 */
@property (nonatomic) BrowseCameraCategory cameraCategory;

/**
 *  Object responsible for asynchronously retrieving a list of cameras to be
 *  displayed by the BrowseViewController.
 */
@property (strong, nonatomic) CameraDataSource * cameraDataSource;


// Interface builder outlets
@property (strong, nonatomic) IBOutlet UIBarButtonItem       * showMapButton;
@property (strong, nonatomic) IBOutlet ActivityTableViewCell * activityTableViewCell;
@property (weak, nonatomic)   IBOutlet UITableView           * tableView;
@property (weak, nonatomic)   IBOutlet MKMapView             * mapView;

@end
