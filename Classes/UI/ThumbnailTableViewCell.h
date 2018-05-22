//
//  ThumbnailTableViewCell.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ThumbnailTableViewCell : UITableViewCell

+ (NSString *)reuseIdentifier;

@property (weak, nonatomic) IBOutlet UIImageView * imageView;

@end
