//
//  DeviceManager.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/15/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"
#import "OCDeviceManager+Private.h"
#import "OCDevice.h"
#import "OCDeviceProxy.h"
#import "OCLocalDeviceBackend.h"
#import "OCGphotoBackend.h"

// Key name for KVO notifications
NSString * const devicesKeyName = @"devices";

@implementation OCDeviceManager

- (id)init {
    self = [super init];
    if (self) {
        _proxyByKey = [NSMapTable strongToWeakObjectsMapTable];
        _proxyByDevice = [NSMapTable strongToStrongObjectsMapTable];
        _devices = [NSMutableSet setWithCapacity:0];
        _proxies = [NSMutableSet setWithCapacity:0];
        
        // init backends
        _backends = [NSArray arrayWithObjects:
                        [OCLocalDeviceBackend backendWithOwner:self],
                        [OCGphotoBackend backendWithOwner:self],
                     nil];
        
        // start backends
        for (OCDeviceManagerBackend *backend in _backends) {
            [backend start];
        }
    }
    return self;
}

- (NSUInteger)countOfDevices {
    return [_proxies count];
}

- (NSEnumerator *)enumeratorOfDevices {
    return [_proxies objectEnumerator];
}

- (id)memberOfDevices:(id)object {
    return [_proxies member:object];
}

- (void)_registerDevice:(OCDevice *)adevice
{
    @synchronized (self) {
        if ([_devices containsObject:adevice]) {
            NSLog(@"OCDeviceManager _registerDevice: already registered");
            return;
        }
        [_devices addObject:adevice];
        NSString *key = [adevice key];
        OCDeviceProxy *proxy = nil;
        if (key)
            proxy = [_proxyByKey objectForKey:key];
        if (!proxy) {
            proxy = [OCDeviceProxy proxyWithOwner:self key:key];
            if (key)
                [_proxyByKey setObject:proxy forKey:key];
        }
        [_proxyByDevice setObject:proxy forKey:adevice];
        
        [self _asyncCleanupPending:self];
        dispatch_async([self _dispatchQueue], ^{
            if ([proxy isBound]) {
                [proxy unbind];
            } else {
                [proxy addObserver:self
                        forKeyPath:@"isAvailable"
                           options:(NSKeyValueObservingOptionNew |
                                      NSKeyValueObservingOptionOld)
                             context:NULL];
            }
            [proxy bindTo:adevice];
            [self _asyncCleanupCompleted:self];
        });
    }
}

- (void)_unregisterDevice:(OCDevice *)adevice
{
    @synchronized (self) {
        if (![_devices containsObject:adevice]) {
            if (_devices)
                NSLog(@"OCDeviceManager _unregisterDevice: not registered");
            return;
        }
        [_devices removeObject:adevice];
        OCDeviceProxy *proxy = [_proxyByDevice objectForKey:adevice];
        [_proxyByDevice removeObjectForKey:adevice];
        
        [self _asyncCleanupPending:self];
        dispatch_async([self _dispatchQueue], ^{
            if ([proxy isBoundTo:adevice]) {
                [proxy unbind];
                [proxy removeObserver:self
                           forKeyPath:@"isAvailable"];
            }
            [self _asyncCleanupCompleted:self];
        });
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"isAvailable"]) {
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
            
            [_proxies addObject:object];
            
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
            
            [_proxies removeObject:object];
            
            [self didChangeValueForKey:devicesKeyName
                       withSetMutation:NSKeyValueMinusSetMutation
                          usingObjects:objects];

        }
    }
}

- (void)invalidate
{
    NSSet *devices = _devices;
    _devices = nil;
    for (OCDevice *device in devices) {
        [device invalidate];
    }
    // terminate backends (in reverse order)
    [_backends enumerateObjectsWithOptions:NSEnumerationReverse
                                usingBlock:^(OCDeviceManagerBackend *backend, NSUInteger pos, BOOL *stop) {
                                    [backend invalidate];
                                }];
    _backends = nil;
}

- (dispatch_queue_t)_dispatchQueue
{
    return dispatch_get_main_queue();
}

- (void)_asyncCleanupPending:(id)sender
{
}

- (void)_asyncCleanupCompleted:(id)sender
{
}

- (NSArray *)_qualifyingDispatchersBySelector:(SEL)selector
{
    NSMutableArray *dispatchers = [NSMutableArray arrayWithCapacity:0];
    for (id backend in _backends) {
        if ([backend respondsToSelector:selector])
            [dispatchers addObject:backend];
    }
    return [dispatchers copy];
}

@end

@implementation OCDevice (ManagerAdditions)

- (void)_register
{
    [[self owner] _registerDevice:self];
}

- (void)_unregister
{
    [[self owner] _unregisterDevice:self];
}

@end
