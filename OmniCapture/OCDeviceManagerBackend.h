//
//  OCDeviceManagerBackend.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCDeviceManager;

@protocol OCDeviceManagerBackend <NSObject>
+ (id)backendWithOwner:(OCDeviceManager *)owner;
- (void)start;
- (void)terminate;
@end
