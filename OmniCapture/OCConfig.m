//
//  OCDevicePropertyCollection.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 10/18/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCConfig.h"

NSString *kOCConfigItemStyleStatic = @"static";
NSString *kOCConfigItemStyleInput = @"input";
NSString *kOCConfigItemStyleSelect = @"select";

@implementation OCConfig

- (void)invalidate
{
    
}

- (NSArray *)items
{
    return [NSArray array];    
}

- (NSArray *)sections
{
    return [NSArray array];
}

- (BOOL)didInitialize
{
    return YES;
}

- (BOOL)didCommitChanges
{
    return YES;
}

- (BOOL)commitingChanges
{
    return NO;
}

@end

@implementation OCConfigSection
@end

@implementation OCConfigItem
@end