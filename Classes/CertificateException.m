//
//  CertificateException.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/6/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CertificateException.h"

static NSString * const KEY_SUBJECT    = @"Subject";
static NSString * const KEY_EXCEPTIONS = @"Exceptions";


@implementation CertificateException

@synthesize subject;
@synthesize exceptions;


- (id)initWithSubject:(NSString *)theSubject andExceptions:(NSData *)theExceptions
{
	self = [super init];
	if (self != nil)
	{
		subject    = theSubject;
		exceptions = theExceptions;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder 
{
	subject    = [coder decodeObjectForKey:KEY_SUBJECT];
	exceptions = [coder decodeObjectForKey:KEY_EXCEPTIONS];
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeObject:subject    forKey:KEY_SUBJECT];
	[coder encodeObject:exceptions forKey:KEY_EXCEPTIONS];
}



@end
