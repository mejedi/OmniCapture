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
+ (id)handleWithOwner:(OCLocalDeviceBackend *)owner ioKitService:(io_service_t)service;
- (void)subscribeForDeviceEventsWithNotifyPort:(IONotificationPortRef)port;
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
                                           [self _dispatchQueue]);
    }
    return self;
}

- (void)dealloc
{
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

- (void)terminate
{
    _dispatchersUsb = nil;

    if (_matchIter) {
        // Establishing IOKit notifications doesn't retain context pointers hence
        // when context release and notification delivery happens on concurrent threads
        // certain lifetime management issues can arise.
        OCDeviceManager *owner = _owner;
        [owner _notifyTerminating:self];
        IOObjectRelease(self->_matchIter);
        self->_matchIter = 0;
        dispatch_async([self _dispatchQueue], ^{
            [owner _notifyTerminated:self];
        });
    }
}

- (dispatch_queue_t)_dispatchQueue
{
    return dispatch_get_main_queue();
}

- (void)_processNotificationsWithIter:(io_iterator_t)iter
{
    io_service_t service;
    while ((service = IOIteratorNext(iter))) {
        OCLocalDeviceHandle *handle = [OCLocalDeviceHandle handleWithOwner:self
                                                              ioKitService:service];

        if (!_dispatchersUsb)
            _dispatchersUsb = [_owner _qualifyingDispatchers:@selector(dispatchUsbDevice:)];
        
        for (id<OCUsbDeviceDispatcher> dispatcher in _dispatchersUsb) {
            if ([dispatcher dispatchUsbDevice:handle]) {
                [handle subscribeForDeviceEventsWithNotifyPort:_notifyPort];
                break;
            }
        }
        
        IOObjectRelease(service);
    }
}

- (void)_notifyTerminating:(id)sender
{
    [_owner _notifyTerminating:sender];
}

- (void)_notifyTerminated:(id)sender
{
    [_owner _notifyTerminated:sender];
}

@end

@implementation OCLocalDeviceHandle

+ (id)handleWithOwner:(OCLocalDeviceBackend *)owner ioKitService:(io_service_t)service
{
    return [[OCLocalDeviceHandle alloc] initWithOwner:owner ioKitService:service];
}

- (id)initWithOwner:(OCLocalDeviceBackend *)owner ioKitService:(io_service_t)service
{
    self = [super init];
    if (self) {
        _owner = owner;
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

- (void)terminate
{
    @synchronized (self) {
        if (_service) {
            IOObjectRelease(_service);
            _service = 0;
        }

        if (!_notification)
            return;
        
        // see notes in OCLocalDeviceBackend terminate:
        OCLocalDeviceBackend *owner = _owner;
        io_object_t notification = _notification;
        _notification = 0;
        [owner _notifyTerminating:self];
        dispatch_async([_owner _dispatchQueue], ^{
            IOObjectRelease(notification);
            [owner _notifyTerminated:self];
        });
    }
}

- (void)dealloc
{
    if (_notification)
        IOObjectRelease(_notification);
    if (_service)
        IOObjectRelease(_service);
}

static void callback2(void *user, io_service_t service, natural_t msgType, void *msgArg)
{
    OCLocalDeviceHandle *handle = (__bridge id)user;
    if (msgType == kIOMessageServiceIsTerminated)
        [[handle delegate] deviceDidDisconnect:handle];
}

- (void)subscribeForDeviceEventsWithNotifyPort:(IONotificationPortRef)port
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
