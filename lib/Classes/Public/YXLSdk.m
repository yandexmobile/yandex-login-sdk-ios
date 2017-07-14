#import "YXLSdk.h"
#import "YXLActivationValidator.h"
#import "YXLDefinitions.h"
#import "YXLError.h"
#import "YXLJwtRequestParams.h"
#import "YXLHTTPClient.h"
#import "YXLLoginResultModel.h"
#ifdef YXL_USE_WEBVIEW
#import "YXLLoginWebViewController.h"
#endif
#import "YXLObserversController.h"
#import "YXLSpinnerController.h"
#import "YXLStatesManager.h"
#import "YXLStorage.h"
#import "YXLStorageFactory.h"
#import "YXLURLParser.h"

#ifdef YXL_USE_WEBVIEW
@interface YXLSdk () <YXLLoginWebViewControllerDelegate>
#else
@interface YXLSdk ()
#endif

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong, readonly) YXLObserversController *observersController;
@property (nonatomic, strong, readonly) YXLHTTPClient *httpClient;
@property (nonatomic, strong, readonly) id<YXLStorage> loginResultStorage;
@property (nonatomic, strong, readonly) YXLStatesManager *statesManager;
@property (nonatomic, strong) id<YXLLoginResult> loginResult;
@property (nonatomic, weak) UIViewController *presentedViewController;
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

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _observersController = [[YXLObserversController alloc] init];
        _httpClient = [[YXLHTTPClient alloc] init];
        _loginResultStorage = YXLStorageFactory.loginResultStorage;
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
    return self.activated && [userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && [self processURL:userActivity.webpageURL];
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

- (void)authorizeWithParentViewController:(UIViewController *)parentViewController
{
    NSParameterAssert(parentViewController);
    if (NO == self.activated) {
        [self notifyAuthorizationDidFinishWithErrorCode:YXLErrorCodeNotActivated];
        return;
    }
    if (self.displayingAuthorizationController) {
        [self notifyAuthorizationDidFinishWithErrorCode:YXLErrorCodeIsAuthorizing];
        return;
    }
    if (self.loginResult != nil) {
        [self notifyAuthorizationDidFinishWithResult:self.loginResult];
        return;
    }
    NSString *state = self.statesManager.generateNewState;
    dispatch_block_t openAuthorizationURLBlock = ^{
        NSURL *url = [YXLURLParser authorizationURLWithAppId:self.appId state:state];
        if (self.universalLinksAvailable) {
            [self authorizeWithOpenURL:url completionHandler:nil];
        }
        else {
            [self displayWebViewControllerWithURL:url state:state parentViewController:parentViewController];
        }
    };

    NSURL *openURL = [YXLURLParser openURLWithAppId:self.appId state:state];
    if (self.universalLinksAvailable && [UIApplication.sharedApplication canOpenURL:openURL]) {
        [self authorizeWithOpenURL:openURL completionHandler:^(BOOL success) {
            if (NO == success) {
                openAuthorizationURLBlock();
            }
        }];
    }
    else {
        openAuthorizationURLBlock();
    }
}

- (void)authorizeWithOpenURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completion
{
    UIApplication *application = UIApplication.sharedApplication;
    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
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

- (void)displayWebViewControllerWithURL:(NSURL *)url
                                  state:(NSString *)state
                   parentViewController:(UIViewController *)parentViewController
{
#ifdef YXL_USE_WEBVIEW
    UIViewController *controller = [[YXLLoginWebViewController alloc] initWithURL:url state:state delegate:self];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.navigationBar.translucent = NO;

    self.presentedViewController = controller;
    [parentViewController presentViewController:navigationController animated:YES completion:NULL];
#endif
}

- (BOOL)isActivated
{
    return self.appId != nil;
}

- (BOOL)isDisplayingAuthorizationController
{
    return self.presentedViewController != nil;
}

- (void)logout
{
    self.loginResult = nil;
    self.loginResultStorage.storedObject = nil;
}

- (void)dismissViewController:(UIViewController *)viewController
{
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    if (viewController == self.presentedViewController) {
        self.presentedViewController = nil;
    }
}

- (void)notifyAuthorizationDidFinishWithErrorCode:(YXLErrorCode)code
{
    [self.observersController notifyLoginDidFinishWithError:[NSError errorWithDomain:kYXLErrorDomain code:code userInfo:nil]];
}

- (void)notifyAuthorizationDidFinishWithResult:(id<YXLLoginResult>)result
{
    [self.observersController notifyLoginDidFinishWithResult:result];
}

- (BOOL)processURL:(NSURL *)URL
{
    BOOL result = NO;
    NSString *token = [YXLURLParser tokenFromURL:URL];
    NSString *state = [YXLURLParser stateFromURL:URL];
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
            error = [NSError errorWithDomain:kYXLErrorDomain code:YXLErrorCodeInvalidState userInfo:nil];
        }
        else {
            error = [YXLURLParser errorFromURL:URL];
        }
        if (error != nil) {
            [self dismissViewController:self.presentedViewController];
            [self.observersController notifyLoginDidFinishWithError:error];
            result = YES;
        }
    }
    return result;
}

- (void)requestJWTByToken:(NSString *)token
{
    NSParameterAssert(token);
    UIViewController *controller = self.presentedViewController;
    YXLSpinnerController *spinnerController = (controller != nil) ? [[YXLSpinnerController alloc] init] : nil;
    [spinnerController showInViewController:controller];
    id<YXLRequestParams> requestParams = [[YXLJwtRequestParams alloc] initWithToken:token];
    WEAKIFY_SELF;
    [self.httpClient executeRequestWithParameters:requestParams success:^(NSString *jwt) {
        STRONGIFY_SELF;
        YXLLoginResultModel *result = [[YXLLoginResultModel alloc] initWithToken:token jwt:jwt];
        self.loginResult = result;
        self.loginResultStorage.storedObject = result.dictionaryRepresentation;
        [spinnerController hide];
        [self dismissViewController:controller];
        [self notifyAuthorizationDidFinishWithResult:result];
    } failure:^(NSError *error) {
        STRONGIFY_SELF;
        [spinnerController hide];
        [self dismissViewController:controller];
        [self.observersController notifyLoginDidFinishWithError:error];
    }];
}

#ifdef YXL_USE_WEBVIEW

#pragma mark - YXLLoginWebViewControllerDelegate

- (BOOL)loginWebViewController:(YXLLoginWebViewController *)controller shouldStartLoadURL:(NSURL *)URL
{
    BOOL result = YES;
    if (controller == self.presentedViewController) {
        result = (NO == [self processURL:URL]);
    }
    return result;
}

- (void)loginWebViewControllerDidClose:(YXLLoginWebViewController *)controller
{
    [self.statesManager deleteState:controller.state];
    [self dismissViewController:controller];
    [self notifyAuthorizationDidFinishWithErrorCode:YXLErrorCodeCancelled];
}

#endif

@end
