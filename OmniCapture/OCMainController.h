//
//  OCMainController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManager.h"

@interface OCMainController : NSObject<OCDeviceManagerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate> {
    int _serial;
    NSTimer *_timer;
    OCDevice *_blinky;
    NSTimer *_blinkyNameTimer;

    NSMutableArray *_groups;
    NSMapTable *_devCleanupTimers;
}

@property (weak) IBOutlet OCDeviceManager *deviceManager;
@property (weak) IBOutlet NSOutlineView *devOutlineView;
@property (weak) IBOutlet NSPopover *errorPopover;

- (IBAction)addDevBtnAction:(id)sender;
- (IBAction)removeDevBtnAction:(id)sender;
- (IBAction)showErrorBtnAction:(id)sender;
- (IBAction)devOutlineViewSingleClickAction:(id)sender;

@end
