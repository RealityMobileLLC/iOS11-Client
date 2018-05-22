//
//  AboutViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/10/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  View Controller used to present the About RealityVision dialog.
 */
@interface AboutViewController : UIViewController


// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UILabel     * productLabel;
@property (weak, nonatomic) IBOutlet UILabel     * versionLabel;
@property (weak, nonatomic) IBOutlet UILabel     * copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel     * supportUrlLabel;
@property (weak, nonatomic) IBOutlet UILabel     * userLabel;
@property (weak, nonatomic) IBOutlet UILabel     * deviceIdLabel;
@property (weak, nonatomic) IBOutlet UIImageView * productLogoView;

- (IBAction)dismissAction:(id)sender;

@end
