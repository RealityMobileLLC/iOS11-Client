//
//  CommandHistoryResult.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandHistoryResult.h"


@implementation CommandHistoryResult

@synthesize commands;
@synthesize moreResults;


- (id)initWithCommands:(NSArray *)cmds andMoreResultsFlag:(BOOL)more
{
	self = [super init];
	if (self != nil)
	{
		commands = cmds;
		moreResults = more;
	}
	return self;
}

@end
