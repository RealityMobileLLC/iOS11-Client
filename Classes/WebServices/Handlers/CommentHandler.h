//
//  CommentHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"

@class Comment;


/**
 *  Parses an XML Comment element and returns a Comment object.
 */
@interface CommentHandler : RvXmlParserDelegate

@end