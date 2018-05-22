//
//  Recipient.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "Recipient.h"
#import "RecipientType.h"
#import "Device.h"
#import "Group.h"
#import "User.h"


@implementation Recipient

@synthesize recipientId;
@synthesize recipientType;
@synthesize name;
@synthesize deviceId;
@synthesize deviceName;
@synthesize selected;


#pragma mark - Initialization and cleanup

- (id)initWithGroup:(Group *)group
{
    self = [super init];
    if (self != nil)
    {
        recipientType = [[RecipientType alloc] initWithValue:RT_Group];
        self.recipientId = group.groupId;
        self.name = group.name;
    }
    return self;
}

- (id)initWithUser:(User *)user
{
    self = [super init];
    if (self != nil)
    {
        recipientType = [[RecipientType alloc] initWithValue:RT_User];
        self.recipientId = user.userId;
        self.name = user.fullName;
    }
    return self;
}

- (id)initWithUserOfDevice:(Device *)user
{
    self = [super init];
    if (self != nil)
    {
        recipientType = [[RecipientType alloc] initWithValue:RT_User];
        self.recipientId = user.userId;
        self.name = user.fullName;
    }
    return self;
}

- (id)initWithDevice:(Device *)device
{
    self = [super init];
    if (self != nil)
    {
        recipientType = [[RecipientType alloc] initWithValue:RT_UserDevice];
        self.recipientId = device.userId;
        self.name = device.fullName;
        self.deviceId = device.deviceId;
        self.deviceName = device.deviceName;
    }
    return self;
}



#pragma mark - Public methods

- (NSString *)name
{
    if (NSStringIsNilOrEmpty(name) && (recipientType.value == RT_Group) && (recipientId == AllUsersGroupId))
    {
        name = @"All Users";
    }
    
    return name;
}

- (NSComparisonResult)compare:(Recipient *)otherRecipient
{
	return [self.name compare:otherRecipient.name];
}

+ (NSString *)stringWithRecipients:(NSArray *)recipients
{
    if ((recipients == nil) || ([recipients count] == 0))
    {
        return @"None";
    }
    
    NSMutableString * toText = [NSMutableString stringWithCapacity:1024];
    
    for (Recipient * recipient in recipients)
    {
        [toText appendFormat:@"%@; ",recipient.name];
    }
    
    // remove the trailing separator
    [toText deleteCharactersInRange:NSMakeRange([toText length]-2,2)];
    
    return toText;
}


#pragma mark - Selectable methods

- (NSString *)title
{
    return self.name;
}


#pragma mark - Equality overrides

- (BOOL)isEqualToRecipient:(Recipient *)recipient 
{
	return (self.recipientType.value == recipient.recipientType.value) && 
           (self.recipientId == recipient.recipientId);
}

- (BOOL)isEqual:(id)other 
{
	if (other == self)
		return YES;
	
	if ((other == nil) || (! [other isKindOfClass:[self class]]))
		return NO;
    
	return [self isEqualToRecipient:other];
}

// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash
- (NSUInteger)hash 
{
	static const NSUInteger prime = 31;
	NSUInteger result = 1;
	
	result = prime * result + self.recipientType.value;
	result = prime * result + self.recipientId;
	
	return result;
} 

@end
