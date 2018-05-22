//
//  LocationStatusBarButtonItem.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/16/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "LocationStatusBarButtonItem.h"



@implementation LocationStatusBarButtonItem

@synthesize locationProvider;


- (id)initWithLocationProvider:(NSObject <LocationStatusProvider> *)theLocationProvider
{
    self = [self initWithLocationProvider:theLocationProvider target:theLocationProvider action:@selector(toggleLocationAware)];
    //self.button.adjustsImageWhenDisabled = NO;
    self.enabled = YES;
    return self;
}

- (id)initWithLocationProvider:(NSObject <LocationStatusProvider> *)theLocationProvider 
                        target:(id)target 
                        action:(SEL)action
{
    NSAssert(theLocationProvider,@"Location provider is required");
    self.locationProvider = theLocationProvider;
    
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 32, 32);
    [button setImage:[self locationStatusImage] forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchDown];
    
    self = [super initWithCustomView:button];
    if (self) 
    {
        [self.locationProvider addObserver:self
                                forKeyPath:@"locationOn"
                                   options:NSKeyValueObservingOptionNew
                                   context:NULL];
        
        [self.locationProvider addObserver:self
                                forKeyPath:@"locationLock"
                                   options:NSKeyValueObservingOptionNew
                                   context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [self.locationProvider removeObserver:self forKeyPath:@"locationOn"];
    [self.locationProvider removeObserver:self forKeyPath:@"locationLock"];
    self.locationProvider = nil;
}

- (UIButton *)button
{
    return (UIButton *)self.customView;
}

- (UIImage *)locationStatusImage
{
    return (! self.locationProvider.locationOn)                ? [UIImage imageNamed:@"location_off"] :
           (self.locationProvider.locationLock == GL_NoLock)   ? [UIImage imageNamed:@"location_on_no_position"] :
           (self.locationProvider.locationLock == GL_Lock)     ? [UIImage imageNamed:@"location_on_lock"] :
           (self.locationProvider.locationLock == GL_LostLock) ? [UIImage imageNamed:@"location_on_lost_lock"] : nil; 
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [[self button] setImage:[self locationStatusImage] forState:UIControlStateNormal];
}

@end
