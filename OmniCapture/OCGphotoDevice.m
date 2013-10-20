//
//  OCGphotoDevice.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <IOKit/usb/IOUSBLib.h>
#import <ImageIO/ImageIO.h>
#import "OCGphotoDevice.h"
#import "OCDeviceManager+Private.h"
#import "OCGphotoLVDistributor.h"
#import "OCGphotoLVLayer.h"
#import "OCConfig.h"

static int _OCGphotoDeviceMagic;

@interface OCGphotoDeviceConfig : OCConfig {
    OCGphotoDevice *_theDevice;
}
+ (id)configWithDevice:(OCGphotoDevice *)device;
@property (readwrite) OCGphotoDevice *theDevice;
@end

@implementation OCGphotoDevice

+ (id)deviceWithOwner:(OCDeviceManager *)owner usbDeviceHandle:(OCLocalDeviceHandle *)handle
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

    OCGphotoDevice *device = [[self alloc] initWithOwner:owner
                                                     key:key];
    
    if (device) {
        [device setHandle:handle];
        [device setName:productName];
        [device setProductName:productName];
        [device setVendorName:vendorName];
        
        char port[128];
        sprintf(port, "usb:%03d,%03d",
                [locationId intValue]>>24,
                [usbAddress intValue]);
        [device _initCameraWithGphotoPort:port async:YES];
    }

    return device;
}

- (id)initWithOwner:(OCDeviceManager *)owner
                key:(NSString *)key
{
    self = [super initWithOwner:owner key:key];
    if (self) {
        _gpContext = gp_context_new();
        int result = gp_camera_new(&_gpCamera);
        if (result < GP_OK) {
            NSLog(@"gp_camera_new: %s", gp_result_as_string(result));
            return nil;
        }
        [self _register];
    }
    return self;
}

- (void)dealloc
{
    if (_gpWidgetTree)
        gp_widget_free(_gpWidgetTree);
    if (_gpCamera)
        gp_camera_free(_gpCamera);
    if (_gpContext)
        gp_context_unref(_gpContext);
}

- (void)setHandle:(OCLocalDeviceHandle *)handle
{
    [_handle setDelegate:nil];
    [handle setDelegate:self];
    _handle = handle;
}

- (dispatch_queue_t)_dispatchQueue
{
    // lazy initialization enables capturing the name in dispatch queue label
    dispatch_once(&_once, ^{
        NSString *label = [NSString stringWithFormat:@"org.example.acme.%@",
                 [[self name] stringByReplacingOccurrencesOfString:@" " withString:@"-"]];
        _queue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding],
                                               DISPATCH_QUEUE_SERIAL);        
    });
    return _queue;
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

- (void)_initCameraWithGphotoPort:(const char *)port async:(BOOL)async
{
    if (async) {
        NSString *portCopy = [NSString stringWithCString:port
                                                encoding:NSASCIIStringEncoding];
        dispatch_async([self _dispatchQueue], ^{
            [self _initCameraWithGphotoPort:[portCopy cStringUsingEncoding:NSASCIIStringEncoding]
                                      async:NO];
        });
        return;
    }
    
    [self setIsInitializing:YES];
    [self setIsAvailable:YES];

    GPPortInfoList *ports = NULL;
    gp_port_info_list_new(&ports);
    int result = gp_port_info_list_load(ports);
    int portIdx = -1;
    if (result == GP_OK)
        result = portIdx = gp_port_info_list_lookup_path(ports, port);
    else
        NSLog(@"OCGphotoDevice: failed to enumerate ports: %s", gp_result_as_string(result));
    
    if (portIdx >= 0) {
        GPPortInfo portInfo;
        gp_port_info_list_get_info(ports, portIdx, &portInfo);
        
        result = gp_camera_set_port_info(_gpCamera, portInfo);
        if (result == GP_OK)
            result = gp_camera_init(_gpCamera, _gpContext);
    }
    
    gp_port_info_list_free(ports);
    ports = NULL;
    
    if (result == GP_OK)
        [self _updatePropertiesUsingCameraInfo];
    else
        [self setDidFailToInitialize:YES];
    [self setIsInitializing:NO];
}

- (void)_updatePropertiesUsingCameraInfo
{
    CameraText camSummary;
    int result = gp_camera_get_summary(_gpCamera, &camSummary, _gpContext);
    if (result != GP_OK) {
        NSLog(@"gp_camera_get_summary: %s", gp_result_as_string(result));
    } else {
        char *p = camSummary.text, *e, *v;
        while ((e = strchr(p, '\n')))
        {
            *e = 0;
            while (isspace(*p)) {
                p++;
            }
            v = strchr(p, ':');
            if (v) {
                *(v++) = 0;
                while (isspace(*v)) {
                    v++;
                }
                if (strcmp(p, "Manufacturer") == 0) {
                    [self setVendorName:[NSString stringWithCString:v encoding:NSUTF8StringEncoding]];
                } else if (strcmp(p, "Model") == 0) {
                    NSString *name = [NSString stringWithCString:v encoding:NSUTF8StringEncoding];
                    [self setName:name];
                    [self setProductName:name];
                }
            }
            p = e+1;
        }
    }
}

static int _CFDataWriter (void *priv, unsigned char *data, uint64_t *len)
{
    CFDataAppendBytes(priv, data, *len);
    return GP_OK;
}

- (id)createPreviewImage
{
    if (![self isReady])
        return nil;

    NSMutableData *previewBuf = [NSMutableData dataWithCapacity:0x10000];

    int result;
    CameraFileHandler gpHandler = {.write = _CFDataWriter};
    CameraFile *gpFile;
    result = gp_file_new_from_handler(&gpFile, &gpHandler, (__bridge void *)previewBuf);
    if (result != GP_OK) {
        NSLog(@"gp_file_new_from_handler: %s", gp_result_as_string(result));
        return nil;
    }
    result = gp_camera_capture_preview(_gpCamera, gpFile, _gpContext);
    gp_file_free(gpFile);
    gpFile = NULL;
    if (result != GP_OK) {
        NSLog(@"gp_camera_capture_preview: %s", gp_result_as_string(result));
        return nil;
    }
    
    CGImageSourceRef loader = CGImageSourceCreateWithData((__bridge CFDataRef)previewBuf, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(loader, 0, NULL);
    CFRelease(loader);
    return CFBridgingRelease(image);
}

- (CALayer *)createLiveViewLayer
{
    if ([self isInitializing] || [self didFailToInitialize])
        return nil;

    OCGphotoLVDistributor *lvDistributor = _lvDistributor;
    if (!lvDistributor)
        lvDistributor = _lvDistributor =
            [OCGphotoLVDistributor
             distributorWithGphotoDevice:self
             mainQueue:[[self owner] _dispatchQueue]
             workerQueue:[self _dispatchQueue]];

    return [OCGphotoLVLayer layerWithLVDistributor:lvDistributor];
}

//
// config
//

- (OCConfig *)copyConfig
{
    if ([self isInitializing] || [self didFailToInitialize])
        return nil;
    return [OCGphotoDeviceConfig configWithDevice:self];
}

- (void)didAddConfigUser:(id)user
{
    _configUsers++;
    if (_configUsers==1 && !_configIsInitializing) {
        _configIsInitializing = YES;
        _configDidInitialize = NO;
        _configItems = nil;
        _configSections = nil;
        _configItemsChanged = [NSMutableSet setWithCapacity:0];
        _configIsCommitingChanges = NO;
        _configDidCommitChanges = YES;
        
        dispatch_async(_queue, ^{
            NSArray *items = nil;
            NSArray *sections = nil;
            [self getConfigItems:&items sections:&sections];
            dispatch_async([[self owner] _dispatchQueue], ^{
                _configIsInitializing = NO;
                if (_configUsers == 0)
                    return;
                for (id item in items) {
                    [item addObserver:self
                           forKeyPath:@"value"
                              options:NSKeyValueObservingOptionNew
                              context:&_OCGphotoDeviceMagic];
                }
                [self setConfigItems:items];
                [self setConfigSections:sections];
                [self setConfigDidInitialize:YES];
            });
        });
    }
}

static CameraWidget *lookupWidgetByName(CameraWidget *w, const char *name)
{
    if (!w)
        return nil;
    const char *widgetName;
    if (gp_widget_get_name(w, &widgetName)==GP_OK
        && strcmp(name, widgetName)==0
    ) {
        return w;
    }
    for (int i=0, n=gp_widget_count_children(w); i<n; i++) {
        CameraWidget *c;
        gp_widget_get_child(w, i, &c);
        c = lookupWidgetByName(c, name);
        if (c)
            return c;
    }
    return nil;
}

static OCConfigItem *itemWithWidget(CameraWidget *w,
                                    NSString *style,
                                    NSMutableArray *items)
{
    OCConfigItem *item = [[OCConfigItem alloc] init];
#if _RESPECT_READONLY
    int readonly;
    gp_widget_get_readonly(w, &readonly);
    [item setStyle:readonly ? kOCConfigItemStyleStatic : style];
#else
    [item setStyle:style];
#endif
    const char *name;
    gp_widget_get_name(w, &name);
    if (strcmp(name, "capture")==0)
        return nil;
    [item setName:[NSString stringWithCString:name encoding:NSASCIIStringEncoding]];
    const char *label;
    gp_widget_get_label(w, &label);
    [item setLabel:[NSString stringWithCString:label encoding:NSUTF8StringEncoding]];
    [items addObject:item];
    return item;
}

static void convertWidgetTree(CameraWidget *w,
                              NSMutableArray *items,
                              NSMutableArray *sections)
{
    CameraWidgetType type;
    gp_widget_get_type(w, &type);
    switch (type)
    {
        case GP_WIDGET_TEXT: {
            OCConfigItem *item = itemWithWidget(w, kOCConfigItemStyleInput, items);
            const char *value;
            if (gp_widget_get_value(w, &value)==GP_OK && value)
                [item setValue:[NSString stringWithCString:value encoding:NSUTF8StringEncoding]];
            break;
        }
        case GP_WIDGET_TOGGLE: {
            OCConfigItem *item = itemWithWidget(w, kOCConfigItemStyleSelect, items);
            NSArray *domain = [NSArray arrayWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:YES], nil];
            [item setValuesDomain:domain];
            int value;
            if (gp_widget_get_value(w, &value)!=GP_OK)
                value = 0;
            [item setValue:[domain objectAtIndex:(value?1:0)]];
            break;
        }
        case GP_WIDGET_RANGE: {
            OCConfigItem *item = itemWithWidget(w, kOCConfigItemStyleSelect, items);
            float value, min, max, increment;
            gp_widget_get_value(w, &value);
            gp_widget_get_range(w, &min, &max, &increment);
            [item setValue:[NSNumber numberWithFloat:value]];
            NSMutableArray *domain = [NSMutableArray arrayWithCapacity:0];
            for (int i=0, n=1+(int)ceil((max-min)/increment); i<n; i++)
                [domain addObject:[NSNumber numberWithFloat:min+i*increment]];
            [item setValuesDomain:domain];
            break;
        }
        case GP_WIDGET_MENU:
        case GP_WIDGET_RADIO: {
            OCConfigItem *item = itemWithWidget(w, kOCConfigItemStyleSelect, items);
            const char *value;
            if (gp_widget_get_value(w, &value)==GP_OK && value)
                [item setValue:[NSString stringWithCString:value encoding:NSUTF8StringEncoding]];
            NSMutableArray *domain = [NSMutableArray arrayWithCapacity:0];
            for (int i=0, n=gp_widget_count_choices(w); i<n; i++) {
                const char *choice;
                if (gp_widget_get_choice(w, i, &choice)==GP_OK && choice)
                    [domain addObject:[NSString stringWithCString:choice encoding:NSUTF8StringEncoding]];
            }
            [item setValuesDomain:domain];
            break;
        }
        case GP_WIDGET_DATE: {
            NSLog(@"convertWidgetTree: GP_WIDGET_DATE");
            break;
        }
        case GP_WIDGET_BUTTON: {
            NSLog(@"convertWidgetTree: GP_WIDGET_BUTTON");
            break;
        }
        case GP_WIDGET_SECTION: {
            const char *label;
            OCConfigSection *section = [[OCConfigSection alloc] init];
            gp_widget_get_label(w, &label);
            [section setLabel:[NSString stringWithCString:label
                                                 encoding:NSUTF8StringEncoding]];
            [sections addObject:section];
            
            NSMutableArray *nestedItems = [NSMutableArray arrayWithCapacity:0];
            for (int i=0, n=gp_widget_count_children(w); i<n; i++) {
                CameraWidget *c;
                gp_widget_get_child(w, i, &c);
                convertWidgetTree(c, nestedItems, sections);
            }            
            [section setItems:[nestedItems copy]];
            break;
        }
        case GP_WIDGET_WINDOW: {
            for (int i=0, n=gp_widget_count_children(w); i<n; i++) {
                CameraWidget *c;
                gp_widget_get_child(w, i, &c);
                convertWidgetTree(c, items, sections);
            }
            break;
        }
    }
}

- (void)getConfigItems:(NSArray **)items sections:(NSArray **)sections
{
    *items = [NSArray array];
    *sections = [NSArray array];
    int result;
    // get config
    if (!_gpWidgetTree) {
        result = gp_camera_get_config(_gpCamera, &_gpWidgetTree, _gpContext);
        if (result != GP_OK) {
            NSLog(@"OCGphotoDevice: failed to get config: %s",
                  gp_result_as_string(result));
            return;
        }
    }
    // Canon taming - make sure capture is on
    CameraWidget *capture = lookupWidgetByName(_gpWidgetTree, "capture");
    if (capture) {
        CameraWidgetType type;
        gp_widget_get_type(capture, &type);
        if (type == GP_WIDGET_TOGGLE) {
            int isCaptureOn;
            gp_widget_get_value(capture, &isCaptureOn);
            if (!isCaptureOn) {
                isCaptureOn = 1;
                gp_widget_set_value(capture, &isCaptureOn);
                result = gp_camera_set_config(_gpCamera, _gpWidgetTree, _gpContext);
                if (result != GP_OK) {
                    NSLog(@"OCGphotoDevice: enabling capture: %s",
                          gp_result_as_string(result));
                } else {
                    // re-read config
                    CameraWidget *widgetTree2 = NULL;
                    result = gp_camera_get_config(_gpCamera, &widgetTree2, _gpContext);
                    if (result==GP_OK) {
                        gp_widget_free(_gpWidgetTree);
                        _gpWidgetTree = widgetTree2;
                    } else {
                        NSLog(@"OCGphotoDevice: failed to get config: %s",
                              gp_result_as_string(result));
                    }
                }
            }
        }
    }
    // and convert
    NSMutableArray *mutableItems = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *mutableSections = [NSMutableArray arrayWithCapacity:0];
    convertWidgetTree(_gpWidgetTree, mutableItems, mutableSections);
    for (OCConfigSection *section in mutableSections) {
        [mutableItems addObjectsFromArray:[section items]];
    }
    *items = [mutableItems copy];
    *sections = [mutableSections copy];
}

- (void)didRemoveConfigUser:(id)user
{
    _configUsers--;
    if (_configUsers==0) {
        for (id item in _configItems) {
            [item removeObserver:self
                      forKeyPath:@"value"
                         context:&_OCGphotoDeviceMagic];
        }
        _configItems = nil;
        _configSections = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != &_OCGphotoDeviceMagic)
        return [super observeValueForKeyPath:keyPath
                                    ofObject:object
                                      change:change
                                     context:context];

    if ([object isKindOfClass:[OCConfigItem class]]
        && [keyPath isEqualToString:@"value"]
    ) {
        [_configItemsChanged addObject:object];
        [self maybeCommitConfigChanges];
    }
}

- (void)maybeCommitConfigChanges
{
    BOOL didCommit = [_configItemsChanged count]==0;
    if (_configDidCommitChanges != didCommit)
        [self setConfigDidCommitChanges:didCommit];
    if (didCommit || _configIsCommitingChanges)
        return;
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
    for (OCConfigItem *item in _configItemsChanged) {
        [names addObject:[item name]];
        [values addObject:[item value]];
    }
    [_configItemsChanged removeAllObjects];
    _configIsCommitingChanges = YES;
    dispatch_async(_queue, ^{
        [self applyConfigChanges:names values:values];
        dispatch_async([[self owner] _dispatchQueue], ^{
            _configIsCommitingChanges = NO;
            [self maybeCommitConfigChanges];
        });
    });
}

- (void)applyConfigChanges:(NSArray *)names values:(NSArray *)values
{
    NSUInteger namesCount = [names count];
    NSUInteger valuesCount = [values count];
    int c = 0;
    for (NSUInteger i = 0; i < MIN(namesCount, valuesCount); i++) {
        NSString *name = [names objectAtIndex:i];
        id value = [values objectAtIndex:i];
        CameraWidget *w = lookupWidgetByName(_gpWidgetTree,
                                             [name cStringUsingEncoding:NSASCIIStringEncoding]);
        if (!w) {
            NSLog(@"OCGphotoDevice: applyConfigChanges not found: %@", name);
            continue;
        }
#if _RESPECT_READONLY
        int readonly;
        gp_widget_get_readonly(w, &readonly);
        if (readonly) {
            NSLog(@"OCGphotoDevice: applyConfigChanges readonly: %@", name);
            continue;
        }
#endif
        CameraWidgetType type;
        gp_widget_get_type(w, &type);
        switch (type) {
            case GP_WIDGET_TEXT:
            case GP_WIDGET_MENU:
            case GP_WIDGET_RADIO: {
                const char *v = [value cStringUsingEncoding:NSUTF8StringEncoding];
                gp_widget_set_value(w, v);
                c += 1;
                break;
            }
            case GP_WIDGET_RANGE: {
                float v = [value floatValue];
                gp_widget_set_value(w, &v);
                c += 1;
                break;
            }
            case GP_WIDGET_TOGGLE: {
                int v = [value boolValue];
                gp_widget_set_value(w, &v);
                c += 1;
                break;
            }
            default:
                NSLog(@"OCGphotoDevice: applyConfigChanges TODO: %@", name);
                continue;
        }
        if (c>0) {
            int result = gp_camera_set_config(_gpCamera, _gpWidgetTree, _gpContext);
            if (result != GP_OK)
                NSLog(@"OCGphotoDevice: gp_camera_set_config: %s",
                      gp_result_as_string(result));
        }
    }
}

@end

@implementation OCGphotoDeviceConfig

+ (id)configWithDevice:(OCGphotoDevice *)device
{
    OCGphotoDeviceConfig *config = [[OCGphotoDeviceConfig alloc] init];
    config->_theDevice = device;
    [device didAddConfigUser:config];
    return config;
}

- (void)dealloc
{
    [self invalidate];
}

- (void)invalidate
{
    OCGphotoDevice *device = _theDevice;
    if (_theDevice) {
        [self setTheDevice:nil];
        [device didRemoveConfigUser:self];
    }
}

- (NSArray *)items
{
    return [_theDevice configItems];
}

+ (NSSet *)keyPathsForValuesAffectingItems
{
    return [NSSet setWithObjects:@"theDevice.configItems", nil];
}

- (NSArray *)sections
{
    return [_theDevice configSections];
}

+ (NSSet *)keyPathsForValuesAffectingSections
{
    return [NSSet setWithObjects:@"theDevice.configSections", nil];
}

- (BOOL)didInitialize
{
    return [_theDevice configDidInitialize];
}

+ (NSSet *)keyPathsForValuesAffectingDidInitialize
{
    return [NSSet setWithObjects:@"theDevice.configDidInitialize", nil];
}

- (BOOL)didCommitChanges
{
    return [_theDevice configDidCommitChanges];
}

+ (NSSet *)keyPathsForValuesAffectingDidCommitChanges
{
    return [NSSet setWithObjects:@"theDevice.configDidCommitChanges", nil];
}

- (BOOL)commitingChanges
{
    return ![_theDevice configDidCommitChanges];
}

+ (NSSet *)keyPathsForValuesAffectingCommitingChanges
{
    return [NSSet setWithObjects:@"theDevice.configDidCommitChanges", nil];
}

@end