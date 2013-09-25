//
//  OCGphotoLVLayer.m
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/25/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCGphotoLVLayer.h"
#import "OCGphotoLVDistributor.h"

@implementation OCGphotoLVLayer

static int magicCookie;

+ (id)layerWithLVDistributor:(OCGphotoLVDistributor *)distributor
{
    OCGphotoLVLayer *layer = [[self alloc] init];
    if (layer) {
        layer->_distributor = distributor;
        [distributor addObserver:layer
                      forKeyPath:@"lastFrame"
                         options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial
                         context:&magicCookie];
    }
    return layer;
}

- (void)dealloc
{
    [_distributor removeObserver:self
                      forKeyPath:@"lastFrame"
                         context:&magicCookie];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != &magicCookie)
        return [super observeValueForKeyPath:keyPath
                                    ofObject:object
                                      change:change
                                     context:context];
    if (object == _distributor && [keyPath isEqualToString:@"lastFrame"])
        [self setContents:[change objectForKey:NSKeyValueChangeNewKey]];
}

@end
