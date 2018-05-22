//
//  RvXmlParserDelegate.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RvXmlParserDelegate.h"


@implementation RvXmlParserDelegate
{
	NSUInteger embeddedElementCount;
}


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		embeddedElementCount = 0;
	}
	return self;
}


- (BOOL)isParsingElement
{
	return embeddedElementCount != 0;
}


- (id)result
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


+ (NSDate *)parseDate:(NSString *)dateString
{
	static NSDateFormatter * dateFormatter = nil;
	
	if (dateFormatter == nil)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
	}

	// NSDateFormatter is picky when it comes to strings with fractional seconds
	NSRange fractionalSeconds = [dateString rangeOfString:@"."];
	
	if (fractionalSeconds.location == NSNotFound)
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
	}
	else 
	{
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
	}

	
	// convert Zulu to timezone offset because NSDateFormatter doesn't do Zulu
	NSString * newDateString = [dateString stringByReplacingOccurrencesOfString:@"Z" 
																	 withString:@"-0000"];
	
	return [dateFormatter dateFromString:newDateString];
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	embeddedElementCount++;
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	NSAssert(embeddedElementCount>0,@"RvXmlParserDelegate received more end elements than start elements");
	embeddedElementCount--;
}

@end
