//
//  ArrayHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "ArrayHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ArrayHandler
{
	NSMutableArray * array;
}

@synthesize elementName;
@synthesize parserClass;


#pragma mark - Initialization and cleanup

- (id)initWithElementName:(NSString *)theElementName andParserClass:(Class)theParserClass
{
	NSAssert([theElementName length]>0,@"elementName is required");
	NSAssert([theParserClass isSubclassOfClass:[RvXmlParserDelegate class]],@"");
	
	self = [super init];
	if (self != nil)
	{
		array = [[NSMutableArray alloc] initWithCapacity:20];
		elementName = [theElementName copy];
		parserClass = theParserClass;
	}
	return self;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
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
		DDLogError(@"Failed to parse array of %@", elementName);
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (NSArray *)result
{
	return array;
}

- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)theElementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:theElementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
	if (handler != nil)
	{
		// forward to responsible handler
		[handler parser:theParser 
		didStartElement:theElementName 
		   namespaceURI:namespaceURI 
		  qualifiedName:qName 
			 attributes:attributeDict];
	}
	else if ([theElementName isEqualToString:elementName])
	{
		handler = [[parserClass alloc] init];
	}
}

- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	// forward to responsible handler
	[handler parser:theParser foundCharacters:string];
}

- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)theElementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:theElementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ([handler isParsingElement])
	{
		// forward to responsible handler
		[handler parser:theParser didEndElement:theElementName namespaceURI:namespaceURI qualifiedName:qName];
	}
	else if ([theElementName isEqualToString:elementName]) 
	{
		[array addObject:handler.result];
		handler = nil;
	}
}

@end
