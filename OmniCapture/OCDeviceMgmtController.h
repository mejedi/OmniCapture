//
//  OCMainController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManager.h"

// Controls all the device management machinery in the UI, including:
// - Available device list
// - Showing live preview for the selected device
// - Inspecting properties of the selected device
// - Initiating sample shots
// - Arranging multiple devices to participate in a capture session (alt mode)
// - Initiating capture sessions
//
@interface OCDeviceMgmtController : NSObject<
    OCDeviceManagerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    int _serial;

    NSMutableArray *_groups;
    NSMapTable *_devCleanupTimers;
}

@property (nonatomic) OCDeviceManager *deviceManager;
@property (weak) IBOutlet NSOutlineView *devOutlineView;
@property (strong) IBOutlet NSPopover *errorPopover;

- (IBAction)addDevBtnAction:(id)sender;
- (IBAction)removeDevBtnAction:(id)sender;
- (IBAction)showErrorBtnAction:(id)sender;
- (IBAction)devOutlineViewSingleClickAction:(id)sender;

- (void)invalidate;

@end
