//
//  OCDeviceManager+Private.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDeviceManager.h"
#import "OCDevice+ManagerAdditions.h"

@interface OCDeviceManager ()

// Executes code that can potentially affect the UI on the proper thread
// (Ex: modifications of KVO-conformant properties)
- (dispatch_queue_t)_dispatchQueue;


// Enables device manager to wait for async termination
- (void)_asyncCleanupPending:(id)sender;
- (void)_asyncCleanupCompleted:(id)sender;

// Select a subset of backends (those ones that respond to the given selector)
- (NSArray *)_qualifyingDispatchersBySelector:(SEL)selector;
@end
