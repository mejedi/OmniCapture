//
//  OCGphotoLVDistributor.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/25/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCGphotoLVDistributor.h"
#import "OCGphotoDevice.h"

@implementation OCGphotoLVDistributor

+ (id)distributorWithGphotoDevice:(OCGphotoDevice *)device
                        mainQueue:(dispatch_queue_t)mainQueue
                      workerQueue:(dispatch_queue_t)workerQueue
{
    OCGphotoLVDistributor *distributor = [[self alloc] init];
    __weak OCGphotoLVDistributor *weakDistributor = distributor;
    if (distributor) {
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, workerQueue);
        
        dispatch_source_set_event_handler(timer, ^{
            id frame = [device createPreviewImage];
            dispatch_async(mainQueue, ^{
                [weakDistributor setLastFrame:frame];
            });
        });
        
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, NSEC_PER_SEC/60, 0);
        dispatch_resume(timer);
        
        distributor->_captureTimer = timer;
    }
    return distributor;
}

- (void)dealloc
{
    if (_captureTimer)
        dispatch_source_cancel(_captureTimer);
}

@end