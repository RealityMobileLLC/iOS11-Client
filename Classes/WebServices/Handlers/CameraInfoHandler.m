//
//  CameraInfoHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraInfoHandler.h"
#import "CameraInfo.h"
#import "Base64.h"


@implementation CameraInfoHandler
{
	NSMutableString * buffer;
	CameraInfo      * camera;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		camera = [[CameraInfo alloc] init];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (CameraInfo *)result
{
	return camera;
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
	
	if ([elementName isEqualToString:@"Server"]) 
	{
		camera.server = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"Port"]) 
	{
		camera.port = [buffer longLongValue];
	}
	else if ([elementName isEqualToString:@"URI"]) 
	{
		camera.uri = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Caption"]) 
	{
		camera.caption = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"CameraType"]) 
	{
		camera.cameraType = [buffer intValue];
	}
	else if ([elementName isEqualToString:@"Country"]) 
	{
		camera.country = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Province"]) 
	{
		camera.province = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"City"]) 
	{
		camera.city = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Latitude"]) 
	{
		camera.latitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Longitude"]) 
	{
		camera.longitude = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Description"]) 
	{
		camera.description = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Range"]) 
	{
		camera.range = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Tilt"]) 
	{
		camera.tilt = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"Heading"]) 
	{
		camera.heading = [buffer doubleValue];
	}
	else if ([elementName isEqualToString:@"ControlStub"]) 
	{
		camera.controlStub = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlRight"]) 
	{
		camera.controlRight = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlLeft"]) 
	{
		camera.controlLeft = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlUp"]) 
	{
		camera.controlUp = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlDown"]) 
	{
		camera.controlDown = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlHome"]) 
	{
		camera.controlHome = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlZoomIn"]) 
	{
		camera.controlZoomIn = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlZoomOut"]) 
	{
		camera.controlZoomOut = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlPan"]) 
	{
		camera.controlPan = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ControlTilt"]) 
	{
		camera.controlTilt = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"LastHeartbeat"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			BOOL lastHeartbeat   = [buffer isEqualToString:@"true"];
			camera.lastHeartbeat = [NSValue value:&lastHeartbeat withObjCType:@encode(BOOL)];
		}
	}
	else if ([elementName isEqualToString:@"LastHeartbeatTime"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			camera.lastHeartbeatTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"Inactive"]) 
	{
		camera.inactive = [buffer isEqualToString:@"true"];
	}
	else if ([elementName isEqualToString:@"Thumbnail"])
	{
		NSData * imageData = [Base64 decode:buffer];
		camera.thumbnail   = [UIImage imageWithData:imageData];
	}
	else if ([elementName isEqualToString:@"StartTime"])
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			camera.startTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
}

@end
