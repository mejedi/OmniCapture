//
//  OCDevicePropertyCollection.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 10/18/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCConfig : NSObject

- (void)invalidate;
- (NSArray *)items;
- (NSArray *)sections;
- (BOOL)didInitialize;
- (BOOL)didCommitChanges;
- (BOOL)commitingChanges;

@end


@interface OCConfigSection : NSObject

@property (readwrite, copy) NSString *label;
@property (readwrite) NSArray *items;

@end


@interface OCConfigItem : NSObject

@property (readwrite, copy) NSString *name;
@property (readwrite, copy) id value;
@property (readwrite, copy) NSString *style;
@property (readwrite, copy) NSArray *valuesDomain;
@property (readwrite, copy) NSString *label;

@end

extern NSString *kOCConfigItemStyleStatic; /* readonly text */
extern NSString *kOCConfigItemStyleInput;   /* freeform text input */
extern NSString *kOCConfigItemStyleSelect; /* select from predefined choices */