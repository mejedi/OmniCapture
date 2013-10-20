//
//  NSOutlineView+OCExtensions.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/9/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSOutlineView (OCExtensions)
- (id)oc_viewAtColumn:(NSInteger)column item:(id)item makeIfNecessary:(BOOL)makeIfNecessary;
@end
