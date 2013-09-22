//
//  OCDevice+ManagerAdditions.h
//  OmniCapture
//
//  Created by Nick Zavaritsky on 9/23/13.
//  Copyright (c) 2013 Nick Zavaritsky. All rights reserved.
//

#import "OCDevice.h"

@interface OCDevice (ManagerAdditions)
- (void)_register;
- (void)_unregister;
@end
