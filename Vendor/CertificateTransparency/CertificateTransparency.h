#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(CERTIFICATE_TRANSPARENCY_DYNAMIC_FRAMEWORK)
#define CERTIFICATE_TRANSPARENCY_EXPORT __attribute__((visibility("default")))
#else
#define CERTIFICATE_TRANSPARENCY_EXPORT
#endif

typedef struct CertificateTransparencyVerifyResult {
  bool trusted;
  bool hasCustomRoot;
} CertificateTransparencyVerifyResult;

typedef void (^CertificateTransparencyCompletion)(
    NSURLSessionAuthChallengeDisposition disposition,
    NSURLCredential* _Nullable credential);

CERTIFICATE_TRANSPARENCY_EXPORT
@interface CertificateTransparencyConfiguration : NSObject

@property(nonatomic, assign) BOOL autoUpdate;
@property(nonatomic, copy, nullable) NSURL* updateURL;
@property(nonatomic, copy, nullable) NSArray* customRoots;
@property(nonatomic, copy, nullable) NSArray<NSData*>* logs;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

CERTIFICATE_TRANSPARENCY_EXPORT
@interface CertificateTransparency : NSObject

- (instancetype)init;
- (instancetype)initWithConfiguration:
    (CertificateTransparencyConfiguration*)configuration
    NS_DESIGNATED_INITIALIZER;

- (void)
    handleChallengeWithProtectionSpace:(NSURLProtectionSpace*)protectionSpace
                     completionHandler:
                         (CertificateTransparencyCompletion)completionHandler;
- (CertificateTransparencyVerifyResult)verifyTrust:(SecTrustRef)trust;

@end

NS_ASSUME_NONNULL_END
