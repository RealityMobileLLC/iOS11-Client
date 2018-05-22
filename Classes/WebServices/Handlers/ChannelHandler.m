//
//  ChannelHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/23/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "ChannelHandler.h"
#import "Channel.h"



@implementation ChannelHandler
{
	NSMutableString * buffer;
	Channel         * channel;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		channel = [[Channel alloc] init];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (Channel *)result
{
	return channel;
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
	
	if ([elementName isEqualToString:@"Name"]) 
	{
		channel.name = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Description"]) 
	{
		channel.description = [NSString stringWithString:buffer];
	} 
}

@end
