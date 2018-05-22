//
//  ArrayOfNameValueHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ArrayOfNameValueHandler.h"


@implementation ArrayOfNameValueHandler
{
	NSMutableDictionary * arrayOfNameValue;
	NSMutableString     * buffer;
	NSString            * currentName;
	NSString            * currentValue;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		arrayOfNameValue = [[NSMutableDictionary alloc] initWithCapacity:50];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (NSDictionary *)result
{
	return arrayOfNameValue;
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
	
	if ([elementName isEqualToString:@"NameValue"]) 
	{
		[arrayOfNameValue setValue:currentValue forKey:currentName];
		currentName = nil;
		currentValue = nil;
	}
	else if ([elementName isEqualToString:@"name"]) 
	{
		currentName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"value"])
	{
		currentValue = [NSString stringWithString:buffer];
	}
}

@end
