//
//  PushToTalkController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallConfigurationService.h"
#import "PushToTalkBar.h"
#import "PttChannelSelectViewController.h"
#import "PushToTalkCall.h"


/**
 *  The PushToTalkController singleton manages the process of selecting, joining, and leaving
 *  a Push-To-Talk channel.
 */
@interface PushToTalkController : NSObject < PttChannelSelectionDelegate,
                                             PushToTalkCallDelegate, 
                                             PushToTalkBarDelegate,
                                             CallConfigurationServiceDelegate >

/**
 *  Returns the singleton instance of the PushToTalkController.
 */
+ (PushToTalkController *)instance;

@end
