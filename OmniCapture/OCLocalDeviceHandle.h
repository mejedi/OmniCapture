//
//  OCLocalUsbDevice.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCLocalDeviceBackend;

@protocol OCLocalDeviceHandleDelegate <NSObject>
- (void)deviceDidDisconnect:(id)sender;
@end

@interface OCLocalDeviceHandle : NSObject {
    __weak OCLocalDeviceBackend *_owner;
    io_service_t _service;
    io_object_t _notification;
}

- (void)terminate;

@property (readwrite) __weak id<OCLocalDeviceHandleDelegate> delegate;
@property (readonly) NSDictionary *properties;

@end
