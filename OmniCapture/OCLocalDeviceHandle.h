//
//  OCLocalUsbDevice.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCLocalDeviceBackend;
@class OCLocalDeviceHandle;

@protocol OCLocalDeviceHandleDelegate <NSObject>
// The underlying physical device disconnected, the handle did close.
- (void)localDeviceHandleDidClose:(OCLocalDeviceHandle *)handle;
@optional
// Called to determine if it is safe to call delegate on arbitrary threads.
// If it is not, delegate is always called on the main thread (default).
// The method itself if implemented must be thread safe.
- (BOOL)localDeviceHandleIsDelegateThreadSafe:(OCLocalDeviceHandle *)handle;
@end

@interface OCLocalDeviceHandle : NSObject {
    OCLocalDeviceBackend *_backend;
    io_service_t _service;
    io_object_t _notification;
}

// Close handle and release resources. Thread safe.
- (void)close;

@property (readwrite) __weak id<OCLocalDeviceHandleDelegate> delegate;
@property (readonly) NSDictionary *properties;

@end
