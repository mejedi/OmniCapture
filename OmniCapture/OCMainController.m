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
    [fido setName:@"PowerShot A640"];
    [fido setAvailable:YES];
    
    OCDevice *rover = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [rover setName:@"Nikon"];
    [rover setAvailable:YES];
    
    OCDevice *rex = [manager reuseDeviceWithKey:@"" class:[OCDevice class]];
    [rex setName:@"iSight Camera"];
    [rex setAvailable:YES];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];

}

- (IBAction)addDevBtnAction:(id)sender {
    OCDevice *foobar = [[self deviceManager] reuseDeviceWithKey:@"" class:[OCDevice class]];
    if (_serial == 1)
        [foobar setName:@"Foobar"];
    else
        [foobar setName:[NSString stringWithFormat:@"Foobar (%d)", _serial]];
    _serial++;
    [foobar setAvailable:YES];
}

- (IBAction)removeDevBtnAction:(id)sender {
    [[[[self deviceManager] enumeratorOfDevices] nextObject] setAvailable:NO];
}

- (void)timerDidFire:(NSTimer *)timer {
    [_blinkyNameTimer invalidate];
    _blinkyNameTimer = nil;
    if (_blinky) {
        [_blinky setAvailable:NO];
        _blinky = nil;
    } else {
        _blinky = [[self deviceManager] reuseDeviceWithKey:@"blinky" class:[OCDevice class]];
        [_blinky setName:@"Blinky"];
        [_blinky setAvailable:YES];
        _blinkyNameTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(blinkyNameTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)blinkyNameTimerDidFire:(NSTimer *)timer {
    NSString *name = [_blinky name];
    NSUInteger len = [name length];
    if (len == 0)
        return;
    if ([name characterAtIndex:len-1] == '_')
        [_blinky setName:[name substringToIndex:len-1]];
    else
        [_blinky setName:[name stringByAppendingString:@"_"]];
}

@end
