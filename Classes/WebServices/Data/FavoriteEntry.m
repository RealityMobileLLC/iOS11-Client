//
//  FavoriteEntry.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "FavoriteEntry.h"
#import "Command.h"

int InvalidFavoriteId = -1;


@implementation FavoriteEntry

@synthesize favoriteId;
@synthesize caption;
@synthesize openCommand;


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		favoriteId = InvalidFavoriteId;
	}
	return self;
}


#pragma mark - Equality overrides

- (BOOL)isEqualToFavoriteEntry:(FavoriteEntry *)favoriteEntry 
{
	if (self.favoriteId == InvalidFavoriteId || favoriteEntry.favoriteId == InvalidFavoriteId)
	{
		return [self.caption isEqualToString:favoriteEntry.caption];
	}
	
	return (self.favoriteId == favoriteEntry.favoriteId);
}

- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;
	
    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToFavoriteEntry:other];
}

// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash

- (NSUInteger)hash 
{
    return favoriteId;
}

@end
