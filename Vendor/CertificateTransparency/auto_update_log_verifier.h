#pragma once

#import <Foundation/Foundation.h>

#include <memory>
#include <mutex>
#include <string_view>

#include "ct_log_downloader.h"
#include "multi_log_verifier.h"

namespace certificate_transparency {

class AutoUpdateLogVerifier
    : public std::enable_shared_from_this<AutoUpdateLogVerifier> {
 public:
  AutoUpdateLogVerifier(
      NSUserDefaults* user_defaults,
      NSString* pref_key,
      NSURL* update_url);
  ~AutoUpdateLogVerifier();

  static std::shared_ptr<AutoUpdateLogVerifier>
  Create(NSUserDefaults* user_defaults, NSString* pref_key, NSURL* update_url);

  bool Verify(
      std::string_view leaf_cert,
      std::string_view issuer_cert,
      uint64_t now);

 private:
  NSDictionary* GetPrefs();
  void SetPrefs(NSDictionary* dict);

  void ScheduleDownload();
  void StartDownload();
  void OnDownloadFinished(CTLogDownloader::DownloadResult result);

  NSUserDefaults* user_defaults_;
  NSString* pref_key_;

  std::mutex lock_ {};
  CTLogDownloader downloader_;
  std::shared_ptr<MultiLogVerifier> verifier_;
};

}  // namespace certificate_transparency
