//
//  CredentialsViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CredentialsViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CredentialsViewController
{
	NSURLAuthenticationChallenge * challenge;
	NSURLCredential              * credential;
	NSString                     * username;
}

@synthesize persistence;
@synthesize delegate;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize serverLabel;
@synthesize realmLabel;
@synthesize statusLabel;
@synthesize secureImage;
@synthesize signOnButton;
@synthesize cancelButton;


#pragma mark - Initialization and cleanup

- (id)initWithChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge andUser:(NSString *)user
{
    NSAssert(authenticationChallenge!=nil,@"Challenge must be provided");
	DDLogVerbose(@"CredentialsViewController initWithChallenge:andUser:%@",user);
    
    self = [super initWithNibName:@"CredentialsViewController" 
						   bundle:[NSBundle bundleForClass:[self class]]];
    if (self != nil) 
	{
        challenge = authenticationChallenge;
		username = user;
		persistence = NSURLCredentialPersistenceNone;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"CredentialsViewController viewDidLoad");
    [super viewDidLoad];
	self.title = [RealityVisionAppDelegate appName];
	self.contentSizeForViewInPopover = CGSizeMake(320, 250);
	statusLabel.text = @"";
    
    NSURLProtectionSpace * protectionSpace = [challenge protectionSpace];
	if ([protectionSpace receivesCredentialSecurely])
	{
		secureImage.hidden = NO;
	}
	else 
	{
		CGRect serverLabelFrame = serverLabel.frame;
		serverLabelFrame.origin.x = secureImage.frame.origin.x;
		serverLabel.frame = serverLabelFrame;
		secureImage.hidden = YES;
	}

    NSString * host = [protectionSpace host];
	serverLabel.text = host ? host : @"";
    
    NSString * realm = [protectionSpace realm];
    realmLabel.text = realm ? [NSString stringWithFormat:@"Domain: %@", realm] : @"";
	
    // get the username and password from the proposed credential (if any)
    NSURLCredential * proposedCredential = [challenge proposedCredential];
    if (proposedCredential != nil) 
	{
        NSString * proposedUser = [proposedCredential user];
		if (! NSStringIsNilOrEmpty(proposedUser))
		{
			usernameTextField.text = proposedUser;
		}
		
        NSString * proposedPassword = [proposedCredential password];
		if (! NSStringIsNilOrEmpty(proposedPassword))
		{
			passwordTextField.text = proposedPassword;
		}
    }
	else if (! NSStringIsNilOrEmpty(username))
	{
		usernameTextField.text = username;
	}
}

- (void)viewDidUnload
{
	DDLogVerbose(@"CredentialsViewController viewDidUnload");
	[super viewDidUnload];
    usernameTextField = nil;
    passwordTextField = nil;
    serverLabel = nil;
    realmLabel = nil;
    statusLabel = nil;
	secureImage = nil;
	signOnButton = nil;
	cancelButton = nil;
	challenge = nil;
	credential = nil;
	username = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"CredentialsViewController viewWillAppear");
    [super viewWillAppear:animated];
    
	// determine which text field should get focus
	UITextField * firstResponder = ([usernameTextField.text length] == 0) ? usernameTextField : passwordTextField;
	[firstResponder becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // force portrait orientation (ios5)
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Public methods

- (void)gotNewChallenge:(NSURLAuthenticationChallenge *)authenticationChallenge 
		  statusMessage:(NSString *)status
{
	challenge = authenticationChallenge;
	credential = nil;
	
	if (status != nil)
	{
		statusLabel.text = status;
	}
	
	signOnButton.enabled = YES;
	cancelButton.enabled = YES;
	[passwordTextField becomeFirstResponder];
}


#pragma mark - User interface callback methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == usernameTextField)
	{
        // if the focus is on the username field, switch it to the password field
        textField.returnKeyType = UIReturnKeyNext;
    }
	else if (textField == passwordTextField)
	{
        // if the focus is on the password field, sign in
        textField.returnKeyType = UIReturnKeyGo;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == usernameTextField) 
	{
        // if the focus is on the username field, switch it to the password field
        [passwordTextField becomeFirstResponder];
    } 
	else if (textField == passwordTextField) 
	{
        // if the focus is on the password field, sign in
        [self signOnAction:self];
    }
    return NO;
}

- (IBAction)signOnAction:(id)sender
{
	if (! self.usernameFieldIsValid)
	{
		statusLabel.text = NSLocalizedString(@"Username format should be domain\\user",@"Username format should be domain\\user");
		return;
	}
	
	statusLabel.text = @"";
	signOnButton.enabled = NO;
	cancelButton.enabled = NO;
	
    NSString * user = usernameTextField.text;
    if (user == nil) 
	{
        user = @"";
    }
    
    NSString * password = self.passwordTextField.text;
    if (password == nil) 
	{
        password = @"";
    }
    
    credential = [NSURLCredential credentialWithUser:user
											password:password
										 persistence:persistence];
	[delegate didGetCredential:credential];
}

- (IBAction)cancelAction:(id)sender
{
	statusLabel.text = @"";
	signOnButton.enabled = NO;
	cancelButton.enabled = NO;
    [delegate didGetCredential:nil];
}

- (BOOL)usernameFieldIsValid
{
	NSCharacterSet * invalidCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	return [usernameTextField.text rangeOfCharacterFromSet:invalidCharacters].location == NSNotFound;
}

@end
