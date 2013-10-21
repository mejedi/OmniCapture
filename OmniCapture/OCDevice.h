//
//  Device.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/15/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCDeviceManager;
@class OCConfig;

// A capture device: Ex. a digital camera with USB support.
@interface OCDevice : NSObject 

- (id)initWithOwner:(OCDeviceManager *)owner key:(NSString *)akey;
- (BOOL)isReady;
- (void)invalidate;
- (CALayer *)createLiveViewLayer;
- (OCConfig *) copyConfig;
- (void)captureImageUsingBlock:(void(^)(NSData *, NSError *))handler;

@property (readonly) __weak OCDeviceManager *owner;

// Unique key; used to match an existing OCDevice instance with a newly connected
// physical device.  This enables to create long living OCDevice-s that are becoming
// available and unavailable as the status of the corresponding physical device changes.
@property (readonly) NSString *key;

@property (readwrite, copy) NSString *name;
@property (readwrite, copy) NSString *vendorName;
@property (readwrite, copy) NSString *productName;

// When the associated device disconnects isAvailable is set to NO.  If the
// device ever comes back isAvailable is flipped back to YES.
// KVO-observable
// Note: making device instance available invokes observers in OCDeviceManager.
// The object should be fully initialized before doing that.
@property (readwrite) BOOL isAvailable;

@property (readwrite) BOOL isInitializing;
@property (readwrite) BOOL didFailToInitialize;

@end
