//
//  OCLocalDeviceBackend.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManagerBackend.h"

@class OCLocalDeviceHandle;

@protocol OCUsbDeviceDispatcher <NSObject>
- (BOOL)dispatchUsbDevice:(OCLocalDeviceHandle *)handle;
@optional
- (double)usbDeviceDispatchPriority;
@end

@interface OCLocalDeviceBackend : NSObject<OCDeviceManagerBackend> {
    __weak OCDeviceManager *_owner;
    NSArray *_dispatchersUsb;
    IONotificationPortRef _notifyPort;
    io_iterator_t _matchIter;
}

@end
