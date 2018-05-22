//
//  IgnoreHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/27/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "IgnoreHandler.h"


@implementation IgnoreHandler


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	return self;
}




#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (id)result
{
	return nil;
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
}

@end
