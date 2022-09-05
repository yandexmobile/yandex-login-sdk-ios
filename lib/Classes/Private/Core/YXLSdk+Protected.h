#import "YXLSdk.h"

static NSString const* kYXLTestEnvironmentKey = @"YXLUseTestEnvironment";

@interface YXLSdk (Protected)

@property (nonatomic, readonly) BOOL shouldUseTestEnvironment;

@end
