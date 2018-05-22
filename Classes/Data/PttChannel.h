//
//  PttChannel.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/27/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A PttChannel provides information needed to communicate with a Push-To-Talk channel.
 *  PttChannel objects are immutable.
 */
@interface PttChannel : NSObject

@property (nonatomic,strong,readonly) NSString * name;
@property (nonatomic,strong,readonly) NSString * sipUri;
@property (nonatomic,strong,readonly) NSString * codec;
@property (nonatomic,strong,readonly) NSString * pin;

/**
 *  Returns an initialized RVPttChannel.
 */
- (id)initWithName:(NSString *)name 
		   address:(NSString *)sipUri 
			 codec:(NSString *)codec 
			   pin:(NSString *)pin;

@end
