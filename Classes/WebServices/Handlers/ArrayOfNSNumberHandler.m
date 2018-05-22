//
//  ArrayOfNSNumberHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "ArrayOfNSNumberHandler.h"


@implementation ArrayOfNSNumberHandler
{
	NSMutableString * buffer;
	NSMutableArray  * numbers;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer  = [[NSMutableString alloc] initWithCapacity:1024];
		numbers = [[NSMutableArray alloc]  initWithCapacity:20];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (NSArray *)result
{
	return numbers;
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
	
	if ([elementName isEqualToString:@"int"]) 
	{
		NSNumber * value = [[NSNumber alloc] initWithInt:[buffer intValue]];
		[numbers addObject:value];
	}
	
	// @todo add other NSNumber-supported element types as needed
}

@end
