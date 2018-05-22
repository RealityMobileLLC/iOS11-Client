//
//  GroupHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "GroupHandler.h"
#import "Group.h"
#import "ArrayOfNSNumberHandler.h"


@interface GroupHandler()
{
	NSMutableString * buffer;
	Group           * group;
}
@end


@implementation GroupHandler


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		group = [[Group alloc] init];
		handler = nil;
	}
	return self;
}




#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (Group *)result
{
	return group;
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
	else if ([elementName isEqualToString:@"Users"]) 
	{
		handler = [[ArrayOfNSNumberHandler alloc] init];
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
	else if ([elementName isEqualToString:@"Users"]) 
	{
		group.userIds = handler.result;
		handler = nil;
	}
	else if ([elementName isEqualToString:@"Id"]) 
	{
		group.groupId = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"Name"]) 
	{
		group.name = [NSString stringWithString:buffer];
	}
}

@end
