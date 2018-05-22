//
//  RvError.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/17/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RvError.h"

NSString * const RV_DOMAIN = @"RvError";
NSString * const RVHttpStatusKey = @"RVHttpStatus";
NSString * const RVErrorMessageKey = @"RVErrorMessage";


@implementation RvError

- (id)initWithCode:(int)errorCode userInfo:(NSDictionary *)userInfo
{
	self = [super initWithDomain:RV_DOMAIN code:errorCode userInfo:userInfo];
	return self;
}

- (NSString *)message
{
    return [self.userInfo objectForKey:RVErrorMessageKey];
}

- (NSNumber *)httpStatus
{
    return [self.userInfo objectForKey:RVHttpStatusKey];
}

+ (RvError *)rvErrorWithLocalizedDescription:(NSString *)description
{
	NSArray      * objArray = [NSArray arrayWithObjects:description, nil];
	NSArray      * keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil];
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjects:objArray
														  forKeys:keyArray];
	
	return [[RvError alloc] initWithCode:RV_ERROR userInfo:userInfo];
}

+ (RvError *)rvErrorWithHttpStatus:(UInt32)status message:(NSString *)errorMsg
{
	NSString * description = [NSString stringWithFormat:NSLocalizedString(@"Received HTTP status: %d",
                                                                          @"Received HTTP status error format"), status];
    NSNumber * statusCode  = [NSNumber numberWithUnsignedInteger:status];
    NSString * message     = (errorMsg != nil) ? [NSString stringWithString:errorMsg] : @"";
    
	NSArray      * objArray = [NSArray arrayWithObjects:description, statusCode, message, nil];
	NSArray      * keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, RVHttpStatusKey, RVErrorMessageKey, nil];
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
	
	return [[RvError alloc] initWithCode:RV_HTTP_ERROR userInfo:userInfo];
}

+ (RvError *)rvUserCancelled
{
    NSString     * description = NSLocalizedString(@"User cancelled request",@"User cancelled request");
	NSArray      * objArray = [NSArray arrayWithObjects:description, nil];
	NSArray      * keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil];
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjects:objArray
														  forKeys:keyArray];
	
	return [[RvError alloc] initWithCode:RV_USER_CANCEL userInfo:userInfo];
}

+ (RvError *)rvNotSignedOn
{
    NSString     * description = NSLocalizedString(@"Client device is not signed on",@"Client device is not signed on");
	NSArray      * objArray = [NSArray arrayWithObjects:description, nil];
	NSArray      * keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil];
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjects:objArray
														  forKeys:keyArray];
	
	return [[RvError alloc] initWithCode:RV_NOT_SIGNED_ON userInfo:userInfo];
}

@end
