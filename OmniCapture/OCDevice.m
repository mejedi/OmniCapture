//
//  Device.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/15/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDevice.h"
#import "OCDeviceManager.h"
#import "OCDeviceManager+Private.h"

@implementation OCDevice

- (id)init {
    @throw [NSException exceptionWithName:@"OCException"
                                   reason:@"use initWithOwner:key: to init OCDevice"
                                 userInfo:nil];
    return nil;
}

- (id)initWithOwner:(OCDeviceManager *)owner key:(NSString *)akey {
    self = [super init];
    if (self) {
        _owner = owner;
        _key = akey;
        _name = @"";
    }
    return self;
}

- (void)invalidate
{
}

- (CALayer *)createLiveViewLayer
{
    return nil;
}

- (BOOL)isReady
{
    return _isAvailable && !_isInitializing && !_didFailToInitialize;
}

+ (NSSet *)keyPathsForValuesAffectingIsReady {
    return [NSSet setWithObjects:@"isAvailable", @"isInitializing", @"didFailToInitialize", nil];
}

@end
