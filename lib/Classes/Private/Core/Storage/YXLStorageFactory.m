#import "YXLStorageFactory.h"
#import "YXLInsecureStorage.h"
#import "YXLSecureStorage.h"

static NSString *const kYXLLoginResultStorageKey = @"YandexLoginSdkToken";
static NSString *const kYXLStatesStorageKey = @"ru.yandex.loginsdk.states";

@implementation YXLStorageFactory

+ (id<YXLStorage>)loginResultStorage
{
    return [[YXLSecureStorage alloc] initWithKey:kYXLLoginResultStorageKey];
}

+ (id<YXLStorage>)statesStorage
{
    return [[YXLInsecureStorage alloc] initWithKey:kYXLStatesStorageKey];
}

@end
