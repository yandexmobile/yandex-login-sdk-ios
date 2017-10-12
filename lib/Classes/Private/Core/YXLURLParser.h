#import <Foundation/Foundation.h>

@interface YXLURLParser : NSObject

@property (class, copy, readonly) NSString *openURLScheme;
@property (class, copy, readonly) NSString *openURLSchemeUniversalLink;

+ (NSString *)redirectURLSchemeWithAppId:(NSString *)appId;

+ (NSURL *)authorizationURLWithAppId:(NSString *)appId state:(NSString *)state pkce:(NSString *)pkce;
+ (NSURL *)openURLWithAppId:(NSString *)appId state:(NSString *)state pkce:(NSString *)pkce;
+ (NSURL *)openURLUniversalLinkWithAppId:(NSString *)appId state:(NSString *)state;

+ (NSError *)errorFromURL:(NSURL *)url;
+ (NSString *)codeFromURL:(NSURL *)url;
+ (NSString *)stateFromURL:(NSURL *)url;

+ (NSError *)errorFromUniversalLinkURL:(NSURL *)url;
+ (NSString *)tokenFromUniversalLinkURL:(NSURL *)url;
+ (NSString *)stateFromUniversalLinkURL:(NSURL *)url;

@end
