//
//  SessionResult.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A list of sessions returned from a SearchVideoHistory request.
 *  
 *  @todo this should really be immutable (all properties readonly)
 */
@interface SessionResult : NSObject 

/**
 *  List of sessions.
 */
@property (strong, nonatomic) NSArray * sessions;

/**
 *  Indicates whether the server has more sessions that can be retrieved
 *  for this user.
 */
@property (nonatomic) BOOL hasMoreResults;

/**
 *  Total number of sessions for this user.
 */
@property (nonatomic) int totalResults;

@end
