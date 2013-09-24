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
        [device setVendor:vendorName];
        
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
        _dispatchQueue = dispatch_queue_create([label cStringUsingEncoding:NSASCIIStringEncoding],
                                               DISPATCH_QUEUE_SERIAL);        
    });
    return _dispatchQueue;
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
                    [self setVendor:[NSString stringWithCString:v encoding:NSUTF8StringEncoding]];
                } else if (strcmp(p, "Model") == 0) {
                    [self setName:[NSString stringWithCString:v encoding:NSUTF8StringEncoding]];
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

- (CGImageRef)_createPreviewImage
{
    if (!_previewBuf)
        _previewBuf = [NSMutableData dataWithCapacity:0x10000];
    else
        [_previewBuf setLength:0];

    int result;
    CameraFileHandler gpHandler = {.write = _CFDataWriter};
    CameraFile *gpFile;
    result = gp_file_new_from_handler(&gpFile, &gpHandler, (__bridge void *)_previewBuf);
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
    
    CGImageSourceRef loader = CGImageSourceCreateWithData((__bridge CFDataRef)_previewBuf, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(loader, 0, NULL);
    CFRelease(loader);
    return image;
}

@end