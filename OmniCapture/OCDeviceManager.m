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
        _devices = [NSMutableArray arrayWithCapacity:0];
        _reusePool = [NSMutableDictionary dictionaryWithCapacity:0];        
    }
    return self;
}

- (NSUInteger)countOfDevices {
    return [_devices count];
}

- (id)objectInDevicesAtIndex:(NSUInteger)index {
    return [_devices objectAtIndex:index];
}

- (void)advertiseDevice:(OCDevice *)adevice available:(BOOL)isavail {
    
    if ([adevice owner] != self) {
        NSLog(@"OCDeviceManager advertiseDevice:available: does not own the device");
        return;
    }
    
    NSUInteger idx = [_devices indexOfObject:adevice];
    
    // device came online
    if (isavail && idx == NSNotFound) {
        [self removeDeviceFromReusePool:adevice];
        
        NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[_devices count]];
        
        [self willChange:NSKeyValueChangeInsertion
         valuesAtIndexes:indices
                  forKey:devicesKeyName];
        
        [_devices addObject:adevice];
        
        [self didChange:NSKeyValueChangeInsertion
        valuesAtIndexes:indices
                 forKey:devicesKeyName];
        
        if (_delegate)
            [_delegate deviceDidBecomeAvailable:adevice];
    }
    
    // device went offline
    if (!isavail && idx != NSNotFound) {
        if (_delegate)
            [_delegate deviceWillBecomeUnavailable:adevice];
        
        NSIndexSet *indices = [NSIndexSet indexSetWithIndex:idx];
        
        [self willChange:NSKeyValueChangeRemoval
         valuesAtIndexes:indices
                  forKey:devicesKeyName];
        
        [_devices removeObjectAtIndex:idx];
        
        [self didChange:NSKeyValueChangeRemoval
        valuesAtIndexes:indices
                forKey:devicesKeyName];
        
        [self addDeviceToReusePool:adevice];
    }
}

- (void)addDeviceToReusePool:(OCDevice *)adevice {
    if ([adevice owner] != self) {
        NSLog(@"OCDeviceManager addDeviceToReusePool: does not own the device");
        return;
    }
    [_reusePool setObject:[OCDeviceReuseNote noteWithDevice:adevice] forKey:[adevice key]];
}

- (void)removeDeviceFromReusePool:(OCDevice *)adevice {
    if ([adevice owner] != self) {
        NSLog(@"OCDeviceManager removeDeviceFromReusePool: does not own the device");
        return;
    }
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
