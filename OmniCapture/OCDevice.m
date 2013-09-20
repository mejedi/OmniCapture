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

- (void)terminate
{
}

@end
