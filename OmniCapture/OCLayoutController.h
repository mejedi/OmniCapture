//
//  WindowController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/6/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OCBackgroundView.h"

// Controls the layout of main window.
@interface OCLayoutController : NSObject <NSSplitViewDelegate>

/*
 
+-------------------+------------------------------+--------------------+
|                   |      deviceSelectionArea     |                    |
|                   +------------------------------+                    |
| deviceBrowserArea |                              |   inspectorArea    |
|                   |          contentArea         |                    |
|                   |                              |                    |
+-------------------+------------------------------+--------------------+
|                                                                       |
|                           galleryBrowserArea                          |
|                                                                       |
+-----------------------------------------------------------------------+
 
 Content Area occupies the major part of the window.  Content area is either
 showing live preview from a capture device or it is showing an asset from
 the gallery.
 
 Device Browser Area is showing the list of available capture devices.
 
 Normally Device Selection Area is hidden.  Capture device is selected
 using the device browser.  In advanced mode Device Selection Area is enabled.
 One drag devices from the browser to the selection area; devices in the
 selection area will be used for capture.  Also in this mode selected devices are
 hidden from the device browser.
 
 Inspector enables to configure a capture device.
 
 Gallery Browser Area shows captured assets enabling export and other
 actions with assets.
 
*/

@property (weak) IBOutlet NSView *contentArea;
@property (weak) IBOutlet NSView *deviceBrowserArea;
@property (weak) IBOutlet NSView *deviceSelectionArea;
@property (weak) IBOutlet NSView *inspectorArea;
@property (weak) IBOutlet NSView *galleryBrowserArea;

@end
