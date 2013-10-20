//
//  OCButtonCellHack.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 10/20/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCButtonCellHack.h"

@implementation OCButtonCellHack

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    frame.size.width -= 6;
    return [super drawTitle:title withFrame:frame inView:controlView];
}

@end
