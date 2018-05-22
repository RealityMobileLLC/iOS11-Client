//
//  CommandHistoryResult.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A list of commands returned from a GetCommandHistory request.
 */
@interface CommandHistoryResult : NSObject 

/**
 *  List of commands.
 */
@property (strong, nonatomic) NSArray * commands;

/**
 *  Indicates whether the server has more commands that can be retrieved
 *  for this device.
 */
@property (nonatomic) BOOL moreResults;

/**
 *  Initializes a CommandHistoryResult object.
 */
- (id)initWithCommands:(NSArray *)commands andMoreResultsFlag:(BOOL)moreResults;

@end
