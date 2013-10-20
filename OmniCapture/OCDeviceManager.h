//
//  DeviceManager.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/15/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCDevice;

// Device Manager delegate
@protocol OCDeviceManagerDelegate <NSObject>
- (void)deviceDidBecomeAvailable:(OCDevice *)adevice;
- (void)deviceWillBecomeUnavailable:(OCDevice *)adevice;
@end

// Device Manager: get current device list and subscribe for change notifications
// You probably should not create more than a single OCDeviceManager instance.
// Not safe to call from multiple threads.
@interface OCDeviceManager : NSObject {
    __weak id<OCDeviceManagerDelegate> _delegate;
    NSArray *_backends;
    NSMapTable *_proxyByKey;
    NSMapTable *_proxyByDevice;
    NSMutableSet *_devices;
    NSMutableSet *_proxies;
}

@property (weak) id<OCDeviceManagerDelegate> delegate;

// Currently available capture devices. (KVC/KVO-compliant)
- (NSUInteger)countOfDevices;
- (NSEnumerator *)enumeratorOfDevices;
- (id)memberOfDevices:(id)object;

// Perform proper shutdown
- (void)invalidate;

@end