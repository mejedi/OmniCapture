//
//  OCGphotoLVLayer.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/25/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class OCGphotoLVDistributor;

@interface OCGphotoLVLayer : CALayer {
    OCGphotoLVDistributor *_distributor;
}
+ (id)layerWithLVDistributor:(OCGphotoLVDistributor *)distributor;
@end
