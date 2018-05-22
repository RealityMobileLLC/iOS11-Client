//
//  FavoriteEntry.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Command;


/**
 *  Indicates a favorite that has been created locally, not retrieved from the RealityVision server.
 */
extern int InvalidFavoriteId;   // @todo change constant name


/**
 *  A command or camera bookmarked as a favorite.
 */
@interface FavoriteEntry : NSObject 

@property (nonatomic)         int        favoriteId;
@property (strong, nonatomic) NSString * caption;
@property (strong, nonatomic) Command  * openCommand;

@end
