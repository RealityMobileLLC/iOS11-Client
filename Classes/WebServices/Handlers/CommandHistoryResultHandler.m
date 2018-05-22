//
//  CommandHistoryHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandHistoryResultHandler.h"
#import "ArrayHandler.h"
#import "CommandHandler.h"
#import "CommandHistoryResult.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandHistoryResultHandler
{
	NSMutableString      * buffer;
	CommandHistoryResult * commandHistory;
	RvXmlParserDelegate  * handler;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		commandHistory = [[CommandHistoryResult alloc] init];
		handler = nil;
	}
	return self;
}


#pragma mark - WebServiceResponseHandler methods

- (id)parseResponse:(NSData *)xml
{
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xml];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    
	BOOL success = [parser parse];
	if (! success)
	{
		DDLogError(@"Failed to parse CommandHistoryResult");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (CommandHistoryResult *)result
{
	return commandHistory;
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
	else if ([elementName isEqualToString:@"Commands"]) 
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"Command" andParserClass:[CommandHandler class]];
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
	else if ([elementName isEqualToString:@"Commands"]) 
	{
		commandHistory.commands = handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"MoreResults"]) 
	{
		commandHistory.moreResults = [buffer isEqualToString:@"true"];
	} 
}

@end
