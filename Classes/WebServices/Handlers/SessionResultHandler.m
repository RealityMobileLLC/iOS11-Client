//
//  SessionResultHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "SessionResultHandler.h"
#import "ArrayHandler.h"
#import "SessionHandler.h"
#import "SessionResult.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation SessionResultHandler
{
	NSMutableString * buffer;
	SessionResult   * sessionResult;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		sessionResult = [[SessionResult alloc] init];
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
		DDLogError(@"Failed to parse SessionResult");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (SessionResult *)result
{
	return sessionResult;
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
	else if ([elementName isEqualToString:@"Sessions"]) 
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"Session" andParserClass:[SessionHandler class]];
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
	else if ([elementName isEqualToString:@"Sessions"]) 
	{
		sessionResult.sessions = handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"HasMoreResults"]) 
	{
		sessionResult.hasMoreResults = [buffer isEqualToString:@"true"];
	} 
	else if ([elementName isEqualToString:@"TotalResults"]) 
	{
		sessionResult.totalResults = [buffer intValue];
	} 
}

@end
