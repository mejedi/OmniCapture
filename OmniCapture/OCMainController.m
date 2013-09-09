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
#import "NSOutlineView+OCExtensions.h"

@interface _OCDeviceGroup : NSObject
@property (readonly) NSMutableArray *devices;
@property (readwrite) NSString *name;
@end

@implementation _OCDeviceGroup
- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _devices = [NSMutableArray arrayWithCapacity:0];
        _name = name;
    }
    return self;
}

@end

@implementation OCMainController

- (id)init {
    self = [super init];
    if (self) {
        _serial = 1;
        
        _groups = [NSMutableArray arrayWithCapacity:1];
        [_groups addObject:[[_OCDeviceGroup alloc] initWithName:@"CAMERAS"]];
        [_groups addObject:[[_OCDeviceGroup alloc] initWithName:@"TESTING"]];
        
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
    NSOutlineView *outlineView = [self devOutlineView];
    [outlineView reloadData];
    [outlineView expandItem:nil expandChildren:YES];
}

- (IBAction)addDevBtnAction:(id)sender {
    OCDevice *foobar = [[self deviceManager] reuseDeviceWithKey:nil class:[OCDevice class]];
    [foobar setName:[NSString stringWithFormat:@"Camera #%d", _serial]];
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
        [_blinky setName:@"PowerShot A640"];
        [_blinky setError:YES];
        [_blinky setAvailable:YES];
        _blinkyNameTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(blinkyNameTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)blinkyNameTimerDidFire:(NSTimer *)timer {
#if 0
    NSString *name = [_blinky name];
    NSUInteger len = [name length];
    if (len == 0)
        return;
    if ([name characterAtIndex:len-1] == '_')
        [_blinky setName:[name substringToIndex:len-1]];
    else
        [_blinky setName:[name stringByAppendingString:@"_"]];
#endif
}

//
// OCDeviceManager stuff
//

- (void)deviceDidBecomeAvailable:(OCDevice *)adevice {
    _OCDeviceGroup *group = [_groups objectAtIndex:0];
    NSUInteger idx = [[group devices] indexOfObject:adevice];
    
    [[_devCleanupTimers objectForKey:adevice]invalidate];
    
    if (idx == NSNotFound) {
        idx = [[group devices] count];
    
        NSIndexSet *idxs = [NSIndexSet indexSetWithIndex:idx];
        [[group devices] insertObject:adevice atIndex:idx];
    
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:.1];
        [[self devOutlineView] insertItemsAtIndexes:idxs inParent:group withAnimation:NSTableViewAnimationSlideDown];
        [NSAnimationContext endGrouping];
    }
    
    NSView *cellView = [[self devOutlineView] oc_viewAtColumn:0 item:adevice makeIfNecessary:NO];
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
    
    NSView *cellView = [[self devOutlineView] oc_viewAtColumn:0 item:adevice makeIfNecessary:NO];
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
    if ([device available]) {
        return;
    }

    _OCDeviceGroup *group = [_groups objectAtIndex:0];
    NSUInteger idx = [[group devices] indexOfObject:device];
    NSAssert(idx != NSNotFound, @"");
    NSIndexSet *idxs = [NSIndexSet indexSetWithIndex:idx];
    [[group devices] removeObjectAtIndex:idx];
    [[self devOutlineView] removeItemsAtIndexes:idxs inParent:group withAnimation:NSTableViewAnimationSlideUp];
}


//
// NSOutlineViewDataSource stuff
//

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return YES;
    return NO;
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    /* toplevel */
    if (item == nil)
        return [_groups count];
    /* a device group */
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return [[item devices] count];
    /* a device */
    if ([item isKindOfClass:[OCDevice class]])
        return 0;
    NSLog(@"Unexpected kind of entity in outline view: %@", item);
    return 0;
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    /* toplevel */
    if (item == nil)
        return [_groups objectAtIndex:index];
    /* a device group */
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return [[item devices] objectAtIndex:index];
    NSLog(@"Unexpected kind of entity in outline view: %@", item);
    return nil;
}

//
// NSOutlineVIewDelegate stuff
//

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return [[self devOutlineView] makeViewWithIdentifier:@"HeaderCell" owner:self];
    if ([item isKindOfClass:[OCDevice class]])
        return [[self devOutlineView] makeViewWithIdentifier:@"DeviceCell" owner:self];
    NSLog(@"Unexpected kind of entity in outline view: %@", item);
    return nil;
}

-(CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return [_groups indexOfObject:item] == 0 ? 25 : 31;
    if ([item isKindOfClass:[OCDevice class]])
        return 32;
    NSLog(@"Unexpected kind of entity in outline view: %@", item);
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return NO;
    return YES;
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

- (IBAction)showErrorBtnAction:(id)sender {
    [_errorPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}
    
@end

