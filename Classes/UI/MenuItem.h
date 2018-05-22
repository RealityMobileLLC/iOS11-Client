//
//  MenuItem.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A menu item consisting of a label and an image.
 */
@interface MenuItem : NSObject 

/**
 *  The label to display with the menu item.
 */
@property (strong, nonatomic,readonly) NSString * label;

/**
 *  The file name for the image to display with the menu item.
 */
@property (strong, nonatomic,readonly) NSString * image;

/**
 *  A tag to identify the menu item.
 */
@property (nonatomic) NSInteger tag;

/**
 *  Initializes a MenuItem.
 *
 *  @param label The label to display with the menu item.
 *  @param image The file name for the image to display with the menu item.
 *  @return An initialized MenuItem object or nil if the object could not be 
 *           initialized.
 */
- (id)initWithLabel:(NSString *)label image:(NSString *)image;

@end
