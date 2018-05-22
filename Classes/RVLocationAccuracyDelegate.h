//
//  RVLocationAccuracyDelegate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/12/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MkTypes.h>


/**
 *  The desired accuracy for tracking location. 
 */
typedef enum
{
	kRVLocationAccuracyLow,     /**< Location within 3,000 meters */
	kRVLocationAccuracyMedium,  /**< Location within 100 meters */
	kRVLocationAccuracyHigh     /**< Navigation-quality accuracy */
} RVLocationAccuracy;


/**
 *  Delegate used to indicate when the user has changed the location accuracy setting.
 */
@protocol RVLocationAccuracyDelegate

/**
 *  Indicates whether the client is currently tracking location.
 */
@property (nonatomic) BOOL isLocationAware;

/**
 *  The desired accuracy for tracking location.
 */
@property (nonatomic) RVLocationAccuracy locationAccuracy;

/**
 *  The type of map to display.
 */
@property (nonatomic) MKMapType mapType;

@end
