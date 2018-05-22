//
//  Group.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "Group.h"

const int AllUsersGroupId = 0;


@implementation Group

@synthesize groupId;
@synthesize name;
@synthesize userIds;


+ (Group *)allUsersGroup
{
    Group * allUsersGroup = [[Group alloc] init];
    allUsersGroup.groupId = AllUsersGroupId;
    allUsersGroup.name = NSLocalizedString(@"All Users",@"All users group");
    return allUsersGroup;
}

@end
