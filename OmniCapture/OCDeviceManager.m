//
//  DeviceManager.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/15/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"
#import "OCDevice.h"
#import "OCDeviceManager+Private.h"

// Key name for KVO notifications
NSString * const devicesKeyName = @"devices";

@implementation OCDeviceManager

- (id)init {
    self = [super init];
    if (self) {
        _devices = [NSMutableSet setWithCapacity:0];
        _reusePool = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

- (NSUInteger)countOfDevices {
    return [_devices count];
}

- (NSEnumerator *)enumeratorOfDevices {
    return [_devices objectEnumerator];
}

- (id)memberOfDevices:(id)object {
    return [_devices member:object];
}

- (void)advertiseDevice:(OCDevice *)adevice available:(BOOL)isavail {
    if ([adevice owner] != self)
        return NSLog(@"OCDeviceManager advertiseDevice:available: does not own the device");
    
    BOOL listed = [_devices containsObject:adevice];
    
    // device came online
    if (isavail == YES && listed == NO) {
        [self removeDeviceFromReusePool:adevice];
        
        NSSet *objects = [NSSet setWithObject:adevice];
        
        [self willChangeValueForKey:devicesKeyName
                    withSetMutation:NSKeyValueUnionSetMutation
                       usingObjects:objects];
        
        [_devices addObject:adevice];
        
        [self didChangeValueForKey:devicesKeyName
                   withSetMutation:NSKeyValueUnionSetMutation
                      usingObjects:objects];
        
        [_delegate deviceDidBecomeAvailable:adevice];
    }
    
    // device went offline
    if (isavail == NO && listed == YES) {
        [_delegate deviceWillBecomeUnavailable:adevice];
        
        NSSet *objects = [NSSet setWithObject:adevice];
        
        [self willChangeValueForKey:devicesKeyName
                    withSetMutation:NSKeyValueMinusSetMutation
                       usingObjects:objects];
        
        [_devices removeObject:adevice];
        
        [self didChangeValueForKey:devicesKeyName
                   withSetMutation:NSKeyValueMinusSetMutation
                      usingObjects:objects];
        
        [self addDeviceToReusePool:adevice];
    }
}

- (void)addDeviceToReusePool:(OCDevice *)adevice {
    if ([adevice owner] != self)
        return NSLog(@"OCDeviceManager addDeviceToReusePool: does not own the device");
    NSString *key = [adevice key];
    if (!key)
        return;
    [_reusePool setObject:adevice forKey:key];
}

- (void)removeDeviceFromReusePool:(OCDevice *)adevice {
    if ([adevice owner] != self)
        return NSLog(@"OCDeviceManager removeDeviceFromReusePool: does not own the device");
    NSString *key = [adevice key];
    if (!key)
        return;
    [_reusePool removeObjectForKey:key];
}

- (id)reuseDeviceWithKey:(NSString *)akey class:(Class)class {
    id adevice = nil;
    if (akey) {
        adevice = [_reusePool objectForKey:akey];
    }
    if ([adevice isKindOfClass:class]) {
        [self removeDeviceFromReusePool:adevice];
        return adevice;
    } else {
        return [[class alloc] initWithOwner:self key:akey];
    }
}

@end
