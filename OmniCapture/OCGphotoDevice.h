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

@class OCGphotoLVDistributor;

@interface OCGphotoDevice : OCDevice<OCLocalDeviceHandleDelegate> {
    dispatch_once_t _once;
    dispatch_queue_t _queue;
    GPContext *_gpContext;
    Camera *_gpCamera;
    NSMutableData *_previewBuf;
    __weak OCGphotoLVDistributor *_lvDistributor;
    // config support
    CameraWidget *_gpWidgetTree;
    NSUInteger _configUsers;
    BOOL _configIsInitializing;
    BOOL _configDidInitialize;
    NSArray *_configItems;
    NSArray *_configSections;
    NSMutableSet *_configItemsChanged;
    BOOL _configIsCommitingChanges;
    BOOL _configDidCommitChanges;
}
+ (id)deviceWithOwner:(OCDeviceManager *)owner usbDeviceHandle:(OCLocalDeviceHandle *)handle;
- (id)createPreviewImage;
@property (readwrite, nonatomic) OCLocalDeviceHandle *handle;

// config support
@property (readwrite) BOOL configDidInitialize;
@property (readwrite) BOOL configDidCommitChanges;
@property (readwrite) NSArray *configItems;
@property (readwrite) NSArray *configSections;
- (void)didAddConfigUser:(id)user;
- (void)didRemoveConfigUser:(id)user;

@end