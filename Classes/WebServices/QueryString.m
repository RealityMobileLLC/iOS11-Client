//
//  QueryString.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "QueryString.h"
#import "XmlFactory.h"


@implementation QueryString
{
	NSMutableString * query;
}

@synthesize query;


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		query = [[NSMutableString alloc] init];
	}
	return self;
}


- (id)initWithParameters:(NSArray *)parameters
{
	self = [self init];
	if (self != nil)
	{
		// initialize string with prefix and use ? to separate prefix from first parameter
		[query appendString:[parameters objectAtIndex:0]];
		NSString * separator = @"?";
		
		// append remaining parameters separated by &
		for (NSUInteger index = 1; index < [parameters count]; index++)
		{
			NSString * name;
			NSString * value;
			
			NSString * nameValuePair = [parameters objectAtIndex:index];
			NSRange    pos           = [nameValuePair rangeOfString:@"="];
			
			if (pos.location == NSNotFound) 
			{
				name  = nameValuePair;
				value = nil;
			}
			else
			{
				name  = [nameValuePair substringToIndex:pos.location];
				value = [nameValuePair substringFromIndex:pos.location + pos.length];
			}
			
			[self append:name stringValue:value separator:separator];
			separator = @"&";
		}
	}
	return self;
}




#pragma mark -
#pragma mark Public methods

- (void)append:(NSString *)name stringValue:(NSString *)value
{
	[self append:name stringValue:value separator:@"&"];
}


- (void)append:(NSString *)name boolValue:(BOOL)value
{
	NSString * stringValue = value ? @"true" : @"false";
	[self append:name stringValue:stringValue];
}


- (void)append:(NSString *)name intValue:(int)value
{
	NSString * stringValue = [NSString stringWithFormat:@"%d",value];
	[self append:name stringValue:stringValue];
}


- (void)append:(NSString *)name dateValue:(NSDate *)value
{
	NSString * stringValue = [XmlFactory formatDate:value];
	[self append:name stringValue:stringValue];
}


+ (NSString *)getParameter:(NSString *)name fromQuery:(NSString *)query
{
	NSArray * parameters = [query componentsSeparatedByString:@"&"];
	
	for (NSString * nameValuePair in parameters)
	{
		NSString * thisName;
		NSString * thisValue;
		
		NSRange pos = [nameValuePair rangeOfString:@"="];
		if (pos.location == NSNotFound) 
		{
			thisName  = [QueryString urlDecodeString:nameValuePair];
			thisValue = @"";
		}
		else
		{
			thisName  = [QueryString urlDecodeString:[nameValuePair substringToIndex:pos.location]];
			thisValue = [QueryString urlDecodeString:[nameValuePair substringFromIndex:pos.location + pos.length]];
		}
		
		if ([thisName isEqualToString:name])
		{
			return thisValue;
		}
	}
	
	return nil;
}


+ (NSMutableArray *)getParametersFromQuery:(NSString *)query
{
    // the prefix will be the first object in the parameter list and will NOT be url-encoded
    // each additional object in the parameter list will be url-encoded when the query is turned back into a url
	NSString * prefix = @"";
    
	NSRange pos = [query rangeOfString:@"?"];
	if (pos.location != NSNotFound)
	{
        // if ? found, everything before it is the prefix and everything following is parameters
		prefix = [query substringToIndex:pos.location];
		query  = [query substringFromIndex:pos.location + pos.length];
	}
    else if ([query hasPrefix:@"http://"] || [query hasPrefix:@"https://"])
    {
        // if no ? found but query starts with a scheme, the entire query is the prefix and there are no parameters
        prefix = query;
        query = @"";
    }
	
	NSArray        * parameters        = [query componentsSeparatedByString:@"&"];
	NSMutableArray * decodedParameters = [NSMutableArray arrayWithCapacity:[parameters count]+1];
	
	[decodedParameters addObject:prefix];
	
	for (NSString * param in parameters)
	{
		[decodedParameters addObject:[QueryString urlDecodeString:param]];
	}
	
	return decodedParameters;
}


+ (NSString *)urlEncodeString:(NSString *)string
{
	NSString * result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																			(__bridge CFStringRef)string,
																			NULL,
																			(CFStringRef)@"!*'();:@&=+$,/?%#[]-",
																			kCFStringEncodingUTF8);
	return result;
}


+ (NSString *)urlDecodeString:(NSString *)string
{
	return [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


#pragma mark -
#pragma mark Private methods

- (void)append:(NSString *)name 
   stringValue:(NSString *)value 
	 separator:(NSString *)separator
{
	if ([query length] > 0)
	{
		[query appendString:separator];
	}
	
	NSString * urlEncodedName = [QueryString urlEncodeString:name];
	
	if (value != nil)
	{
		NSString * urlEncodedValue = [QueryString urlEncodeString:value];
		[query appendFormat:@"%@=%@",urlEncodedName,urlEncodedValue];
	}
	else 
	{
		[query appendString:urlEncodedName];
	}
}

@end
