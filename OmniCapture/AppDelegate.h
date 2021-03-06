//
//  AppDelegate.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/3/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OCDeviceMgmtController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet OCDeviceMgmtController *deviceMgmtController;

@end
