//
//  OCGphotoLVDistributor.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/25/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCGphotoDevice;

// Live View distributor (sourcing multiple CALayers with a single device).
// Layers (OCGphotoLVLayer) subscribe to lastFrame property changes via KVO.
@interface OCGphotoLVDistributor : NSObject {
    dispatch_source_t _captureTimer;
}
+ (id)distributorWithGphotoDevice:(OCGphotoDevice *)device
                        mainQueue:(dispatch_queue_t)mainQueue
                      workerQueue:(dispatch_queue_t)workerQueue;
@property (readwrite, nonatomic) id lastFrame;

// Presumably makes KVO operations more efficient
@property (readwrite, nonatomic) void *observationInfo;
@end