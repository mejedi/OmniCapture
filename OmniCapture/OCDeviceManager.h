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
@interface OCDeviceManager : NSObject {
    __weak id<OCDeviceManagerDelegate> _delegate;
    NSMutableArray *_devices;
    NSMutableDictionary *_reusePool;
}

@property (weak) id<OCDeviceManagerDelegate> delegate;

// Currently available capture devices. (KVO-compliant)
- (NSUInteger)countOfDevices;
- (id)objectInDevicesAtIndex:(NSUInteger)index;

@end