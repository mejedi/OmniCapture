//
//  OCMainController.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <QuartzCore/CoreAnimation.h>

#import "OCDeviceMgmtController.h"
#import "OCDeviceManager+Private.h"
#import "OCDevice.h"
#import "NSOutlineView+OCExtensions.h"

@interface _OCDeviceGroup : NSObject
@property (readonly) NSMutableArray *devices;
@property (readwrite, copy) NSString *name;
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

@implementation OCDeviceMgmtController

- (id)init {
    self = [super init];
    if (self) {
        _serial = 1;
        
        _groups = [NSMutableArray arrayWithCapacity:1];
        [_groups addObject:[[_OCDeviceGroup alloc] initWithName:@"DEVICES"]];
        
        _devCleanupTimers = [NSMapTable weakToWeakObjectsMapTable];
        
        [self addObserver:self
               forKeyPath:@"selectedDevice.isReady"
                  options:NSKeyValueObservingOptionNew
                  context:0];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"selectedDevice.isReady"];
}

- (void)invalidate
{
    [[self deviceManager] invalidate];
}

- (void)awakeFromNib {
    NSOutlineView *outlineView = [self devOutlineView];
    [outlineView reloadData];
    [outlineView expandItem:nil expandChildren:YES];
}

- (void)setDeviceManager:(OCDeviceManager *)deviceManager
{
    [_deviceManager setDelegate:nil];
    [deviceManager setDelegate:self];
    _deviceManager = deviceManager;
}

- (IBAction)addDevBtnAction:(id)sender {
    OCDevice *foobar = [[OCDevice alloc] initWithOwner:[self deviceManager] key:nil];
    [foobar _register];
    [foobar setName:[NSString stringWithFormat:@"Camera #%d", _serial++]];
    [foobar setIsAvailable:YES];
}

- (IBAction)removeDevBtnAction:(id)sender {
    OCDevice *victim = [[[self deviceManager] enumeratorOfDevices] nextObject];
    if (victim) {
        [victim invalidate];
        [victim _unregister];
    }
}

//
// OCDeviceManager stuff
//

- (void)deviceDidBecomeAvailable:(OCDevice *)adevice {
    [NSSet setWithObject:adevice];
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
    if ([device isAvailable]) {
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
        return 24;
    NSLog(@"Unexpected kind of entity in outline view: %@", item);
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if ([item isKindOfClass:[_OCDeviceGroup class]])
        return NO;
    return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_devOutlineView selectedRow];
    id entity = nil;
    if (row != -1)
        entity = [_devOutlineView itemAtRow:row];
    if (![entity isKindOfClass:[OCDevice class]])
        entity = nil;
    [self setSelectedDevice:entity];
}

//
// NSTableViewDelegate
//

enum ConfigItemClass {
    kOCConfigItemClassStatic,
    kOCConfigItemClassInput,
    kOCConfigItemClassSelect,
    kOCConfigItemClassCheckBox,
    kOCConfigItemClassCheckBoxWithOnOffMapping
};

static enum ConfigItemClass classifyConfigItem(OCConfigItem *item)
{
    NSString *style = [item style];
    if ([style isEqualToString:kOCConfigItemStyleInput]) {
        return kOCConfigItemClassInput;
    }
    if ([style isEqualToString:kOCConfigItemStyleSelect]) {
        NSArray *domain = [item valuesDomain];
        if ([domain isEqualToArray:@[@NO,@YES]])
            return kOCConfigItemClassCheckBox;
#if 0
        if ([domain isEqualToArray:@[@"On",@"Off"]]
            || [domain isEqualToArray:@[@"Off",@"On"]])
            return kOCConfigItemClassCheckBoxWithOnOffMapping;
#endif
        if ([domain count]<=1)
            return kOCConfigItemClassStatic;
        return kOCConfigItemClassSelect;
    }
    return kOCConfigItemClassStatic;
    
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    OCConfigItem *item = [[_configArrayController arrangedObjects] objectAtIndex:row];
    if (![item isKindOfClass:[OCConfigItem class]])
        return nil;
    switch (classifyConfigItem(item)) {
        case kOCConfigItemClassStatic:
        case kOCConfigItemClassInput:
            return [_configTableView makeViewWithIdentifier:@"TextCell" owner:self];;
        case kOCConfigItemClassSelect:
            return [_configTableView makeViewWithIdentifier:@"SelectCell" owner:self];;
        case kOCConfigItemClassCheckBox:
        case kOCConfigItemClassCheckBoxWithOnOffMapping:
            return [_configTableView makeViewWithIdentifier:@"CheckCell" owner:self];;
    }

}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    OCConfigItem *item = [[_configArrayController arrangedObjects] objectAtIndex:row];
    if (![item isKindOfClass:[OCConfigItem class]])
        return 0;
    switch (classifyConfigItem(item)) {
        case kOCConfigItemClassStatic:
        case kOCConfigItemClassInput:
            return 23;
        case kOCConfigItemClassSelect:
            return 25;
        case kOCConfigItemClassCheckBox:
        case kOCConfigItemClassCheckBoxWithOnOffMapping:
            return 23;
    }
}

//
//
//

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"selectedDevice.isReady"]) {
        [self _setupOrTeardownPreview];
        [_selectedDeviceConfig invalidate];
        [self setSelectedDeviceConfig:[_selectedDevice copyConfig]];
    }
}

- (void)_setupOrTeardownPreview
{
    [_previewFrame setSubviews:[NSArray array]];
    CALayer *layer = [_selectedDevice createLiveViewLayer];

    if (layer) {
        //CALayer *mask = [CALayer layer];
        
        [layer setContentsGravity:kCAGravityResize];
        //[layer setCornerRadius:6.0];
        //[layer setMasksToBounds:YES];
        [layer setShadowOpacity:0.5];
        [layer setShadowOffset:CGSizeMake(5.0, -5.0)];
        
        CALayer *wrapper = [CALayer layer];
        [wrapper addSublayer:layer];
        [wrapper setLayoutManager:self];

        NSView *view = [[NSView alloc] init];
        [view setFrameSize:[_previewFrame frame].size];
        [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [view setWantsLayer:YES];
        [view setLayer:wrapper];
        [_previewFrame addSubview:view];
    }
}

- (void)layoutSublayersOfLayer:(CALayer *)container
{
    for (CALayer *content in [container sublayers]) {
        CGRect frame = CGRectInset([container frame], 16.0, 16.0);
        CGSize contentNaturalSize = [content preferredFrameSize];
        CGRect contentRect = CGRectZero;
        if (contentNaturalSize.height!=0.0 && contentNaturalSize.width!=0.0) {
            CGFloat kx = frame.size.width/contentNaturalSize.width;
            CGFloat ky = frame.size.height/contentNaturalSize.height;
            CGFloat k = MIN(MIN(kx, ky), 1.33);
            CGRect r = CGRectMake(0.0,
                                  0.0,
                                  k*contentNaturalSize.width,
                                  k*contentNaturalSize.height);
            contentRect = CGRectIntegral(CGRectOffset(r,
                                                      frame.origin.x + (frame.size.width-r.size.width)*0.5,
                                                      frame.origin.y + (frame.size.height-r.size.height)*0.95));
        }
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.0f]
                         forKey:kCATransactionAnimationDuration];
        [content setFrame:contentRect];
        [CATransaction commit];
    }
}

+ (NSSet *)keyPathsForValuesAffectingAppTitle
{
    return [NSSet setWithObjects:@"selectedDevice.name", nil];
}

- (NSString *)appTitle
{
    NSString *name = [[self selectedDevice] name];
    if (!name)
        return @"OmniCapture";
    else
        return [NSString stringWithFormat:@"OmniCapture — %@", name, nil];
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
    [animation setBeginTime:currentTime + kOCPulseTime - fmod(currentTime, kOCPulseTime)];
    [animation setDuration:kOCPulseTime*kOCPulsesNum];
    [animation setValues:values];

    return animation;
}

- (IBAction)showErrorBtnAction:(id)sender {
    [_errorPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
}

- (IBAction)startCaptureBtnAction:(id)sender {
    if (!_selectedDevice)
        return;
    if (!_captureController)
        _captureController = [[OCCaptureWindowController alloc] init];
    [_captureController timelapseUsingDevice:[self selectedDevice]];
}

@end

