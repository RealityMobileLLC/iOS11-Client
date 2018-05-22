//
//  Selectable.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Protocol used to define objects that can be displayed in a selectable list.
 *  Frequently this is for objects displayed in a UITableView using a cell with a
 *  UITableViewCellAccessoryCheckmark if the object has been selected.
 */
@protocol Selectable <NSObject>

/**
 *  The title, or name, of the Selectable object.
 */
@property (nonatomic,readonly) NSString * title;

/**
 *  Indicates whether the object is currently selected.
 */
@property (nonatomic) BOOL selected;

@end
