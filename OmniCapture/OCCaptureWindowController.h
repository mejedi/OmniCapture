//
//  OCCaptureWindowController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 10/21/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OCDevice.h"

@interface OCCaptureWindowController : NSWindowController<NSCollectionViewDelegate> {
    NSWindow *_mainWindow;
    NSSavePanel *_savePanel;
    OCDevice *_captureDevice;
    NSURL *_outputUrl;
    int _counter;
    dispatch_source_t _timer;
    uint64_t _ticks;
    BOOL _isDeviceBusy;
}

- (void)timelapseUsingDevice:(OCDevice *)device;

@property (strong) IBOutlet NSView *accessoryView;
@property (readwrite) NSNumber *indication;
@property (readwrite) NSMutableArray *images;
@property (weak) IBOutlet NSCollectionView *thumbsView;
- (IBAction)stopBtnAction:(id)sender;
@end
