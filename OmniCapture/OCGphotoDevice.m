//
//  OCGphotoDevice.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <IOKit/usb/IOUSBLib.h>
#import "OCGphotoDevice.h"
#import "OCDeviceManager+Private.h"

@implementation OCGphotoDevice

+(id)deviceWithOwner:(OCDeviceManager *)owner usbDeviceHandle:(OCLocalDeviceHandle *)handle
{
    NSDictionary *properties = [handle properties];

    id vid = [properties objectForKey:@kUSBVendorID];
    id pid = [properties objectForKey:@kUSBProductID];
    id locationId = [properties objectForKey:@kUSBDevicePropertyLocationID];
    id usbAddress = [properties objectForKey:@kUSBDevicePropertyAddress];
    id vendorName = [properties objectForKey:@kUSBVendorString];
    id productName = [properties objectForKey:@kUSBProductString];
    id serial = [properties objectForKey:@kUSBSerialNumberString];
    
    NSString *key = nil;
    if (serial)
        key = [NSString stringWithFormat:@"USB:%04X:%04X:%@",
               [vid intValue], [pid intValue], serial];

    OCGphotoDevice *device = [[self alloc] initWithOwner:owner key:key];
    [device _register];

    [device setHandle:handle];
    [handle setDelegate:device];
    [device setName:productName];
    [device setIsAvailable:YES];

    return device;
}

- (void)localDeviceHandleDidClose:(OCLocalDeviceHandle *)handle
{
    [self invalidate];
}

- (void)invalidate
{
    [_handle close];
    _handle = nil;
    [self _unregister];
}

@end