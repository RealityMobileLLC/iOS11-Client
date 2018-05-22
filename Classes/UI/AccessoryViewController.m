//
//  AccessoryViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AccessoryViewController.h"
#import "AccessoryView.h"


@implementation AccessoryViewController
{
	// if NO, show accessory view on the bottom in portrait and on the right in landscape
	// if YES, show accessory view on the top in portrait and on the left in landscape
	// @todo expose this as a property to allow user to set layout direction?
	BOOL accessoryViewTopLeft;
}

@synthesize accessoryViewHidden;
@synthesize accessoryViewFullScreen;
@synthesize mainView;
@synthesize accessoryView;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];
	accessoryViewFullScreen = NO;
	accessoryViewHidden = accessoryView.hidden = YES;
	accessoryViewTopLeft = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	// the main view has to be behind the accessory view
	[mainView.superview sendSubviewToBack:mainView];
	[self layoutAccessoryViewForInterfaceOrientation:self.interfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
										 duration:(NSTimeInterval)duration
{
	[self layoutAccessoryViewForInterfaceOrientation:interfaceOrientation];
}


#pragma mark - Virtual methods

- (void)layoutMainView
{
	// subclasses should override if desired
}


#pragma mark - Accessory view methods

- (void)hideAccessoryView
{
	if (! accessoryViewHidden)
	{
		// slide accessory view out
		CGRect accessoryViewFrame = accessoryView.frame;
		
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
		{
			accessoryViewFrame.origin.y = accessoryViewTopLeft ? -accessoryViewFrame.size.height 
			                                                   : mainView.superview.bounds.size.height;
		}
		else 
		{
			accessoryViewFrame.origin.x = accessoryViewTopLeft ? -accessoryViewFrame.size.width 
			                                                   : mainView.superview.bounds.size.width;
		}
		
		[self hideAccessoryViewInFrame:accessoryViewFrame mainFrame:mainView.superview.bounds];
	}
}

- (void)showAccessoryView:(UIView *)thisView 
		hideAccessoryView:(UIView *)otherView 
			   fullScreen:(BOOL)fullScreen
			flipDirection:(UIViewAnimationOptions)flipDirection
{
	NSAssert(thisView,@"Accessory view to show must not be nil");
	
	if (accessoryViewHidden)
	{
		thisView.hidden = NO;
		otherView.hidden = YES;
		
		accessoryViewFullScreen = fullScreen;
		if (accessoryViewFullScreen)
		{
			[self showAccessoryViewInFrame:mainView.superview.bounds mainFrame:mainView.frame];
		}
		else 
		{
			[self showSplitView];
		}
	}
	else if (thisView.hidden)
	{
		if (otherView != nil)
		{
			// flip accessory views
			[UIView transitionWithView:self.accessoryView
							  duration:0.5
							   options:UIViewAnimationOptionShowHideTransitionViews | flipDirection
							animations:^{ thisView.hidden = NO; otherView.hidden = YES; }
							completion:^(BOOL finished)
									    { 
										   if (accessoryViewFullScreen != fullScreen) 
											   [self toggleAccessoryViewSize]; 
									    }];
		}
		else 
		{
			thisView.hidden = NO;
		}
	}
	else if (accessoryViewFullScreen != fullScreen)
	{
		[self toggleAccessoryViewSize];
	}
}

- (void)toggleAccessoryView:(UIView *)thisView 
		 otherAccessoryView:(UIView *)otherView 
			  flipDirection:(UIViewAnimationOptions)flipDirection
{
	NSAssert(thisView,@"Accessory view to show must not be nil");
	
	if (accessoryViewHidden)
	{
		// slide accessory view in
		accessoryViewFullScreen = NO;
		
		if (thisView != nil)
		{
			thisView.hidden = NO;
		}
		
		if (otherView != nil)
		{
			otherView.hidden = YES;
		}
		
		[self showSplitView];
	}
	else if (thisView.hidden)
	{
		if (otherView != nil)
		{
			// flip accessory views
			[UIView transitionWithView:accessoryView
							  duration:0.5
							   options:UIViewAnimationOptionShowHideTransitionViews | flipDirection
							animations:^{ thisView.hidden = NO; otherView.hidden = YES; }
							completion:NULL];
		}
		else 
		{
			thisView.hidden = NO;
		}
	}
	else
	{
		// slide accessory view out
		[self hideAccessoryView];
	}
}

- (void)toggleAccessoryViewSize
{
	accessoryViewFullScreen = ! accessoryViewFullScreen;
	
	if (accessoryViewFullScreen)
	{
		[self showAccessoryViewInFrame:mainView.superview.bounds mainFrame:mainView.frame];
	}
	else 
	{
		[self showSplitView];
	}
}


#pragma mark - Private methods

- (void)layoutAccessoryViewForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    CGFloat toolbarHeight = 0;
    if (self.toolbarItems != nil && self.navigationController.toolbarHidden)
    {
        toolbarHeight = self.navigationController.toolbar.bounds.size.height;
    }
    
    CGRect viewBounds = mainView.superview.bounds;
    viewBounds.size.height += toolbarHeight;
	CGRect mainViewFrame = viewBounds;
	CGRect accessoryViewFrame = viewBounds;
	
	if (accessoryViewHidden)
	{
		// move accessory view off screen
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
		{
			accessoryViewFrame.size.height = viewBounds.size.height / 2;
			accessoryViewFrame.origin.y = accessoryViewTopLeft ? -accessoryViewFrame.size.height 
			                                                   : mainViewFrame.size.height;
		}
		else 
		{
			accessoryViewFrame.size.width = viewBounds.size.width / 2;
			accessoryViewFrame.origin.x = accessoryViewTopLeft ? -accessoryViewFrame.size.width  
			                                                   : mainView.superview.bounds.size.width;
		}
	}
	else if (! accessoryViewFullScreen)
	{
		// split main view and accessory view to half screen each
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
		{
			CGFloat newHeight = viewBounds.size.height / 2;
			mainViewFrame.origin.y = newHeight - toolbarHeight;
			mainViewFrame.size.height = newHeight;
			accessoryViewFrame.size.height = newHeight;
		}
		else 
		{
			CGFloat newWidth = viewBounds.size.width / 2;
			mainViewFrame.origin.x = newWidth;
			mainViewFrame.size.width = newWidth;
			accessoryViewFrame.size.width = newWidth;
		}
	}
	
	mainView.frame = mainViewFrame;
	accessoryView.frame = accessoryViewFrame;
}

- (void)showAccessoryViewInFrame:(CGRect)newFrame mainFrame:(CGRect)newMainFrame
{
	accessoryViewHidden = NO;
	[UIView animateWithDuration:0.3 
					 animations:^{ 
									accessoryView.hidden = NO; 
									accessoryView.frame = newFrame; 
									mainView.frame = newMainFrame; 
								 } 
					 completion:^(BOOL finished){ [accessoryView setNeedsLayout]; [self layoutMainView]; }];
}

- (void)hideAccessoryViewInFrame:(CGRect)newFrame mainFrame:(CGRect)newMainFrame
{
	accessoryViewHidden = YES;
	[UIView animateWithDuration:0.3 
					 animations:^{ accessoryView.frame = newFrame; mainView.frame = newMainFrame; } 
					 completion:^(BOOL finished){ self.accessoryView.hidden = YES; [self layoutMainView]; }];	
}

- (void)showSplitView
{
	CGRect mainViewFrame = mainView.superview.bounds;
	CGRect accessoryViewFrame = accessoryViewTopLeft ? mainView.superview.bounds : accessoryView.frame;
	
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
	{
		CGFloat newHeight = mainView.superview.bounds.size.height / 2;
		mainViewFrame.origin.y = newHeight;
		mainViewFrame.size.height = newHeight;
		accessoryViewFrame.size.height = newHeight;
	}
	else 
	{
		CGFloat newWidth = mainView.superview.bounds.size.width / 2;
		mainViewFrame.origin.x = newWidth;
		mainViewFrame.size.width = newWidth;
		accessoryViewFrame.size.width = newWidth;
	}
	
	[self showAccessoryViewInFrame:accessoryViewFrame mainFrame:mainViewFrame];
}

@end
