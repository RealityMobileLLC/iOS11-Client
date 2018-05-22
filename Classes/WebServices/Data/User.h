//
//  User.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A RealityVision user.
 */
@interface User : NSObject 

@property (nonatomic)         int        userId;
@property (strong, nonatomic) NSString * userName;
@property (strong, nonatomic) NSString * fullName;
@property (strong, nonatomic) NSString * description;
@property (strong, nonatomic) NSDate   * lastHeardFrom;
@property (strong, nonatomic) NSDate   * lastVideoTime;
@property (strong, nonatomic) NSDate   * lastGpsTime;
@property (strong, nonatomic) NSArray  * viewers;

@end
