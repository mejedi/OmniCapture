//
//  OCGphotoBackend.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/18/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <IOKit/usb/IOUSBLib.h>
#import <gphoto2/gphoto2.h>
#import "OCGphotoBackend.h"
#import "OCDeviceManager.h"
#import "OCDeviceManager+Private.h"
#import "OCLocalDeviceHandle.h"
#import "OCGphotoDevice.h"

@implementation OCGphotoBackend

+ (id)backendWithOwner:(OCDeviceManager *)owner
{
    return [[OCGphotoBackend alloc] initWithOwner:owner];
}

- (id)initWithOwner:(OCDeviceManager *)owner
{
    self = [super init];
    if (self) {
        _owner = owner;
        
        // knownVidPidPairs
        NSMutableSet *vidPidPairs = [NSMutableSet setWithCapacity:0];
        CameraAbilitiesList *knownCams = NULL;
        gp_abilities_list_new(&knownCams);
        GPContext *gphotoContext = gp_context_new();
        int result = gp_abilities_list_load(knownCams, gphotoContext);
        if (result < GP_OK) {
            NSLog(@"Gphoto2: error enumerating camera modules: %s", gp_result_as_string(result));
        }
        int count = gp_abilities_list_count(knownCams);
        for (int i = 0; i < count; i++) {
            CameraAbilities camInfo;
            gp_abilities_list_get_abilities(knownCams, i, &camInfo);
            if (camInfo.port & GP_PORT_USB) {
                [vidPidPairs addObject:[NSString stringWithFormat:@"%04X:%04X", camInfo.usb_vendor, camInfo.usb_product]];
            }
        }
        gp_abilities_list_free(knownCams);
        knownCams = NULL;
        gp_context_unref(gphotoContext);
        gphotoContext = NULL;
        
        _knownVidPidPairs = [vidPidPairs copy];
        
    }
    return self;
}

- (BOOL)localDeviceBackend:(OCLocalDeviceBackend *)backend dispatchUsbDevice:(OCLocalDeviceHandle *)handle
{
    NSDictionary *properties = [handle properties];
    id vid = [properties objectForKey:@kUSBVendorID];
    id pid = [properties objectForKey:@kUSBProductID];
    
    NSString *vidPid = [NSString stringWithFormat:@"%04X:%04X", [vid intValue], [pid intValue]];
    if (![_knownVidPidPairs containsObject:vidPid])
        return NO;
    
    return [OCGphotoDevice deviceWithOwner:_owner usbDeviceHandle:handle] != nil;
}

@end
