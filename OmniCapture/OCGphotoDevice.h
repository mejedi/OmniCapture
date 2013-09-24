//
//  OCGphotoDevice.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <gphoto2/gphoto2.h>
#import "OCDevice.h"
#import "OCLocalDeviceHandle.h"

@interface OCGphotoDevice : OCDevice<OCLocalDeviceHandleDelegate> {
    dispatch_once_t _once;
    dispatch_queue_t _dispatchQueue;
    GPContext *_gpContext;
    Camera *_gpCamera;
    NSMutableData *_previewBuf;
}
+(id)deviceWithOwner:(OCDeviceManager *)owner usbDeviceHandle:(OCLocalDeviceHandle *)handle;
@property (readwrite, nonatomic) OCLocalDeviceHandle *handle;
@end