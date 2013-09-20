//
//  OCGphotoDevice.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDevice.h"
#import "OCLocalDeviceHandle.h"

@interface OCGphotoDevice : OCDevice<OCLocalDeviceHandleDelegate>
@property (readwrite) OCLocalDeviceHandle *handle;
@end
