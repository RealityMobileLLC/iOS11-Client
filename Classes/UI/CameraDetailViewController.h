//
//  CameraDetailViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/17/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailDataSource;


@interface CameraDetailViewController : UITableViewController 

@property (strong, nonatomic) DetailDataSource * detailDataSource;

@end
