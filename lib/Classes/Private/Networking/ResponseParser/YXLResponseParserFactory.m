#import "YXLResponseParserFactory.h"
#import "YXLDefinitions.h"
#import "YXLJwtRequestParams.h"
#import "YXLJwtResponseParser.h"

@implementation YXLResponseParserFactory

+ (id<YXLResponseParser>)parserForRequestParams:(id<YXLRequestParams>)requestParams
{
    if ([requestParams isKindOfClass:[YXLJwtRequestParams class]]) {
        return [[YXLJwtResponseParser alloc] init];
    }
    return nil;
}

@end
