#import "YXLSdk.h"
#import "YXLActivationValidator.h"
#import "YXLDefinitions.h"
#import "YXLError.h"
#import "YXLJwtRequestParams.h"
#import "YXLHTTPClient.h"
#import "YXLLoginResultModel.h"
#import "YXLObserversController.h"
#import "YXLPkce.h"
#import "YXLStatesManager.h"
#import "YXLStorage.h"
#import "YXLStorageFactory.h"
#import "YXLTokenRequestParams.h"
#import "YXLURLParser.h"

@interface YXLSdk ()

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong, readonly) YXLObserversController *observersController;
@property (nonatomic, strong, readonly) YXLHTTPClient *httpClient;
@property (nonatomic, strong, readonly) id<YXLStorage> loginResultStorage;
@property (nonatomic, strong, readonly) id<YXLStorage> pkceStorage;
@property (nonatomic, strong, readonly) YXLStatesManager *statesManager;
@property (nonatomic, strong) id<YXLLoginResult> loginResult;
@property (nonatomic, assign, readonly, getter=isActivated) BOOL activated;

@end

@implementation YXLSdk

+ (YXLSdk *)shared
{
    static dispatch_once_t once;
    static YXLSdk *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (NSString *)sdkVersion
{
    return @"2.0.1";
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _observersController = [[YXLObserversController alloc] init];
        _httpClient = [[YXLHTTPClient alloc] init];
        _loginResultStorage = YXLStorageFactory.loginResultStorage;
        _pkceStorage = YXLStorageFactory.pkceStorage;
        _loginResult = [YXLLoginResultModel modelWithDictionaryRepresentation:self.loginResultStorage.storedObject];
        _statesManager = [[YXLStatesManager alloc] initWithStorage:YXLStorageFactory.statesStorage];
    }
    return self;
}

- (BOOL)activateWithAppId:(NSString *)appId error:(NSError *__autoreleasing *)error
{
    NSError *validationError = [YXLActivationValidator validateActivationWithAppId:appId];
    BOOL result = validationError == nil && NO == self.activated;
    if (result) {
        self.appId = appId;
    }
    else if (error != NULL) {
        *error = validationError;
    }
    return result;
}

- (BOOL)processUserActivity:(NSUserActivity *)userActivity
{
    NSParameterAssert(userActivity);
    return (self.activated &&
            [userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] &&
            [self processUniversalLinkURL:userActivity.webpageURL]);
}

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
    NSParameterAssert(url);
    return self.activated && [self processURL:url];
}

- (void)addObserver:(id<YXLObserver>)observer
{
    NSParameterAssert(observer);
    [self.observersController addObserver:observer];
}

- (void)removeObserver:(id<YXLObserver>)observer
{
    NSParameterAssert(observer);
    [self.observersController removeObserver:observer];
}

- (BOOL)universalLinksAvailable
{
    return UIDevice.currentDevice.systemVersion.floatValue >= 9.f;
}

- (void)authorize
{
    if (NO == self.activated) {
        [self.observersController notifyLoginDidFinishWithError:[self errorWithCode:YXLErrorCodeNotActivated]];
        return;
    }
    if (self.loginResult != nil) {
        [self.observersController notifyLoginDidFinishWithResult:self.loginResult];
        return;
    }
    NSString *state = self.statesManager.generateNewState;
    YXLPkce *pkce = [[YXLPkce alloc] init];
    self.pkceStorage.storedObject = pkce.dictionaryRepresentation;
    [self tryOpenUrlWithState:state pkce:pkce.codeChallenge];
}

- (void)tryOpenUrlWithState:(NSString *)state pkce:(NSString *)pkce
{
    NSURL *openURL = [YXLURLParser openURLWithAppId:self.appId state:state pkce:pkce];
    if ([UIApplication.sharedApplication canOpenURL:openURL]) {
        [self authorizeWithOpenURL:openURL completionHandler:^(BOOL success) {
            if (NO == success) {
                [self tryOpenUniversalLinkUrlWithState:state pkce:pkce];
            }
        }];
    }
    else {
        [self tryOpenUniversalLinkUrlWithState:state pkce:pkce];
    }
}

- (void)tryOpenUniversalLinkUrlWithState:(NSString *)state pkce:(NSString *)pkce
{
    NSURL *openURL = [YXLURLParser openURLUniversalLinkWithAppId:self.appId state:state];
    if (self.universalLinksAvailable && [UIApplication.sharedApplication canOpenURL:openURL]) {
        [self authorizeWithOpenURL:openURL completionHandler:^(BOOL success) {
            if (NO == success) {
                [self openBrowserUrlWithState:state pkce:pkce];
            }
        }];
    }
    else {
        [self openBrowserUrlWithState:state pkce:pkce];
    }
}

- (void)openBrowserUrlWithState:(NSString *)state pkce:(NSString *)pkce
{
    NSURL *url = [YXLURLParser authorizationURLWithAppId:self.appId state:state pkce:pkce];
    [self authorizeWithOpenURL:url completionHandler:nil];
}

- (void)authorizeWithOpenURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completion
{
    UIApplication *application = UIApplication.sharedApplication;
#ifdef __IPHONE_11_0
    if (@available(iOS 10_0, *)) {
#else
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
#endif
        NSDictionary *options = @{ UIApplicationOpenURLOptionUniversalLinksOnly: @NO };
        [application openURL:url options:options completionHandler:completion];
    }
    else {
        BOOL result = [application openURL:url];
        if (completion != NULL) {
            completion(result);
        }
    }
}

- (BOOL)isActivated
{
    return self.appId != nil;
}

- (void)logout
{
    self.loginResult = nil;
    self.loginResultStorage.storedObject = nil;
    self.pkceStorage.storedObject = nil;
    [self.statesManager deleteAllStates];
}

- (NSError *)errorWithCode:(YXLErrorCode)code
{
    return [NSError errorWithDomain:kYXLErrorDomain code:code userInfo:nil];
}

- (BOOL)processURL:(NSURL *)URL
{
    if (NO == [YXLURLParser isOpenURL:URL appId:self.appId]) {
        return NO;
    }
    BOOL result = NO;
    NSString *code = [YXLURLParser codeFromURL:URL];
    NSString *state = [YXLURLParser stateFromURL:URL];
    BOOL isValidState = (state == nil) ? NO : [self.statesManager isValidState:state];
    if (state != nil) {
        [self.statesManager deleteState:state];
    }
    YXLPkce *pkce = [YXLPkce modelWithDictionaryRepresentation:self.pkceStorage.storedObject];
    if (code != nil && isValidState && pkce != nil) {
        [self requestTokenByCode:code codeVerifier:pkce.codeVerifier];
        result = YES;
    }
    else {
        NSError *error;
        if (code != nil && NO == isValidState) {
            error = [self errorWithCode:YXLErrorCodeInvalidState];
        }
        else if (pkce == nil) {
            error = [self errorWithCode:YXLErrorCodeInvalidCode];
        }
        else {
            error = [YXLURLParser errorFromURL:URL];
        }
        if (error != nil) {
            [self.observersController notifyLoginDidFinishWithError:error];
            result = YES;
        }
    }
    return result;
}

- (BOOL)processUniversalLinkURL:(NSURL *)URL
{
    BOOL result = NO;
    NSString *token = [YXLURLParser tokenFromUniversalLinkURL:URL];
    NSString *state = [YXLURLParser stateFromUniversalLinkURL:URL];
    BOOL isValidState = (state == nil) ? NO : [self.statesManager isValidState:state];
    if (state != nil) {
        [self.statesManager deleteState:state];
    }
    if (token != nil && isValidState) {
        [self requestJWTByToken:token];
        result = YES;
    }
    else {
        NSError *error;
        if (token != nil && NO == isValidState) {
            error = [self errorWithCode:YXLErrorCodeInvalidState];
        }
        else {
            error = [YXLURLParser errorFromUniversalLinkURL:URL];
        }
        if (error != nil) {
            [self.observersController notifyLoginDidFinishWithError:error];
            result = YES;
        }
    }
    return result;
}

- (void)requestJWTByToken:(NSString *)token
{
    NSParameterAssert(token);
    id<YXLRequestParams> requestParams = [[YXLJwtRequestParams alloc] initWithToken:token];
    WEAKIFY_SELF;
    [self.httpClient executeRequestWithParameters:requestParams success:^(NSString *jwt) {
        STRONGIFY_SELF;
        YXLLoginResultModel *result = [[YXLLoginResultModel alloc] initWithToken:token jwt:jwt];
        self.loginResult = result;
        self.loginResultStorage.storedObject = result.dictionaryRepresentation;
        [self.observersController notifyLoginDidFinishWithResult:result];
    } failure:^(NSError *error) {
        STRONGIFY_SELF;
        [self.observersController notifyLoginDidFinishWithError:error];
    }];
}

- (void)requestTokenByCode:(NSString *)code codeVerifier:(NSString *)codeVerifier
{
    NSParameterAssert(code);
    id<YXLRequestParams> requestParams = [[YXLTokenRequestParams alloc] initWithCode:code
                                                                        codeVerifier:codeVerifier
                                                                               appId:self.appId];
    WEAKIFY_SELF;
    [self.httpClient executeRequestWithParameters:requestParams success:^(NSString *token) {
        STRONGIFY_SELF;
        [self requestJWTByToken:token];
    } failure:^(NSError *error) {
        STRONGIFY_SELF;
        [self.observersController notifyLoginDidFinishWithError:error];
    }];
}

@end
