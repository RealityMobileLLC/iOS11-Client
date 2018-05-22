//
//  Comment.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "Comment.h"


@implementation Comment

@synthesize commentId;
@synthesize comments;
@synthesize entryTime;
@synthesize username;
@synthesize isFrameComment;
@synthesize frameId;
@synthesize frameTime;
@synthesize thumbnail;


- (NSComparisonResult)compareEntryTime:(Comment *)other
{
	return [other.entryTime compare:self.entryTime];
}

@end
