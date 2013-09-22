#import "OCDeviceManagerBackend.h"

@implementation OCDeviceManagerBackend

+ (id)backendWithOwner:(OCDeviceManager *)owner
{
    @throw [NSException exceptionWithName:@"OCException"
                                   reason:[NSString stringWithFormat:@"override +backendWithOwner: in %@", NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (void)start
{
}

- (void)invalidate
{
}

@end