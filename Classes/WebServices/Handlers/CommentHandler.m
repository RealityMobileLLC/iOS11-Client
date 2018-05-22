//
//  CommentHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommentHandler.h"
#import "Comment.h"
#import "Base64.h"


@implementation CommentHandler
{
	NSMutableString * buffer;
	Comment         * comment;
}


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		comment = [[Comment alloc] init];
	}
	return self;
}


#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (Comment *)result
{
	return comment;
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	[buffer setString:@""];
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	[buffer appendString:string];
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ([elementName isEqualToString:@"CommentId"]) 
	{
		comment.commentId = [buffer longLongValue];
	}
	else if ([elementName isEqualToString:@"UserName"]) 
	{
		comment.username = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"EntryTime"]) 
	{
		comment.entryTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"ReferenceFrameId"]) 
	{
		comment.isFrameComment = ! NSStringIsNilOrEmpty(buffer);
		
		if (comment.isFrameComment)
		{
			comment.frameId = [buffer intValue];
		}
	}
	else if ([elementName isEqualToString:@"ReferenceFrameTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			comment.frameTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"Comments"]) 
	{
		comment.comments = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Thumbnail"])
	{
		NSData * imageData    = [Base64 decode:buffer];
		comment.thumbnail = [UIImage imageWithData:imageData];
	}
}

@end
