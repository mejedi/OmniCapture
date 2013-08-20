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

// This is necessary to implement a weak collection of devices for reuse.
// As soon as the device refcount drops down to 0 the device is deallocated even
// if it is a member of the reuse pool.
// Reuse pool solves the following problem:
// 1) It would be a waste to keep all disconnected device instances
// 2) However if someone is interested in the particular device the instance
//    should survive. It is reused when that particular device comes back
//
@interface OCDeviceReuseNote: NSObject {
    __weak OCDevice *_device;
}
+ (OCDeviceReuseNote *)noteWithDevice:(OCDevice *)adevice;
@property (weak) OCDevice *device;
@end

@implementation OCDeviceReuseNote
+ (OCDeviceReuseNote *)noteWithDevice:(OCDevice *)adevice {
    OCDeviceReuseNote *note = [[self alloc] init];
    [note setDevice:adevice];
    return note;
}
@end

@implementation OCDeviceManager

- (id)init {
    self = [super init];
    if (self) {
        _devices = [NSMutableSet setWithCapacity:0];
        _reusePool = [NSMutableDictionary dictionaryWithCapacity:0];        
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
    [_reusePool setObject:[OCDeviceReuseNote noteWithDevice:adevice] forKey:[adevice key]];
}

- (void)removeDeviceFromReusePool:(OCDevice *)adevice {
    if ([adevice owner] != self)
        return NSLog(@"OCDeviceManager removeDeviceFromReusePool: does not own the device");
    [_reusePool removeObjectForKey:[adevice key]];
}

- (id)reuseDeviceWithKey:(NSString *)akey class:(Class)class {
    id adevice = [[_reusePool objectForKey:akey] device];
    if ([adevice class] == class) {
        [self removeDeviceFromReusePool:adevice];
        return adevice;
    } else {
        return [[class alloc] initWithOwner:self key:akey];
    }
}

@end
