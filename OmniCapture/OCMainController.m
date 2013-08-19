//
//  OCMainController.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCMainController.h"
#import "OCDeviceManager+Private.h"
#import "OCDevice.h"

@implementation OCMainController

- (id)init {
    self = [super init];
    return self;
}

- (void)awakeFromNib {
    OCDeviceManager *manager = [self deviceManager];

    OCDevice *fido = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [fido setName:@"fido"];
    [fido setAvailable:YES];
    
    OCDevice *rover = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [rover setName:@"rover"];
    [rover setAvailable:YES];
    
    OCDevice *rex = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [rex setName:@"rex"];
    [rex setAvailable:YES];

}

- (IBAction)addDevBtnAction:(id)sender {
    OCDeviceManager *manager = [self deviceManager];
    
    OCDevice *foobar = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [foobar setName:@"foobar"];
    [foobar setAvailable:YES];
}

- (IBAction)removeDevBtnAction:(id)sender {
    OCDeviceManager *manager = [self deviceManager];
   // NSArray *devices = [[self deviceManager] devices];
    if ([manager countOfDevices] > 0) {
        OCDevice *dev = [manager objectInDevicesAtIndex:0];
        [dev setAvailable:NO];
    }
}
@end
