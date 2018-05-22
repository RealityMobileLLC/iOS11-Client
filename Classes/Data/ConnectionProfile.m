//
//  ConnectionProfile.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ConnectionProfile.h"


@implementation ConnectionProfile

@synthesize host;
@synthesize path;
@synthesize useSsl;
@synthesize isExternal;
@synthesize port;


- (id)initWithHost:(NSString *)connectionHost 
			useSsl:(BOOL)ssl
		isExternal:(BOOL)external
			  port:(int)connectionPort 
			  path:(NSString *)connectionPath
{
	self = [super init];
	if (self != nil)
	{
		host       = connectionHost;
		path       = connectionPath;
		useSsl     = ssl;
		isExternal = external;
		port       = connectionPort;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder 
{
	host       = [coder decodeObjectForKey:@"Host"];
	path       = [coder decodeObjectForKey:@"Path"];
	useSsl     =  [coder decodeBoolForKey:@"Secure"];
	isExternal =  [coder decodeBoolForKey:@"External"];
	port       =  [coder decodeIntForKey:@"Port"];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeObject:host     forKey:@"Host"];
	[coder encodeObject:path     forKey:@"Path"];
	[coder encodeBool:useSsl     forKey:@"Secure"];
    [coder encodeBool:isExternal forKey:@"External"];
	[coder encodeInt:port        forKey:@"Port"];
}




- (NSString *)name
{
	NSString * name = nil;
	if (host != nil)
	{
		NSRange hostRange = [host rangeOfString:@"."];
		name = (hostRange.location == NSNotFound) ? host : [host substringToIndex:hostRange.location];
	}
	return name;
}


- (NSURL *)url
{
	NSURL * url = nil;
	
	if (! NSStringIsNilOrEmpty(host))
	{
		NSString * scheme = useSsl ? @"https" : @"http";
		
		const int maxPort = 65535;
		port = port < 0 ? 0 : port > maxPort ? maxPort : port;
		
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%d/%@", scheme, host, port, path]];
	}
	
	return url;
}


- (BOOL)isEqualToConnectionProfile:(ConnectionProfile *)profile 
{
	return [self.host isEqual:profile.host] &&
	       [self.path isEqual:profile.path] &&
		   self.useSsl == profile.useSsl &&
	       self.isExternal == profile.isExternal &&
	       self.port == profile.port;
}


- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;

    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToConnectionProfile:other];
}


// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash

- (NSUInteger)hash 
{
	static const NSUInteger prime = 31;
    NSUInteger result = 1;
	
	result = prime * result + (host ? [host hash] : 0);
	result = prime * result + (path ? [path hash] : 0);
	result = prime * result + (useSsl ? 1231 : 1237);
	result = prime * result + (isExternal ? 1231 : 1237);
	result = prime * result + port;
	
    return result;
}


@end
