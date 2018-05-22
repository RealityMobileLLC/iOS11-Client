//
//  CertificateException.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/6/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A certificate subject and a set of security policy exceptions agreed to by 
 *  the currently signed-on user.
 */
@interface CertificateException : NSObject <NSCoding>

@property (strong, nonatomic,readonly) NSString * subject;
@property (strong, nonatomic,readonly) NSData   * exceptions;

/**
 *  Initializes a new CertificateException.
 *
 *  @param subject    Certificate subject.
 *  @param exceptions Certificate policy exceptions from SecTrustCopyExceptions.
 */
- (id)initWithSubject:(NSString *)subject andExceptions:(NSData *)exceptions;

@end
