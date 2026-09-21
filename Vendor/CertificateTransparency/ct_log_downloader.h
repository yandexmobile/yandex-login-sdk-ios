#pragma once

#import <Foundation/Foundation.h>

#include <functional>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace certificate_transparency {

class CTLogDownloader {
 public:
  struct Ok {
    Ok();
    Ok(const Ok& other);
    ~Ok();

    std::optional<std::string> tag;
    std::vector<std::string> logs;
  };
  struct NotModified {};
  using ErrorCode = int;

  using DownloadResult = std::variant<Ok, NotModified, ErrorCode>;
  using DownloadCallback = std::function<void(DownloadResult)>;

  explicit CTLogDownloader(NSURL* update_url);
  ~CTLogDownloader();

  void
  Download(const std::optional<std::string>& tag, DownloadCallback callback);

 private:
  NSURL* update_url_;
  NSString* user_agent_;
  NSURLSession* url_session_;
};

}  // namespace certificate_transparency
