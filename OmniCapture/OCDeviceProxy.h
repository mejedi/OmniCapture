//
//  OCDeviceProxy.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/22/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"
#import "OCDevice.h"

@interface OCDeviceProxy : OCDevice {
    OCDevice *_realDevice;
}
+ (id)proxyWithOwner:(OCDeviceManager *)manager key:(NSString *)key;
- (BOOL)isBound;
- (BOOL)isBoundTo:(OCDevice *)adevice;
- (void)bindTo:(OCDevice *)adevice;
- (void)unbind;
@end
