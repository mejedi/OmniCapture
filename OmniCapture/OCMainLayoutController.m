//
//  WindowController.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/6/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCMainLayoutController.h"

@interface OCMainLayoutController ()

@end

@implementation OCMainLayoutController

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    return [_contentArea isDescendantOf:subview];
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return YES;
    if ([_contentArea isDescendantOf:subview] || [_deviceSelectionArea isDescendantOf:subview])
        return NO;
    else
        return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    return 100;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex {
    return YES;
}

@end
