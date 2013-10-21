//
//  OCCaptureWindowController.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 10/21/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCCaptureWindowController.h"

@interface OCCaptureWindowController ()

@end

@implementation OCCaptureWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"OCCaptureWindowController" owner:self];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)timelapseUsingDevice:(OCDevice *)device
{
    _captureDevice = device;

    _mainWindow = [NSApp mainWindow];
    if (!_savePanel) {
        _savePanel = [NSSavePanel savePanel];
        [_savePanel setPrompt:@"Start"];
        (void)[self window];
        [_savePanel setAccessoryView:_accessoryView];
    }
    [_savePanel beginSheetModalForWindow:_mainWindow
                  completionHandler:^(NSInteger result){
                      
                      if (result==NSFileHandlingPanelCancelButton)
                          return;
                      
                      _outputUrl = [_savePanel URL];
                      
                      [[NSApp keyWindow] orderOut:self];
                      [self beginCapture];
                  }];
}


- (void)beginCapture
{
    _ticks = 0;
    _counter = 1;
    _isDeviceBusy = NO;
    [self setIndication: [NSNumber numberWithInt:0]];
    [self setImages:[NSMutableArray arrayWithCapacity:0]];
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                    0, 0, dispatch_get_main_queue());
    
    dispatch_time_t period = NSEC_PER_SEC/2;
    dispatch_source_set_timer(_timer,
                              dispatch_time(DISPATCH_TIME_NOW, period),
                              period,
                              0);
    dispatch_source_set_event_handler(_timer, ^{
        _ticks ++;
        if ((_ticks % 10)==0 && !_isDeviceBusy) {
            _isDeviceBusy = YES;
            [_captureDevice
             captureImageUsingBlock:
             ^(NSData *data, NSError *error){
                                        
                 _isDeviceBusy = NO;
                 CGImageSourceRef src = CGImageSourceCreateWithData((__bridge CFDataRef)(data), nil);
                 if (src) {
                     CGImageRef thumb = CGImageSourceCreateThumbnailAtIndex(src, 0, nil);
                     if (thumb) {
                         NSImage *nsthumb = [[NSImage alloc] initWithCGImage:thumb size:NSZeroSize];
                         if (thumb)
                             CFRelease(thumb);
                         if (nsthumb) {
                             [[self mutableArrayValueForKey:@"images"] addObject:nsthumb];
                             NSRect r = [_thumbsView frameForItemAtIndex:[_images count]-1];
                             BOOL f = [_thumbsView scrollRectToVisible:r];
                             NSLog(@"%d %f %f %f %f", f, r.origin.x, r.origin.y, r.size.height, r.size.width);
                         }
                     }
                     CFRelease(src);
                 }
                 NSURL *fileUrl = [_outputUrl URLByAppendingPathComponent:[NSString stringWithFormat:@"IMG%04d.jpeg", _counter++]];

                 [[NSFileManager defaultManager]
                  createFileAtPath:[fileUrl path]
                  contents:data
                  attributes:nil];
                 
            }];
        }
        [self setIndication:[NSNumber numberWithInt:_ticks % 10]];
    });
    dispatch_resume(_timer);

    [NSApp beginSheet:[self window]
       modalForWindow:[NSApp mainWindow]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    
    [[NSFileManager defaultManager] removeItemAtURL:_outputUrl error:nil];
    
    [[NSFileManager defaultManager] createDirectoryAtURL:_outputUrl
                             withIntermediateDirectories:NO
                                              attributes:nil
                                                   error:nil];
}



- (void)stopCapture
{
    dispatch_source_cancel(_timer);
    _timer = nil;
}

- (IBAction)stopBtnAction:(id)sender {
    [self stopCapture];
    [[NSWorkspace sharedWorkspace] openURL:_outputUrl];
    [NSApp endSheet:[self window]];
    [[self window] orderOut:self];
}


@end
