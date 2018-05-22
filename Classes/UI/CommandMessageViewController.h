//
//  CommandMessageViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/23/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RecipientSelectionViewController;

extern const NSUInteger MAX_MESSAGE_LENGTH;

/**
 *  View Controller used to get a message to send with a command.
 */
@interface CommandMessageViewController : UIViewController

/**
 *  The RecipientSelectionViewController that presented this view controller.
 */
@property (nonatomic,weak) RecipientSelectionViewController * recipientViewController;


// Interface builder outlets
@property (weak, nonatomic) IBOutlet UILabel    * recipientLabel;
@property (weak, nonatomic) IBOutlet UITextView * messageTextView;

@end
