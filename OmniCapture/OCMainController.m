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
    _serial = 1;
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
    OCDevice *foobar = [[self deviceManager] reuseDeviceWithKey:@"" class:[OCDevice class]];
    if (_serial == 1)
        [foobar setName:@"foobar"];
    else
        [foobar setName:[NSString stringWithFormat:@"foobar (%d)", _serial]];
    _serial++;
    [foobar setAvailable:YES];
}

- (IBAction)removeDevBtnAction:(id)sender {
    [[[[self deviceManager] enumeratorOfDevices] nextObject] setAvailable:NO];
}

@end
