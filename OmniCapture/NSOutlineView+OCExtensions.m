//
//  NSOutlineView+OCExtensions.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/9/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "NSOutlineView+OCExtensions.h"

@implementation NSOutlineView (OCExtensions)

- (id)oc_viewAtColumn:(NSInteger)column item:(id)item makeIfNecessary:(BOOL)makeIfNecessary {
    NSInteger row = [self rowForItem:item];
    if (row == -1)
        return nil;
    return [self viewAtColumn:column row:row makeIfNecessary:makeIfNecessary];
}

@end
