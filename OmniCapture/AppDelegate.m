//
//  AppDelegate.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/3/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "AppDelegate.h"
#import "OCDeviceManager.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[self deviceMgmtController] setDeviceManager:[[OCDeviceManager alloc] init]];
}

-(void)applicationWillTerminate:(NSNotification *)notification
{
    [[self deviceMgmtController] invalidate];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
