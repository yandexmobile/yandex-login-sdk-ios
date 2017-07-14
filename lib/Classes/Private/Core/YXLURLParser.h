#import <Foundation/Foundation.h>

@interface YXLURLParser : NSObject

@property (class, copy, readonly) NSString *openURLScheme;

+ (NSURL *)authorizationURLWithAppId:(NSString *)appId state:(NSString *)state;
+ (NSURL *)openURLWithAppId:(NSString *)appId state:(NSString *)state;

+ (NSError *)errorFromURL:(NSURL *)url;
+ (NSString *)tokenFromURL:(NSURL *)url;
+ (NSString *)stateFromURL:(NSURL *)url;

@end
