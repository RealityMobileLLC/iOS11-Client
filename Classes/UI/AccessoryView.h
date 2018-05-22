//
//  AccessoryView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/7/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  An AccessoryView is intended to be used with an AccessoryViewController. It implements a
 *  view that merely acts as containers for (generally) two subviews. Only one of the two
 *  subviews is ever shown at a time. Others are hidden. The subviews fill the bounds of the
 *  AccessoryView.
 *  
 *  The only real reason this class was created is because of BUG-3918. Due to an apparent bug
 *  or change in how iOS handles laying out subviews, when we started building RealityVision
 *  with the iOS 6 SDK the subviews of the AccessoryViewController's accessoryView were no 
 *  longer being laid out correctly if the AccessoryViewController was initialized in landscape
 *  orientation. This class merely overrides layoutSubviews to set the frame of each subview to
 *  the bounds of the AccessoryView.
 */
@interface AccessoryView : UIView

- (id)initWithFrame:(CGRect)frame;

@end
