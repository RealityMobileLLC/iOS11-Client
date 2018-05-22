//
//  Group.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  RealityVision Group ID reserved for All Users.
 */
extern const int AllUsersGroupId;   // @todo change const name


/**
 *  A RealityVision group consisting of one or more users.
 */
@interface Group : NSObject 

@property (nonatomic)         int        groupId;
@property (strong, nonatomic) NSString * name;
@property (strong, nonatomic) NSArray  * userIds;

+ (Group *)allUsersGroup;

@end
