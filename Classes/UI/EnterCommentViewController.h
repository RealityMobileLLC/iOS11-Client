//
//  EnterCommentViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const int MAX_COMMENT_LENGTH;


/**
 *  Protocol used to provide a comment entered by the user. 
 */
@protocol EnterCommentDelegate

/**
 *  Called when the user has exited the EnterCommentViewController.
 *
 *  @param comment The comment entered by the user or nil if no comment was entered.
 */
- (void)didEnterComment:(NSString *)comment;

@end


/**
 *  View Controller responsible for allowing user to enter a comment.
 *  This is used both after a transmit session has completed as well as to enter
 *  session and frame comments for archive sessions.
 */
@interface EnterCommentViewController : UIViewController 

/**
 *  Delegate to notify when the user has finished entering a comment.
 */
@property (nonatomic,weak) id <EnterCommentDelegate> delegate;

/**
 *  Title to be displayed for view controller.
 */
@property (nonatomic,copy) NSString * title;

/**
 *  Indicates that the view controller will only allow landscape orientation.
 */
@property (nonatomic) BOOL restrictToLandscapeOrientation;


// Interface builder outlets
@property (weak, nonatomic) IBOutlet UITextView      * commentTextView;
@property (weak, nonatomic) IBOutlet UINavigationBar * navigationBar;

- (IBAction)done;

@end
