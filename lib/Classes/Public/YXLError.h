#import <Foundation/Foundation.h>

/** Possible codes for error with domain kYXLErrorDomain.
 - .notActivated: YXLSdk is not activated.
 - .isAuthorizing: Authorization started when previous authorization controller is displayed.
 - .cancelled: Authorization controller closed by user.
 - .denied: User denied access in permissions page.
 - .invalidClient: AppId authentication failed.
 - .invalidScope: The requested scope is invalid, unknown, or malformed.
 - .other: Other error (error string is in NSLocalizedFailureReasonErrorKey of error user info).
 - .requestError: internal HTTP request error.
 - .requestConnectionError: HTTP internet connection error.
 - .requestSSLError: HTTP SSL error.
 - .requestNetworkError: other HTTP error.
 - .requestResponseError: bad response for HTTP request (not NSHTTPURLResponse or status code not in 200..299).
 - .requestEmptyDataError: empty data returns on some HTTP request.
 - .requestJwtError: bad answer for jwt request.
 - .requestJwtInternalError: jwt request internal error.
 - .invalidState: Invalid state parameter.
 */
typedef NS_ENUM(NSInteger, YXLErrorCode) {
    YXLErrorCodeNotActivated,
    YXLErrorCodeIsAuthorizing,
    YXLErrorCodeCancelled,
    YXLErrorCodeDenied,
    YXLErrorCodeInvalidClient,
    YXLErrorCodeInvalidScope,
    YXLErrorCodeOther,
    YXLErrorCodeRequestError,
    YXLErrorCodeRequestConnectionError,
    YXLErrorCodeRequestSSLError,
    YXLErrorCodeRequestNetworkError,
    YXLErrorCodeRequestResponseError,
    YXLErrorCodeRequestEmptyDataError,
    YXLErrorCodeRequestJwtError,
    YXLErrorCodeRequestJwtInternalError,
    YXLErrorCodeInvalidState,
};

/** Possible codes for error with domain kYXLActivationErrorDomain.
 - .noAppId: appId is nil
 - .noQuerySchemeInInfoPList: No scheme in LSApplicationQueriesSchemes in Info.plist
 */
typedef NS_ENUM(NSInteger, YXLActivationErrorCode) {
    YXLActivationErrorCodeNoAppId,
    YXLActivationErrorCodeNoQuerySchemeInInfoPList,
};

/** Domain for YXLSdk errors */
extern NSString *const kYXLErrorDomain;
/** Domain for errors returned by [YXLSdk activateWithAppId:] */
extern NSString *const kYXLActivationErrorDomain;
