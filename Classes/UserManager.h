//
//  UserManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/20/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Singleton that manages the list of signed on users.
 */
@interface UserManager : NSObject

/**
 *  Array of UserDevice representing signed on RealityVision users.
 */
@property (nonatomic,readonly) NSArray * users;

/**
 *  Gets the singleton instance of the UserManager.
 */
+ (UserManager *)instance;

@end
