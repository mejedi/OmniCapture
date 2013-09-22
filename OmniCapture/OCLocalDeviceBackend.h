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
@class OCLocalDeviceBackend;

@protocol OCUsbDeviceDispatcher <NSObject>
- (BOOL)localDeviceBackend:(OCLocalDeviceBackend *)backend dispatchUsbDevice:(OCLocalDeviceHandle *)handle;
@end

@interface OCLocalDeviceBackend : OCDeviceManagerBackend {
    __weak OCDeviceManager *_owner;
    NSArray *_dispatchersUsb;
    IONotificationPortRef _notifyPort;
    io_iterator_t _matchIter;
}

@end
