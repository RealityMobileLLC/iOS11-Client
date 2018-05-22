//
//  CameraStatusTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/17/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  A custom UITableViewCell for displaying status icons about a camera feed.
 */
@interface CameraStatusTableViewCell : UITableViewCell 

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView * locationImage;
@property (weak, nonatomic) IBOutlet UILabel     * locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView * ptzImage;
@property (weak, nonatomic) IBOutlet UILabel     * ptzLabel;

@end
