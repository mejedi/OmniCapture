//
//  NZSolidBackground.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/6/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "SolidBackground.h"

@implementation SolidBackground

- (void)drawRect:(NSRect)dirtyRect
{
    if (_fillColor) {
        [_fillColor setFill];
        NSRectFill(dirtyRect);
    }
}

- (BOOL)isOpaque
{
    return _fillColor != nil;
}

@end
