//
//  Attachment.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AttachmentPurposeType;


/**
 *  An attachment sent as part of a Command.
 */
@interface Attachment : NSObject 

@property (nonatomic)         int                     attachmentId;
@property (strong, nonatomic) NSString              * format;
@property (strong, nonatomic) AttachmentPurposeType * purpose;
@property (strong, nonatomic) NSData                * data;

@end
