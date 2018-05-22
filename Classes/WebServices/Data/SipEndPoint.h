//
//  SipEndPoint.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/25/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A Push-To-Talk channel endpoint.
 */
@interface SipEndPoint : NSObject

@property (strong,nonatomic) NSString * endpoint;
@property (strong,nonatomic) NSString * codec;
@property (strong,nonatomic) NSString * pin;

@end
