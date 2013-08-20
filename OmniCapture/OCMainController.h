//
//  OCMainController.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 8/19/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCDeviceManager.h"

@interface OCMainController : NSObject {
    int _serial;
}
- (IBAction)addDevBtnAction:(id)sender;
- (IBAction)removeDevBtnAction:(id)sender;
@property (weak) IBOutlet OCDeviceManager *deviceManager;
@end
