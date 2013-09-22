//
//  OCDeviceProxy.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/22/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceProxy.h"
#import "OCDevice+ManagerAdditions.h"

static NSArray *syncedProperties;

@implementation OCDeviceProxy

+ (id)proxyWithOwner:(OCDeviceManager *)manager key:(NSString *)key
{
    return [[OCDeviceProxy alloc] initWithOwner:manager key:key];
}

+ (void)initialize
{
    syncedProperties = [NSArray arrayWithObjects:@"isAvailable", @"name", nil];
}

- (BOOL)isBound
{
    return _realDevice != nil;
}

- (BOOL)isBoundTo:(OCDevice *)adevice
{
    return _realDevice == adevice;
}

- (void)bindTo:(OCDevice *)adevice
{
    [self unbind];
    _realDevice = adevice;
    for (NSString *propName in syncedProperties) {
        [_realDevice addObserver:self
                      forKeyPath:propName
                         options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                         context:NULL];
    }
}

- (void)unbind
{
    if (_realDevice) {
        for (NSString *propName in syncedProperties) {
            [_realDevice removeObserver:self forKeyPath:propName];
        }
    }
    _realDevice = nil;
    // reset to a meaningfull state since we are no longer backed by any real
    // device
    [self setIsAvailable:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    [self setValue:[change objectForKey:NSKeyValueChangeNewKey] forKey:keyPath];
}

- (void)_register
{
}

- (void)_unregister
{
    [_realDevice _unregister];
}

- (void)invalidate
{
    [_realDevice invalidate];
}

@end
