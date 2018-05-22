//
//  TransmitterInfoHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "TransmitterInfoHandler.h"
#import "TransmitterInfo.h"
#import "GpsLockStatus.h"
#import "Base64.h"


@implementation TransmitterInfoHandler
{
	NSMutableString * buffer;
	TransmitterInfo * transmitter;
}

#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		transmitter = [[TransmitterInfo alloc] init];
	}
	return self;
}




#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (TransmitterInfo *)result
{
	return transmitter;
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
	
	if ([elementName isEqualToString:@"DeviceId"]) 
	{
		transmitter.deviceId = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"DeviceName"]) 
	{
		transmitter.deviceName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"UserName"]) 
	{
		transmitter.userName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Description"]) 
	{
		transmitter.description = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"FullName"]) 
	{
		transmitter.fullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Latitude"])
	{
		transmitter.latitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Longitude"])
	{
		transmitter.longitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Thumbnail"])
	{
		NSData * imageData = [Base64 decode:buffer];
		transmitter.thumbnail = [UIImage imageWithData:imageData];
	}
	else if ([elementName isEqualToString:@"StartTime"]) 
	{
		transmitter.startTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"IsGpsActive"])
	{
		transmitter.isGpsActive = [buffer boolValue];
	}
	else if ([elementName isEqualToString:@"GpsLockStatus"])
	{
		transmitter.gpsLockStatus = [[GpsLockStatus alloc] initWithString:buffer];
	}
	else if ([elementName isEqualToString:@"LastGpsTime"])
	{
		transmitter.lastGpsTime = [RvXmlParserDelegate parseDate:buffer];
	}
}

@end
