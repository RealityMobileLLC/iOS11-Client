//
//  CameraTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 2/16/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CameraTableViewCell : UITableViewCell 

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView * thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel     * captionLabel;
@property (weak, nonatomic) IBOutlet UILabel     * descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView * ptzIcon;
@property (weak, nonatomic) IBOutlet UIImageView * locationIcon;
@property (weak, nonatomic) IBOutlet UIImageView * commentsIcon;
@property (weak, nonatomic) IBOutlet UILabel     * commentsLabel;
@property (weak, nonatomic) IBOutlet UILabel     * lengthLabel;

@end
