//
//  OCDeviceManager+Private.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"

@interface OCDeviceManager ()

// Devices are created using this method.  Either allocates a new instance or
// returns an existing instance if one exists for the given key.
//
// The intention is to bring the existing object back to life when a corresponding
// unavailable device becomes available again. This basically solves the identity
// issue — from the app standpoint an object and the corresponding physical device
// ARE the same entity.
//
// Pass nil if the device lacks a stable key.
//
// Thread safe.
- (id)_claimDeviceWithKey:(NSString *)akey class:(Class)class;

// This removes aDevice from the internal list of devices (used to send terminate
// on device manager invalidation). Also unsubscribes the device manager from KVO
// notifications from aDevice [available] property changes.
//
// Thread safe.
- (void)_releaseClaimedDevice:(OCDevice *)aDevice;


// Executes code that can potentially affect the UI on the proper thread
// (Ex: modifications of KVO-conformant properties)
- (dispatch_queue_t)_dispatchQueue;


// Enables device manager to wait for async termination
- (void)_notifyTerminating:(id)sender;
- (void)_notifyTerminated:(id)sender;

// Select a subset of backends (those ones that respond to the given selector)
- (NSArray *)_qualifyingDispatchers:(SEL)selector;
@end
