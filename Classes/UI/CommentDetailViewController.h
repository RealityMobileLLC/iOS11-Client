//
//  CommentDetailViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/13/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Comment;


/**
 *  Delegate used by the CommentDetailViewController class to notify when events occur.
 */
@protocol FrameCommentDelegate <NSObject>

/**
 *  Indicates that the user has pressed the Play Video button.
 */
- (void)playVideoFromComment:(Comment *)comment;

@end


/**
 *  View Controller that displays detailed information about a frame comment.
 */
@interface CommentDetailViewController : UIViewController

@property (weak,nonatomic) id <FrameCommentDelegate> delegate;

/**
 *  Returns an initialized CommentDetailViewController for the given comment.
 */
- (id)initWithComment:(Comment *)comment;


// Interface Builder outlets
@property (weak,nonatomic) IBOutlet UIImageView * imageView;
@property (weak,nonatomic) IBOutlet UITextView  * commentView;
@property (weak,nonatomic) IBOutlet UILabel     * infoLabel;

@end
