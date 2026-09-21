#include "ct_log_downloader.h"

#include <optional>

#include "ct_version.h"

namespace certificate_transparency {
namespace {

NSString* GetUserAgent() {
  NSString* version =
      [NSString stringWithUTF8String:CERTIFICATE_TRANSPARENCY_VERSION];
  return [@"CertificateTransparencyPublic/" stringByAppendingString:version];
}

NSString* ToNSString(const std::string& str) {
  return [[NSString alloc] initWithUTF8String:str.c_str()];
}

std::optional<std::vector<std::string>> Parse(NSData* data) {
  if (!data) {
    return {};
  }

  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  if (!json || ![json isKindOfClass:[NSDictionary class]]) {
    return {};
  }

  id operators = ((NSDictionary*)json)[@"operators"];
  if (!operators || ![operators isKindOfClass:[NSArray class]]) {
    return {};
  }

  std::vector<std::string> result;
  for (id op in (NSArray*)operators) {
    if (![op isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    id logs = ((NSDictionary*)op)[@"logs"];
    if (!logs || ![logs isKindOfClass:[NSArray class]]) {
      continue;
    }

    for (id log in (NSArray*)logs) {
      if (![log isKindOfClass:[NSDictionary class]]) {
        continue;
      }

      id key = ((NSDictionary*)log)[@"key"];
      if (!key || ![key isKindOfClass:[NSString class]]) {
        continue;
      }

      NSData* key_data =
          [[NSData alloc] initWithBase64EncodedString:(NSString*)key options:0];
      if (!key_data) {
        continue;
      }

      result.emplace_back(
          reinterpret_cast<const char*>([key_data bytes]), [key_data length]);
    }
  }

  return result;
}

}  // namespace

CTLogDownloader::Ok::Ok() = default;
CTLogDownloader::Ok::Ok(const Ok& other) = default;
CTLogDownloader::Ok::~Ok() = default;

CTLogDownloader::CTLogDownloader(NSURL* update_url)
    : update_url_(update_url),
      user_agent_(GetUserAgent()),
      url_session_([NSURLSession
          sessionWithConfiguration:
              [NSURLSessionConfiguration ephemeralSessionConfiguration]
                          delegate:nil
                     delegateQueue:nil]) {}

CTLogDownloader::~CTLogDownloader() = default;

void CTLogDownloader::Download(
    const std::optional<std::string>& tag,
    DownloadCallback callback) {
  NSMutableURLRequest* request =
      [[NSMutableURLRequest alloc] initWithURL:update_url_];
  [request setValue:user_agent_ forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
  if (tag) {
    [request setValue:ToNSString(*tag) forHTTPHeaderField:@"If-None-Match"];
  }

  __block NSURLSessionDataTask* current_task = nil;
  auto* task = [url_session_
      dataTaskWithRequest:request
        completionHandler:^(
            NSData* data, NSURLResponse* response, NSError* error) {
          current_task = nil;

          if (!response) {
            callback(ErrorCode(-1));
            return;
          }

          NSHTTPURLResponse* http_response = (NSHTTPURLResponse*)response;
          if (http_response.statusCode == 304) {
            callback(NotModified());
            return;
          }
          if (http_response.statusCode != 200) {
            callback(ErrorCode(http_response.statusCode));
            return;
          }

          auto logs = Parse(data);
          if (!logs) {
            callback(ErrorCode(-2));
            return;
          }

          Ok result;
          result.logs = std::move(*logs);

          NSDictionary* headers = [http_response allHeaderFields];
          NSString* response_tag = headers[@"ETag"];
          if (response_tag) {
            result.tag = [response_tag UTF8String];
          }

          callback(std::move(result));
        }];
  current_task = task;
  [task resume];
}

}  // namespace certificate_transparency
