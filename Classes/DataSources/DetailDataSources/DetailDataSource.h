//
//  DetailDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraInfoWrapper.h"
#import "FavoritesManager.h"
 

/**
 *  An abstract class used to provide camera details for displaying in a table view.
 *
 *  This class should never be instantiated directly.
 */
@interface DetailDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, FavoritesObserver>

/**
 *  Camera whose details are displayed.
 */
@property (strong, nonatomic) CameraInfoWrapper * camera;

/**
 *  Title to use when displaying this camera list.
 */
@property (strong, nonatomic,readonly) NSString * title;

/**
 *  Sets the text and properties for the label to use for Add/Remove Favorite button.
 *  The label will be disabled if the user's favorites are not currently known.  
 *  When favorites are updated, the tableView will be updated.
 */
- (void)initFavoriteButtonLabel:(UILabel *)label forTableView:(UITableView *)tableView;

/**
 *  A table view cell used to display a camera property name and value (such as name, 
 *  description, etc.).
 */
- (UITableViewCell *)tableViewCellForCameraDetails:(UITableView *)tableView;

/**
 *  A table view cell used to display camera status icons (such as has location, has comments, 
 *  and PTZ controls).
 */
- (UITableViewCell *)tableViewCellForCameraStatus:(UITableView *)tableView;

/**
 *  A table view cell used to display a thumbnail.
 */
- (UITableViewCell *)tableViewCellForCameraThumbnail:(UITableView *)tableView;

/**
 *  Toggles whether the camera is a favorite and reloads the table view's datasource.
 */
- (void)toggleFavoriteAndRefreshTableView:(UITableView *)tableView;

/**
 *  Shows the video for this camera.
 */
- (void)showVideo;

@end
