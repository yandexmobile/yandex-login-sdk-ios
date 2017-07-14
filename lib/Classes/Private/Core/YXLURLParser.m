#import "YXLURLParser.h"
#import "YXLError.h"
#import "YXLQueryUtils.h"
#import "YXLStatisticsDataProvider.h"

static NSString *const kYXLURLOAuthPath = @"https://oauth.yandex.ru/authorize";
static NSString *const kYXLURLOpenUrlScheme = @"yandexauth";
static NSString *const kYXLURLOpenUrlHost = @"authorize";
static NSString *const kYXLURLResponseTypeKey = @"response_type";
static NSString *const kYXLURLResponseTypeToken = @"token";
static NSString *const kYXLURLClientIdKey = @"client_id";
static NSString *const kYXLURLForceConfirmKey = @"force_confirm";
static NSString *const kYXLURLForceConfirmYes = @"yes";
static NSString *const kYXLURLOriginKey = @"origin";
static NSString *const kYXLURLOriginIos = @"yandex_auth_sdk_ios";
static NSString *const kYXLURLRedirectUriKey = @"redirect_uri";
static NSString *const kYXLURLRedirectUriScheme = @"https";
static NSString *const kYXLURLRedirectUriHostFormat = @"yx%@.oauth.yandex.ru";
static NSString *const kYXLURLRedirectUriPath = @"/auth/finish";
static NSString *const kYXLURLRedirectUriQuery = @"platform=ios";
static NSString *const kYXLURLStateKey = @"state";

static NSString *const kYXLURLErrorKey = @"error";
static NSString *const kYXLURLTokenKey = @"access_token";

struct {
    __unsafe_unretained NSString *const accessDenied;
    __unsafe_unretained NSString *const invalidScope;
    __unsafe_unretained NSString *const invalidClient;
} static const YXLURLParserErrorValues = {
    .accessDenied = @"access_denied",
    .invalidScope = @"invalid_scope",
    .invalidClient = @"invalid_client",
};

@implementation YXLURLParser

+ (NSString *)openURLScheme
{
    return kYXLURLOpenUrlScheme;
}

+ (NSURL *)authorizationURLWithAppId:(NSString *)appId state:(NSString *)state
{
    return [self urlWithPath:kYXLURLOAuthPath
                       appId:appId
                       state:state
        statisticsParameters:YXLStatisticsDataProvider.statisticsParameters];
}

+ (NSURL *)openURLWithAppId:(NSString *)appId state:(NSString *)state
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = self.openURLScheme;
    components.host = kYXLURLOpenUrlHost;
    return [self urlWithPath:components.URL.absoluteString appId:appId state:state statisticsParameters:nil];
}

+ (NSURL *)urlWithPath:(NSString *)path appId:(NSString *)appId state:(NSString *)state statisticsParameters:(NSDictionary *)statisticsParameters
{
    NSMutableDictionary *parameters = [statisticsParameters ?: @{} mutableCopy];
    parameters[kYXLURLResponseTypeKey] = kYXLURLResponseTypeToken;
    parameters[kYXLURLForceConfirmKey] = kYXLURLForceConfirmYes;
    parameters[kYXLURLOriginKey] = kYXLURLOriginIos;
    parameters[kYXLURLClientIdKey] = appId;
    parameters[kYXLURLStateKey] = state;
    parameters[kYXLURLRedirectUriKey] = [self redirectURIWithAppId:appId];
    NSString *query = [YXLQueryUtils queryStringFromParameters:parameters];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", path, query]];
}

+ (NSString *)redirectURIWithAppId:(NSString *)appId
{
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = kYXLURLRedirectUriScheme;
    components.host = [NSString stringWithFormat:kYXLURLRedirectUriHostFormat, appId];
    components.path = kYXLURLRedirectUriPath;
    components.query = kYXLURLRedirectUriQuery;
    return components.URL.absoluteString;
}

+ (NSError *)errorFromURL:(NSURL *)url
{
    NSString *errorValue = [self parametersFromURL:url][kYXLURLErrorKey];
    return (errorValue != nil) ?
            [NSError errorWithDomain:kYXLErrorDomain
                                code:[self errorCodeFromValue:errorValue]
                            userInfo:@{ NSLocalizedFailureReasonErrorKey: errorValue }]
            : nil;
}

+ (NSString *)tokenFromURL:(NSURL *)url
{
    return [self parametersFromURL:url][kYXLURLTokenKey];
}

+ (NSString *)stateFromURL:(NSURL *)url
{
    return [self parametersFromURL:url][kYXLURLStateKey];
}

+ (NSDictionary<NSString *, NSString *> *)parametersFromURL:(NSURL *)url
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    return [YXLQueryUtils parametersFromQueryString:components.fragment];
}

+ (YXLErrorCode)errorCodeFromValue:(NSString *)value
{
    NSParameterAssert(value);
    YXLErrorCode code = YXLErrorCodeOther;
    if ([value isEqualToString:YXLURLParserErrorValues.accessDenied]) {
        code = YXLErrorCodeDenied;
    }
    else if ([value isEqualToString:YXLURLParserErrorValues.invalidClient]) {
        code = YXLErrorCodeInvalidClient;
    }
    else if ([value isEqualToString:YXLURLParserErrorValues.invalidScope]) {
        code = YXLErrorCodeInvalidScope;
    }
    return code;
}

@end
