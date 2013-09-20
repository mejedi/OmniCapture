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
#import "OCLocalDeviceBackend.h"
#import "OCGphotoBackend.h"

// Key name for KVO notifications
NSString * const devicesKeyName = @"devices";

@implementation OCDeviceManager

- (id)init {
    self = [super init];
    if (self) {
        // _deviceByKey: maps a unique device key to an OCDevice instance
        _deviceByKey = [NSMapTable strongToWeakObjectsMapTable];
        
        // _claimedDevices: instances whith some ongoing activity, typically
        // it means that the associated physical device is attached and we are controlling it
        _claimedDevices = [NSMutableSet setWithCapacity:0];
        
        // _availableDevices: devices reported to the UI as being available, this is
        // distinct from _claimedDevices due to different threading requirements.
        _availableDevices = [NSMutableSet setWithCapacity:0];
        
        // init backends
        _backends = [NSMutableArray arrayWithCapacity:10];
        [_backends addObject:[OCLocalDeviceBackend backendWithOwner:self]];
        [_backends addObject:[OCGphotoBackend backendWithOwner:self]];
        
        // start backends
        for (id<OCDeviceManagerBackend> backend in _backends) {
            [backend start];
        }
    }
    return self;
}

- (NSUInteger)countOfDevices {
    return [_availableDevices count];
}

- (NSEnumerator *)enumeratorOfDevices {
    return [_availableDevices objectEnumerator];
}

- (id)memberOfDevices:(id)object {
    return [_availableDevices member:object];
}

- (id)_claimDeviceWithKey:(NSString *)akey class:(Class)class
{
    @synchronized (self) {
        id adevice = nil;
        if (akey) {
            adevice = [_deviceByKey objectForKey:akey];
        }
        if (![adevice isKindOfClass:class] || [_claimedDevices containsObject:adevice]) {
            if (akey && adevice)
                NSLog(@"OCDeviceManager: key %@ already assigned to a device named %@",
                      akey, [adevice name]);
            adevice = [[class alloc] initWithOwner:self key:akey];
            if (akey)
                [_deviceByKey setObject:adevice forKey:akey];
            [adevice addObserver:self forKeyPath:@"available"
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:NULL];
        }
        [_claimedDevices addObject:adevice];
        return adevice;
    }
}

- (void)_releaseClaimedDevice:(OCDevice *)adevice
{
    if (!adevice || [adevice owner] != self)
        return NSLog(@"OCDeviceManager _releaseClaimedDevice: does not own the device");

    @synchronized (self) {
        if (_claimedDevices && ![_claimedDevices containsObject:adevice])
            return NSLog(@"OCDeviceManager _releaseClaimedDevice: device was not claimed");
        [_claimedDevices removeObject:adevice];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"available"]) {
        BOOL wasAvailable = [[change objectForKey:NSKeyValueChangeOldKey] boolValue];
        BOOL isAvailable = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (wasAvailable == isAvailable)
            return;
        if (isAvailable) {
            // device came online
            NSSet *objects = [NSSet setWithObject:object];
            
            [self willChangeValueForKey:devicesKeyName
                        withSetMutation:NSKeyValueUnionSetMutation
                           usingObjects:objects];
            
            [_availableDevices addObject:object];
            
            [self didChangeValueForKey:devicesKeyName
                       withSetMutation:NSKeyValueUnionSetMutation
                          usingObjects:objects];
            
            [_delegate deviceDidBecomeAvailable:object];
        } else {
            // device went offline
            [_delegate deviceWillBecomeUnavailable:object];
            
            NSSet *objects = [NSSet setWithObject:object];
            
            [self willChangeValueForKey:devicesKeyName
                        withSetMutation:NSKeyValueMinusSetMutation
                           usingObjects:objects];
            
            [_availableDevices removeObject:object];
            
            [self didChangeValueForKey:devicesKeyName
                       withSetMutation:NSKeyValueMinusSetMutation
                          usingObjects:objects];

        }
    }
}

- (void)invalidate
{
    NSSet *claimed = nil;
    @synchronized (self) {
        claimed = _claimedDevices;
        _claimedDevices = nil;
    }
    // terminate claimed devices (device may effectively receive multiple terminate messages
    // due to activities on concurrent threads)
    //
    // Threading note: client MUST assume OCDeviceManager and OCDevice-s aren't thread safe.
    // Internally a multithreaded backend may be implememnted; such a backend must consider
    // thread safety when implementing OCDevice-s.
    //
    for (OCDevice *device in claimed) {
        [device terminate];
    }
    // terminate backends (in reverse order)
    [_backends enumerateObjectsWithOptions:NSEnumerationReverse
                                usingBlock:^(id<OCDeviceManagerBackend> backend, NSUInteger pos, BOOL *stop) {
                                    [backend terminate];
                                }];
    _backends = nil;
}

- (dispatch_queue_t)_dispatchQueue
{
    return dispatch_get_main_queue();
}

- (void)_notifyTerminating:(id)sender
{
}

- (void)_notifyTerminated:(id)sender
{
}

- (NSArray *)_qualifyingDispatchers:(SEL)selector
{
    NSMutableArray *dispatchers = [NSMutableArray arrayWithCapacity:0];
    for (id backend in _backends) {
        if ([backend respondsToSelector:selector])
            [dispatchers addObject:backend];
    }
    return [dispatchers copy];
}

@end
