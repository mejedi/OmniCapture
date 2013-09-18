//
//  OCDeviceManager+Private.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"

@interface OCDeviceManager ()

// Notifies interested parties about the change in device availability state.
// No need to call this directly.
- (void)advertiseDevice:(OCDevice *)adevice available:(BOOL)isavail;

// Devices are created using this method.  Either allocates a new instance or
// returns an existing instance if one exists for the given key.
//
// The intention is to bring the existing object back to life when a corresponding
// unavailable device becomes available again. This basically solves the identity
// issue — from the app standpoint an object and the corresponding physical device
// ARE the same entity.
//
// Pass nil if the device lacks a stable key.
- (id)claimDeviceWithKey:(NSString *)akey class:(Class)class;


@end
