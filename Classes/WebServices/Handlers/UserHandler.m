//
//  UserHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserHandler.h"
#import "User.h"
#import "ArrayHandler.h"
#import "ViewerInfoHandler.h"


@implementation UserHandler
{
	NSMutableString * buffer;
	User            * user;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		user = [[User alloc] init];
		handler = nil;
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (User *)result
{
	return user;
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
		// forward to responsible handler
		[handler parser:theParser 
		didStartElement:elementName 
		   namespaceURI:namespaceURI 
		  qualifiedName:qName 
			 attributes:attributeDict];
	}
	else if ([elementName isEqualToString:@"Viewers"]) 
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"ViewerInfo" andParserClass:[ViewerInfoHandler class]];
	}
}

- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	if (handler != nil) 
	{
		// forward to responsible handler
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
		// forward to responsible handler
		[handler parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
	else if ([elementName isEqualToString:@"Viewers"]) 
	{
		user.viewers = handler.result;
	}
	else if ([elementName isEqualToString:@"UserID"]) 
	{
		user.userId = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"Username"]) 
	{
		user.userName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"FullName"]) 
	{
		user.fullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Description"]) 
	{
		user.description = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"LastHeardFrom"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			user.lastHeardFrom = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"LastVideoTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			user.lastVideoTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"LastGpsTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			user.lastGpsTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
}

@end
