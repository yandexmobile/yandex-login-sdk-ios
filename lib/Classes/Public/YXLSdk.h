#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YXLObserver;

@interface YXLSdk : NSObject

/** Shared instance of YXLSdk. */
@property (class, strong, readonly) YXLSdk *shared;

/** Retrieve the current iOS SDK version. */
@property (class, copy, readonly) NSString *sdkVersion;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/** Activates SDK. YXLSdk can be used only after activation.

 @discussion Typically YXLSdk should be activated in applicationDidFinishLaunching method of App delegate.
 
 @param error If an error occurs, contains an NSError with kYXLActivationErrorDomain domain and
 YXLActivationErrorCode code object that describes the problem.
 
 @return YES if activation was successful, error is nil in this case
 */
- (BOOL)activateWithAppId:(NSString *)appId error:(NSError *__autoreleasing *)error;

/**
 Checks passed user activity for access token.

 @param userActivity user activity from external application
 @return YES If parsed successfully
 
 @discussion Should be called from [UIApplication application:continueUserActivity:restorationHandler:]
 @code
     @available(iOS 8.0, *)
     func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
         YXLSdk.shared.processUserActivity(userActivity)
         return true
     }
 */
- (BOOL)processUserActivity:(NSUserActivity *)userActivity NS_AVAILABLE_IOS(8_0);

/** Checks passed url for authentication code.

 @param url The URL as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].
 @param sourceApplication The sourceApplication as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].
 @return YES if the url was intended for the YandexLoginSDK, NO if not.

 @discussion Should be called from [UIApplicationDelegate application:openURL:sourceApplication:annotation:] method
 of the AppDelegate for your app. It should be invoked for the proper processing of responses during interaction
 with the browser or SafariViewController.
 @code
      func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
           return YXLSdk.shared.handleOpen(url, sourceApplication: sourceApplication)
      }

      @available(iOS 9.0, *)
      func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
           return YXLSdk.shared.handleOpen(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String)
      }
 */
- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication;

/** Adds an observer.

 @param observer Observer to be notified with YXLObserver specific events.
 @warning YXLSdk doesn't keep strong reference to observers.
 */
- (void)addObserver:(id<YXLObserver>)observer NS_SWIFT_NAME(add(observer:));

/** Removes an observer.

 @param observer Observer which adopts YXLObserver protocol, previosuly added with addObserver: method.
 @warning YXLSdk doesn't keep strong reference to observers.
 */
- (void)removeObserver:(id<YXLObserver>)observer NS_SWIFT_NAME(remove(observer:));

/**
 Starts authorization process to retrieve token. Opens Yandex application or browser for access request.

 @discussion Notifies observers if authorization is finished with success or error.
 If YXLSdk is not activated, notifies observers with error YXLErrorCodeNotActivated.
 Caches success authorization result and uses it in the next calls.
 */
- (void)authorize;

/** Clears all saved data. */
- (void)logout;

@end

NS_ASSUME_NONNULL_END
