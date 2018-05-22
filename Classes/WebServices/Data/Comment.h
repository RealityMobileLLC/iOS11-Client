//
//  Comment.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A comment associated with a session or frame.
 */
@interface Comment : NSObject 

@property (nonatomic)         long long   commentId;
@property (strong, nonatomic) NSString  * comments;
@property (strong, nonatomic) NSDate    * entryTime;
@property (strong, nonatomic) NSString  * username;
@property (nonatomic)         BOOL        isFrameComment;
@property (nonatomic)         int         frameId;
@property (strong, nonatomic) NSDate    * frameTime;
@property (strong, nonatomic) UIImage   * thumbnail;

/**
 *  Returns an NSComparisonResult value that indicates the ordering of the 
 *  event times of the receiver and the given Comment object.  The ordering
 *  is reverse chronological (i.e., latest date first).
 *  
 *  @param aComment The comment whose event time is to be compared with the receiver.
 *  
 *  @return NSOrderedAscending if the comment's event time is earlier than the receiver's; 
 *          NSOrderedSame if they’re equal; and NSOrderedDescending if the comment's 
 *          event time is later than the receiver’s.
 */
- (NSComparisonResult)compareEntryTime:(Comment *)aComment;

@end
