//
//  OCMainController.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <QuartzCore/CoreAnimation.h>

#import "OCMainController.h"
#import "OCDeviceManager+Private.h"
#import "OCDevice.h"

@implementation OCMainController

- (id)init {
    self = [super init];
    if (self) {
        _serial = 1;
        
        _devList = [NSMutableArray arrayWithCapacity:0];
        _devCellViews = [NSMapTable weakToStrongObjectsMapTable];
        _devCleanupTimers = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

- (void)awakeFromNib {
    if (_timer)
        return;
#if 0
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
#endif
    _timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];

}

- (IBAction)addDevBtnAction:(id)sender {
    OCDevice *foobar = [[self deviceManager] reuseDeviceWithKey:nil class:[OCDevice class]];
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

//
// OCDeviceManager stuff
//

- (void)deviceDidBecomeAvailable:(OCDevice *)adevice {
    BOOL willEmitNotifications = [_devList count] == 0;
    
    if (willEmitNotifications) {
        [self willChangeValueForKey:@"haveVisibleItems"];
    }
    
    NSUInteger idx = [_devList indexOfObject:adevice];
    
    [[_devCleanupTimers objectForKey:adevice]invalidate];
    
    if (idx == NSNotFound) {
        idx = [_devList count];
    
        NSIndexSet *idxs = [NSIndexSet indexSetWithIndex:idx];
        [_devList insertObject:adevice atIndex:idx];
    
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:.1];
        [_devTableView insertRowsAtIndexes:idxs withAnimation:NSTableViewAnimationSlideDown];
        [NSAnimationContext endGrouping];
    }
    
    if (willEmitNotifications) {
        [self didChangeValueForKey:@"haveVisibleItems"];
    }
    
    NSView *cellView = [self viewForDevice:adevice];
    [cellView setAlphaValue:.30];
    
    NSDictionary *animations = [NSDictionary
                                dictionaryWithObject:[self deviceArrivalAnimation]
                                forKey:@"alphaValue"];
    NSDictionary *oldAnimations = [cellView animations];
    [cellView setAnimations:animations];
    [[cellView animator] setAlphaValue:1.0];
    [cellView setAnimations:oldAnimations];
}

- (void)deviceWillBecomeUnavailable:(OCDevice *)adevice {
    
    NSView *cellView = [self viewForDevice:adevice];
    [[cellView animator] setAlphaValue:.30];
    
    NSTimer *cleanupTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                             target:self
                                                           selector:@selector(devCleanupTimerDidFire:)
                                                           userInfo:adevice
                                                            repeats:NO];
    [_devCleanupTimers setObject:cleanupTimer forKey:adevice];
}

-(void)devCleanupTimerDidFire:(NSTimer *)timer {
    OCDevice *device = [timer userInfo];

    NSUInteger idx = [_devList indexOfObject:device];
    NSAssert(idx != NSNotFound, @"");
    NSIndexSet *idxs = [NSIndexSet indexSetWithIndex:idx];
    BOOL willEmitNotifications = [_devList count]==1;
    
    if (willEmitNotifications) {
        [self willChangeValueForKey:@"haveVisibleItems"];
    }
    [_devList removeObjectAtIndex:idx];
    [_devTableView removeRowsAtIndexes:idxs withAnimation:NSTableViewAnimationSlideUp];
    if (willEmitNotifications) {
        [self didChangeValueForKey:@"haveVisibleItems"];
    }
}


//
// NSTableViewDataSource stuff
//

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [_devList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [_devList objectAtIndex:rowIndex];
}

//
// NSTableViewDelegate stuff
//

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id item = [_devList objectAtIndex:row];
    
    if ([item isKindOfClass:[OCDevice class]]) {
        return [self viewForDevice:item];
    }
    return nil;
}

-(NSView *)viewForDevice:(OCDevice *)aDevice {
    // We are managing DeviceCells manually instead of relying on the reuse queue (hence
    // reseting the identifier below).  The intention is to provide a unique view for each
    // OCDevice with the same lifetime as the device itself.  Makes animation easy.
    // (Consider a cell with animated contents. Animating views is easy but doing animations
    // when views are allocated on demand is complex. What if the view was allocated when
    // the content animation had played halfway through?)
    //
    // The lifetime of a DeviceCell view is bound to the corresponding OCDevice by the means
    // of NSMapTable (maps a OCDevice pointer (weak) to the corresponding NSView (strong)). The
    // corresponding table entry is automatically removed when an OCDevice is deallocated.
    NSView *aView = [_devCellViews objectForKey:aDevice];
    if (!aView) {
        aView = [_devTableView makeViewWithIdentifier:@"DeviceCell" owner:self];
        [aView setIdentifier:nil];
        [_devCellViews setObject:aView forKey:aDevice];
    }
    return aView;
}

-(void)tableView:(NSTableView *)tableView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {
    // Breaking reference cycle for DeviceCells (a cell view retains the OCDevice instance
    // aka objectValue; the living OCDevice instance prevents the corresponding DeviceCell
    // from getting deallocated, see discussion in -tableView:viewForTableColumn:row: above).
    [[rowView viewAtColumn:0] setObjectValue:nil];
}

//
// Misc (animation)
//

-(CAAnimation *)deviceArrivalAnimation {
    static const double kOCOpacityMin = 0.30;
    static const double kOCOpacityMax = 1.0;
    static const NSTimeInterval kOCPulseTime = .5;
    static const NSInteger kOCPulsesNum = 6;

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:kOCPulsesNum*2];
    
    for (NSInteger i=0; i<kOCPulsesNum; i++) {
        [values addObject:[NSNumber numberWithDouble:kOCOpacityMin]];
        [values addObject:[NSNumber numberWithDouble:kOCOpacityMax]];
    }

    // Adjusting beginTime to sync pulse animations in different table rows
    CFTimeInterval currentTime = CACurrentMediaTime();
    [animation setBeginTime:currentTime - fmod(currentTime, kOCPulseTime)];
    [animation setDuration:kOCPulseTime*kOCPulsesNum];
    [animation setValues:values];

    return animation;
}

-(BOOL)haveVisibleItems {
    return [_devList count]>0;
}

@end
