//
//  OCDeviceManager+Private.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"

@interface OCDeviceManager ()
- (void)advertiseDevice:(OCDevice *)adevice available:(BOOL)isavail;
- (id)reuseDeviceWithKey:(NSString *)akey class:(Class)class;
@end
