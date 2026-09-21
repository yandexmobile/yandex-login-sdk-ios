#import "CertificateTransparency.h"

#include <CommonCrypto/CommonDigest.h>
#include <variant>

#include "auto_update_log_verifier.h"
#include "builtin_logs.h"
#include "builtin_root_certs.h"
#include "multi_log_verifier.h"

#define STATIC_STORAGE(Type, storage) \
  alignas(Type) static std::byte storage[sizeof(Type)]

namespace ct = certificate_transparency;

NS_ASSUME_NONNULL_BEGIN

namespace {

NSString* const kPrefsKey = @"CertificateTransparencyPrefsKey";
NSString* const kUpdateURL =
    @"https://browser-resources.s3.yandex.net/ctlog/ctlog.json";

CFDataRef GetCert(SecTrustRef trust, int idx) {
  SecCertificateRef cert = SecTrustGetCertificateAtIndex(trust, idx);
  if (!cert) {
    return {};
  }
  return SecCertificateCopyData(cert);
}

std::string_view ToView(CFDataRef data) {
  if (!data) {
    return {};
  }

  const char* buf = reinterpret_cast<const char*>(CFDataGetBytePtr(data));
  const size_t len = CFDataGetLength(data);
  return std::string_view(buf, len);
}

std::vector<std::string> ToCppLogs(NSArray<NSData*>* logs) {
  std::vector<std::string> cppLogs;
  cppLogs.reserve([logs count]);
  for (NSData* data in logs) {
    const char* buf = reinterpret_cast<const char*>([data bytes]);
    cppLogs.push_back(std::string(buf, buf + [data length]));
  }
  return cppLogs;
}

NSString* GeneratePrefKey(NSURL* url) {
  NSString* url_str = [url absoluteString];

  uint8_t hash[32];
  CC_SHA256([url_str UTF8String], [url_str length], hash);
  NSData* data = [NSData dataWithBytes:hash length:sizeof(hash)];

  return [NSString stringWithFormat:@"%@/%@", kPrefsKey,
                                    [data base64EncodedStringWithOptions:0]];
}

struct DefaultCustomRoots {};

struct CustomRootsVisitor {
  NSArray* operator()(DefaultCustomRoots& tag) const {
    static NSArray* roots = ct::GetBuiltinCerts();
    return roots;
  }
  NSArray* operator()(NSArray* roots) const { return roots; }
};

struct DefaultVerifier {};

struct VerifyVisitor {
  bool operator()(DefaultVerifier& tag) const {
    STATIC_STORAGE(ct::MultiLogVerifier, storage);
    static auto* instance =
        new (storage) ct::MultiLogVerifier(ct::GetBuiltinLogs());

    return instance->Verify(leaf_cert, issuer_cert, now);
  }
  bool operator()(ct::AutoUpdateLogVerifier* verifier) const {
    return verifier->Verify(leaf_cert, issuer_cert, now);
  }
  bool operator()(ct::MultiLogVerifier& verifier) const {
    return verifier.Verify(leaf_cert, issuer_cert, now);
  }
  bool operator()(std::shared_ptr<ct::AutoUpdateLogVerifier>& verifier) const {
    return verifier->Verify(leaf_cert, issuer_cert, now);
  }

  std::string_view leaf_cert;
  std::string_view issuer_cert;
  uint64_t now;
};

}  // namespace

@implementation CertificateTransparencyConfiguration

- (instancetype)init {
  self = [super init];
  if (self) {
    _autoUpdate = YES;
  }
  return self;
}

@end

@interface CertificateTransparency () {
  std::variant<DefaultCustomRoots, NSArray*> custom_roots_;
  std::variant<
      DefaultVerifier,
      ct::AutoUpdateLogVerifier*,
      ct::MultiLogVerifier,
      std::shared_ptr<ct::AutoUpdateLogVerifier>>
      verifier_;
}

@end

@implementation CertificateTransparency

- (instancetype)init {
  return
      [self initWithConfiguration:[[CertificateTransparencyConfiguration alloc]
                                      init]];
}

- (instancetype)initWithConfiguration:
    (CertificateTransparencyConfiguration*)configuration {
  self = [super init];
  if (self) {
    if (configuration.customRoots) {
      custom_roots_ = configuration.customRoots;
    } else {
      custom_roots_ = DefaultCustomRoots();
    }

    if (configuration.logs) {
      NSArray<NSData*>* logs = configuration.logs;
      verifier_.emplace<ct::MultiLogVerifier>(ToCppLogs(logs));
    } else {
      if (configuration.autoUpdate) {
        if (configuration.updateURL) {
          NSURL* updateURL = configuration.updateURL;
          verifier_ = ct::AutoUpdateLogVerifier::Create(
              NSUserDefaults.standardUserDefaults, GeneratePrefKey(updateURL),
              updateURL);
        } else {
          STATIC_STORAGE(std::shared_ptr<ct::AutoUpdateLogVerifier>, storage);
          static auto* verifier =
              new (storage) std::shared_ptr(ct::AutoUpdateLogVerifier::Create(
                  NSUserDefaults.standardUserDefaults, kPrefsKey,
                  [NSURL URLWithString:kUpdateURL]));

          verifier_ = verifier->get();
        }
      } else {
        verifier_ = DefaultVerifier();
      }
    }
  }
  return self;
}

- (void)
    handleChallengeWithProtectionSpace:(NSURLProtectionSpace*)protectionSpace
                     completionHandler:
                         (CertificateTransparencyCompletion)completionHandler {
  if (protectionSpace.authenticationMethod !=
      NSURLAuthenticationMethodServerTrust) {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    return;
  }

  if (![NSThread isMainThread]) {
    [self verify:protectionSpace completionHandler:completionHandler];
    return;
  }

  __auto_type work_queue =
      dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
  __auto_type completion =
      ^(NSURLSessionAuthChallengeDisposition disposition,
        NSURLCredential* _Nullable credential) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completionHandler(disposition, credential);
        });
      };

  dispatch_async(work_queue, ^{
    [self verify:protectionSpace completionHandler:completion];
  });
}

- (void)verify:(NSURLProtectionSpace*)protectionSpace
    completionHandler:(CertificateTransparencyCompletion)completionHandler {
  SecTrustRef trust = protectionSpace.serverTrust;
  auto result = [self verifyTrust:trust];
  if (result.trusted) {
    completionHandler(
        NSURLSessionAuthChallengeUseCredential,
        [NSURLCredential credentialForTrust:trust]);
  } else {
    completionHandler(
        NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
  }
}

- (CertificateTransparencyVerifyResult)verifyTrust:(SecTrustRef)trust {
  if (!trust) {
    return {.trusted = false, .hasCustomRoot = false};
  }

  NSArray* custom_roots = std::visit(CustomRootsVisitor(), custom_roots_);

  if (SecTrustSetAnchorCertificates(trust, (CFArrayRef)custom_roots) !=
          errSecSuccess ||
      SecTrustSetAnchorCertificatesOnly(trust, NO) != errSecSuccess) {
    return {.trusted = false, .hasCustomRoot = false};
  }

  bool trusted = false;
  if (@available(iOS 12, tvOS 12, macOS 10.14, *)) {
    trusted = SecTrustEvaluateWithError(trust, NULL);
  } else {
    SecTrustResultType trust_result = kSecTrustResultDeny;
    trusted = SecTrustEvaluate(trust, &trust_result) == errSecSuccess &&
              (trust_result == kSecTrustResultUnspecified ||
               trust_result == kSecTrustResultProceed) &&
              SecTrustGetCertificateCount(trust) > 0;
  }

  const CFIndex chain_length = SecTrustGetCertificateCount(trust);
  if (chain_length == 0) {
    return {.trusted = false, .hasCustomRoot = false};
  }

  bool has_custom_root = false;
  id root = (id)SecTrustGetCertificateAtIndex(trust, chain_length - 1);
  for (id custom_root in custom_roots) {
    if ([custom_root isEqual:root]) {
      has_custom_root = true;
      break;
    }
  }
  if (!trusted || !has_custom_root) {
    return {.trusted = trusted, .hasCustomRoot = has_custom_root};
  }
  assert(has_custom_root);
  if (chain_length < 2) {
    return {.trusted = false, .hasCustomRoot = true};
  }

  CFDataRef leaf = GetCert(trust, 0);
  CFDataRef issuer = GetCert(trust, 1);
  uint64_t now = [[NSDate date] timeIntervalSince1970] * 1000;
  trusted =
      std::visit(VerifyVisitor {ToView(leaf), ToView(issuer), now}, verifier_);
  if (issuer) {
    CFRelease(issuer);
  }
  if (leaf) {
    CFRelease(leaf);
  }
  return {.trusted = trusted, .hasCustomRoot = true};
}

@end

NS_ASSUME_NONNULL_END
