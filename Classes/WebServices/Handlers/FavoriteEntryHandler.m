//
//  FavoriteEntryHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "FavoriteEntryHandler.h"
#import "FavoriteEntry.h"
#import "CommandHandler.h"


@implementation FavoriteEntryHandler
{
@private
	NSMutableString     * buffer;
	FavoriteEntry       * favorite;
	RvXmlParserDelegate * handler;
}


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		favorite = [[FavoriteEntry alloc] init];
		handler = nil;
	}
	return self;
}


#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (FavoriteEntry *)result
{
	return favorite;
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
	[buffer setString:@""];
	
	if (handler != nil) 
	{
		// Forward to responsible handler
		[handler parser:theParser 
		didStartElement:elementName 
		   namespaceURI:namespaceURI 
		  qualifiedName:qName 
			 attributes:attributeDict];
	}
	else if ([elementName isEqualToString:@"OpenCommand"]) 
	{
		handler = [[CommandHandler alloc] init];
	}
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	if (handler != nil) 
	{
		// Forward to responsible handler
		[handler parser:theParser foundCharacters:string];
	}
	else 
	{
		[buffer appendString:string];
	}
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ((handler != nil) && (handler.isParsingElement))
	{
		// Forward to responsible handler
		[handler parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
	else if ([elementName isEqualToString:@"OpenCommand"]) 
	{
		favorite.openCommand = handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"FavoriteId"]) 
	{
		favorite.favoriteId = [buffer intValue];
	}
	else if ([elementName isEqualToString:@"Caption"]) 
	{
		favorite.caption = [NSString stringWithString:buffer];
	}
}

@end
