//
//  CredentialsViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  Delegate used by the CredentialsViewController to indicate when the user
 *  has selected Save or Cancel.
 */
@protocol CredentialsDelegate

/** 
 *  Called when a credential has been entered or the view is cancelled.
 *
 *  @param credential The entered credential, or nil if the user selected Cancel.
 */
- (void)didGetCredential:(NSURLCredential *)credential;

@end


/**
 *  View Controller used to get a credential from the user.
 *
 *  If the user selects Save, the delegate's -didGetCredential: method is called 
 *  and given a NSURLCredential containing the entered data.
 *
 *  If the user selects Cancel, the delegate's -didGetCredential: method is
 *  called and given a nil NSURLCredential.
 *
 *  The CredentialsViewController is intended to be presented modally.
 */
@interface CredentialsViewController : UIViewController <UITextFieldDelegate>

/**
 *  Specifies how long the credential should be kept in the keychain.
 *  Defaults to NSURLCredentialPersistenceNone.
 */
@property (nonatomic,assign) NSURLCredentialPersistence persistence;

/**
 *  Delegate that gets notified when the user selects Save or Cancel.
 */
@property (nonatomic,weak) id <CredentialsDelegate> delegate;

/**
 *  Initializes a new CredentialsViewController to handle the given challenge.
 *
 *  @param challenge Authentication challenge requested by server.
 *  @param user      Default username or nil for no default.
 *
 *  @return An initialized CredentialsViewController object or nil if the
 *           object couldn't be initialized.
 */
- (id)initWithChallenge:(NSURLAuthenticationChallenge *)challenge andUser:(NSString *)user;

/**
 *  Provides a new challenge if a prior challenge was not accepted by the server.
 *
 *  @param challenge Authentication challenge requested by server.
 *  @param status    Status message to be displayed to user.
 */
- (void)gotNewChallenge:(NSURLAuthenticationChallenge *)challenge statusMessage:(NSString *)status;


// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UITextField     * usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField     * passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel         * serverLabel;
@property (weak, nonatomic) IBOutlet UILabel         * realmLabel;
@property (weak, nonatomic) IBOutlet UILabel         * statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView     * secureImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem * signOnButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem * cancelButton;

- (IBAction)signOnAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
