//
//  OCLocalDeviceBackend.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOMessage.h>
#import "OCLocalDeviceBackend.h"
#import "OCDeviceManager+Private.h"
#import "OCLocalDeviceHandle.h"

@interface OCLocalDeviceHandle ()
+ (id)handleWithBackend:(OCLocalDeviceBackend *)backend ioKitService:(io_service_t)service;
- (void)subscribeForEventsWithNotifyPort:(IONotificationPortRef)port;
@end

@implementation OCLocalDeviceBackend

+ (id)backendWithOwner:(OCDeviceManager *)owner
{
    return [[OCLocalDeviceBackend alloc] initWithOwner:owner];
}

- (id)initWithOwner:(OCDeviceManager *)owner
{
    self = [super init];
    if (self) {
        _owner = owner;
        _notifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        IONotificationPortSetDispatchQueue(_notifyPort,
                                           [_owner _dispatchQueue]);
    }
    return self;
}

- (void)dealloc
{
    if (_matchIter) {
        NSLog(@"OCLocalDeviceBackend: should invalidate before dealloc");
        IOObjectRelease(_matchIter);
    }
    if (_notifyPort)
        IONotificationPortDestroy(_notifyPort);
}

static void callback(void *c, io_iterator_t iter)
{
    [(__bridge OCLocalDeviceBackend *)c _processNotificationsWithIter:iter];
}

- (void)start
{
    kern_return_t kr;
    kr = IOServiceAddMatchingNotification(_notifyPort,
                                          kIOFirstMatchNotification,
                                          IOServiceMatching(kIOUSBDeviceClassName),
                                          callback,
                                          (__bridge void *)self,
                                          &_matchIter);
    
    [self _processNotificationsWithIter:_matchIter];
}

- (void)invalidate
{
    _dispatchersUsb = nil;

    if (_matchIter) {
        IOObjectRelease(self->_matchIter);
        self->_matchIter = 0;
    }
}

- (void)_processNotificationsWithIter:(io_iterator_t)iter
{
    io_service_t service;
    while ((service = IOIteratorNext(iter))) {
        OCLocalDeviceHandle *handle = [OCLocalDeviceHandle handleWithBackend:self
                                                                ioKitService:service];

        if (!_dispatchersUsb)
            _dispatchersUsb = [_owner _qualifyingDispatchersBySelector:@selector(localDeviceBackend:dispatchUsbDevice:)];
        
        for (id<OCUsbDeviceDispatcher> dispatcher in _dispatchersUsb) {
            if ([dispatcher localDeviceBackend:self dispatchUsbDevice:handle]) {
                [handle subscribeForEventsWithNotifyPort:_notifyPort];
                break;
            }
        }
        
        IOObjectRelease(service);
    }
}

- (OCDeviceManager *)owner
{
    return _owner;
}

@end

@implementation OCLocalDeviceHandle

+ (id)handleWithBackend:(OCLocalDeviceBackend *)backend ioKitService:(io_service_t)service
{
    return [[OCLocalDeviceHandle alloc] initWithBackend:backend ioKitService:service];
}

- (id)initWithBackend:(OCLocalDeviceBackend *)backend ioKitService:(io_service_t)service
{
    self = [super init];
    if (self) {
        _backend = backend;
        _service = service;
        IOObjectRetain(service);
        
        CFMutableDictionaryRef props;
        kern_return_t kr;
        kr = IORegistryEntryCreateCFProperties(service, &props, NULL, 0);
        if (kr != KERN_SUCCESS)
            NSLog(@"IORegistryEntryCreateCFProperties");
        else
            _properties = CFBridgingRelease(props);

    }
    return self;
}

- (void)close
{
    @synchronized (self) {
        if (_service) {
            IOObjectRelease(_service);
            _service = 0;
        }

        if (!_notification)
            return;
        
        // Establishing IOKit notifications doesn't retain context pointers hence
        // when context release and notification delivery happens on concurrent threads
        // certain lifetime management issues can arise.
        IOObjectRelease(_notification);
        _notification = 0;
        OCDeviceManager *manager = [_backend owner];
        [manager _asyncCleanupPending:self];
        dispatch_async([manager _dispatchQueue], ^{
            // important! capturing self in block, hence concurrent callback2 won't crash
            [manager _asyncCleanupCompleted:self];
        });
    }
}

- (void)dealloc
{
    if (_notification) {
        NSLog(@"OCLocalDeviceHandle: should close before dealloc");
        IOObjectRelease(_notification);
    }
    if (_service)
        IOObjectRelease(_service);
}

static void callback2(void *user, io_service_t service, natural_t msgType, void *msgArg)
{
    OCLocalDeviceHandle *handle = (__bridge id)user;
    if (msgType == kIOMessageServiceIsTerminated)
        [[handle delegate] localDeviceHandleDidClose:handle];
}

- (void)subscribeForEventsWithNotifyPort:(IONotificationPortRef)port
{
    kern_return_t kr;
    kr = IOServiceAddInterestNotification(port,
                                          _service,
                                          kIOGeneralInterest,
                                          callback2,
                                          (__bridge void *)self,
                                          &_notification);
}

@end
