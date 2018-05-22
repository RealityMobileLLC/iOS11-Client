//
//  Channel.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/24/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A Push-To-Talk Channel name and description.
 */
@interface Channel : NSObject <NSCoding>

@property (strong,nonatomic) NSString * name;
@property (strong,nonatomic) NSString * description;

@end
