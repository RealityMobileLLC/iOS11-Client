//
//  AddConnectionViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/21/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectionProfile;


/**
 *  Delegate used by the AddConnectionViewController to indicate when the user
 *  has selected Save or Cancel.
 */
@protocol AddConnectionDelegate

/** 
 *  Called when a connection has been added or the view is cancelled.
 *
 *  @param connection The ConnectionProfile containing the server configuration, 
 *                    or nil if the user selected Cancel.
 */
- (void)connectionAdded:(ConnectionProfile *)connection;

@end


/**
 *  View Controller used to get a new RealityVision server configuration from 
 *  the user.
 *
 *  If the user selects Save, the delegate's -connectionAdded: method is called 
 *  and given a ConnectionProfile containing the entered data.
 *
 *  If the user selects Cancel, the delegate's -connectionAdded: method is
 *  called and given a nil ConnectionProfile.
 *
 *  The AddConnectionViewController is intended to be presented modally.
 */
@interface AddConnectionViewController : UITableViewController

/**
 *  Delegate that gets notified when the user selects Save or Cancel.
 */
@property (nonatomic,weak) id <AddConnectionDelegate> addConnectionDelegate;

/**
 *  Existing connection profile, or nil if no profile has ever been entered.
 */
@property (nonatomic,strong) ConnectionProfile * connection;


// Interface Builder outlets
- (IBAction)save;
- (IBAction)cancel;

@end
