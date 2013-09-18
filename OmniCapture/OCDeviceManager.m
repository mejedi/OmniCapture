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
        _deviceByKey = [NSMapTable strongToWeakObjectsMapTable];
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
    }
}

- (id)claimDeviceWithKey:(NSString *)akey class:(Class)class
{
    id adevice = nil;
    if (akey) {
        adevice = [_deviceByKey objectForKey:akey];
    }
    if ([adevice isKindOfClass:class] && [adevice available]==NO) {
        return adevice;
    } else {
        if (akey && adevice)
            NSLog(@"OCDeviceManager: key %@ already assigned to a device named %@",
                  akey, [adevice name]);
        id device = [[class alloc] initWithOwner:self key:akey];
        if (akey)
            [_deviceByKey setObject:device forKey:akey];
        return device;
    }
}

- (void)invalidate
{
}

@end
