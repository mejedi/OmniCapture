//
//  OCGphotoDevice.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCGphotoDevice.h"
#import "OCDeviceManager+Private.h"

@implementation OCGphotoDevice

- (void)deviceDidDisconnect:(id)sender
{
    [self terminate];
}

- (void)terminate
{
    [[self handle] terminate];
    [self setHandle:nil];
    dispatch_async([[self owner] _dispatchQueue], ^{
        [self setAvailable:NO];
    });
    [[self owner] _releaseClaimedDevice:self];
}

@end
