//
//  OCMainController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManager.h"

@interface OCMainController : NSObject<OCDeviceManagerDelegate, NSTableViewDataSource, NSTableViewDelegate> {
    int _serial;
    NSTimer *_timer;
    OCDevice *_blinky;
    NSTimer *_blinkyNameTimer;

    NSMutableArray *_devList;
    NSMapTable *_devCellViews;
    NSMapTable *_devCleanupTimers;
}
- (IBAction)addDevBtnAction:(id)sender;
- (IBAction)removeDevBtnAction:(id)sender;
@property (weak) IBOutlet OCDeviceManager *deviceManager;
@property (weak) IBOutlet NSTableView *devTableView;
@property (readonly) BOOL haveVisibleItems;

@end
