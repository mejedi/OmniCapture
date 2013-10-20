//
//  OCGphotoBackend.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/18/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManagerBackend.h"
#import "OCLocalDeviceBackend.h"

@class OCDeviceManager;
struct _GPContext;

@interface OCGphotoBackend : OCDeviceManagerBackend<OCUsbDeviceDispatcher> {
    __weak OCDeviceManager *_owner;
    NSSet *_knownVidPidPairs;
}
@end
