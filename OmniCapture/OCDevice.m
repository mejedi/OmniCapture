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
    @throw [NSException exceptionWithName:@"OCBadInitCall"
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
        _available = NO;
    }
    return self;
}

- (BOOL)available {
    return _available;
}

- (void)setAvailable:(BOOL)isavail {
    if (isavail == _available)
        return;
    
    // This is for OCDeviceManagerDelegate to observe the consistent value of isAvailable property.
    // Delegate receives deviceDidBecomeAvailable: and deviceWillBecomeUnavailable: calls.
    if (isavail == YES)
        _available = YES;
    
    [_owner advertiseDevice:self available:isavail];
    
    _available = isavail;
}

@end
