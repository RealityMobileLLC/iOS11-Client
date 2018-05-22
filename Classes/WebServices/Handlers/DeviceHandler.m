//
//  DeviceHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "DeviceHandler.h"
#import "Device.h"
#import "ArrayHandler.h"
#import "ViewerInfoHandler.h"


@implementation DeviceHandler
{
	NSMutableString     * buffer;
	Device              * device;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		device = [[Device alloc] init];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (Device *)result
{
	return device;
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
		device.viewers = handler.result;
	}
	else if ([elementName isEqualToString:@"LastHeardFrom"]) 
	{
		device.lastHeardFrom = [RvXmlParserDelegate parseDate:buffer];
	} 
	else if ([elementName isEqualToString:@"DeviceName"]) 
	{
		device.deviceName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"DeviceID"]) 
	{
		device.deviceId = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Latitude"]) 
	{
		device.latitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Longitude"]) 
	{
		device.longitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"isCamera"]) 
	{
		device.isCamera = [buffer boolValue];
	}
	else if ([elementName isEqualToString:@"isViewer"]) 
	{
		device.isViewer = [buffer boolValue];
	}
	else if ([elementName isEqualToString:@"isPanic"]) 
	{
		device.isPanic = [buffer boolValue];
	}
	else if ([elementName isEqualToString:@"UserID"]) 
	{
		device.userId = [buffer intValue];
	}
	else if ([elementName isEqualToString:@"Username"]) 
	{
		device.userName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"FullName"]) 
	{
		device.fullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"LastVideoTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			device.lastVideoTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"LastGPSTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			device.lastGpsTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"GpsLockStatus"]) 
	{
		device.gpsLockStatus = [[GpsLockStatus alloc] initWithString:buffer];
	}
	else if ([elementName isEqualToString:@"isGps"]) 
	{
		device.isGps = [buffer boolValue];
	}
	else if ([elementName isEqualToString:@"isSignedOn"]) 
	{
		device.isSignedOn = [buffer boolValue];
	}
}

@end
