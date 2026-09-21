#include "auto_update_log_verifier.h"

#include <chrono>
#include <optional>
#include <string>
#include <variant>
#include <vector>

#include "builtin_logs.h"

namespace certificate_transparency {
namespace {

constexpr std::chrono::duration<double> kInitialDelay = std::chrono::seconds(2);
constexpr std::chrono::seconds kSucceedUpdateInterval = std::chrono::days(30);
constexpr std::chrono::seconds kFailedUpdateInterval = std::chrono::hours(1);

NSString* const kNextUpdate = @"next_update";
NSString* const kTag = @"tag";
NSString* const kLogs = @"logs";

NSDate* GetNextUpdate(NSDictionary* dict) {
  id date = dict[kNextUpdate];
  if (date && [date isKindOfClass:[NSDate class]]) {
    return (NSDate*)date;
  } else {
    return nil;
  }
}

std::optional<std::string> GetTag(NSDictionary* dict) {
  id tag = dict[kTag];
  if (tag && [tag isKindOfClass:[NSData class]]) {
    NSData* tag_data = (NSData*)tag;
    return std::string(
        reinterpret_cast<const char*>([tag_data bytes]), [tag_data length]);
  } else {
    return {};
  }
}

std::vector<std::string> GetLogs(NSDictionary* dict) {
  id logs = dict[kLogs];
  if (logs && [logs isKindOfClass:[NSArray class]]) {
    std::vector<std::string> result;
    for (id log in (NSArray*)logs) {
      if (![log isKindOfClass:[NSData class]]) {
        continue;
      }

      NSData* log_bytes = (NSData*)log;
      result.emplace_back(
          reinterpret_cast<const char*>([log_bytes bytes]), [log_bytes length]);
    }
    return result;
  } else {
    return GetBuiltinLogs();
  }
}

NSTimeInterval CalculateDelay(NSDate* next_update) {
  if (!next_update) {
    return kInitialDelay.count();
  }

  NSTimeInterval interval = [next_update timeIntervalSinceDate:[NSDate date]];
  return std::max(interval, kInitialDelay.count());
}

}  // namespace

AutoUpdateLogVerifier::AutoUpdateLogVerifier(
    NSUserDefaults* user_defaults,
    NSString* pref_key,
    NSURL* update_url)
    : user_defaults_(user_defaults),
      pref_key_(pref_key),
      downloader_(update_url) {}

AutoUpdateLogVerifier::~AutoUpdateLogVerifier() = default;

// static
std::shared_ptr<AutoUpdateLogVerifier> AutoUpdateLogVerifier::Create(
    NSUserDefaults* user_defaults,
    NSString* pref_key,
    NSURL* update_url) {
  auto result = std::make_shared<AutoUpdateLogVerifier>(
      user_defaults, pref_key, update_url);
  result->ScheduleDownload();
  return result;
}

bool AutoUpdateLogVerifier::Verify(
    std::string_view leaf_cert,
    std::string_view issuer_cert,
    uint64_t now) {
  auto verifier = [this] {
    std::lock_guard guard(lock_);
    if (!verifier_) {
      verifier_ = std::make_shared<MultiLogVerifier>(GetLogs(GetPrefs()));
    }
    return verifier_;
  }();
  return verifier->Verify(leaf_cert, issuer_cert, now);
}

void AutoUpdateLogVerifier::ScheduleDownload() {
  auto delay = static_cast<int64_t>(
      CalculateDelay(GetNextUpdate(GetPrefs())) * NSEC_PER_SEC);
  std::weak_ptr weak_this = weak_from_this();
  dispatch_after(
      dispatch_walltime(nullptr, delay), dispatch_get_main_queue(), ^{
        if (auto thiz = weak_this.lock()) {
          thiz->StartDownload();
        }
      });
}

NSDictionary* AutoUpdateLogVerifier::GetPrefs() {
  NSDictionary* dict = [user_defaults_ dictionaryForKey:pref_key_];
  return dict ? dict : @ {};
}

void AutoUpdateLogVerifier::SetPrefs(NSDictionary* dict) {
  [user_defaults_ setObject:dict forKey:pref_key_];
}

void AutoUpdateLogVerifier::StartDownload() {
  std::weak_ptr weak_this = weak_from_this();
  downloader_.Download(
      GetTag(GetPrefs()), [weak_this](CTLogDownloader::DownloadResult result) {
        if (auto thiz = weak_this.lock()) {
          thiz->OnDownloadFinished(std::move(result));
        }
      });
}

void AutoUpdateLogVerifier::OnDownloadFinished(
    CTLogDownloader::DownloadResult result) {
  struct ResultVisitor {
    bool operator()(CTLogDownloader::ErrorCode code) const {
      prefs[kNextUpdate] =
          [NSDate dateWithTimeIntervalSinceNow:kFailedUpdateInterval.count()];
      return false;
    }
    bool operator()(CTLogDownloader::NotModified) const {
      prefs[kNextUpdate] =
          [NSDate dateWithTimeIntervalSinceNow:kSucceedUpdateInterval.count()];
      return false;
    }
    bool operator()(CTLogDownloader::Ok& ok) const {
      prefs[kNextUpdate] =
          [NSDate dateWithTimeIntervalSinceNow:kSucceedUpdateInterval.count()];

      if (ok.tag) {
        prefs[kTag] = [NSData
            dataWithBytes:reinterpret_cast<const uint8_t*>(ok.tag->data())
                   length:ok.tag->size()];
      } else {
        [prefs removeObjectForKey:kTag];
      }

      NSMutableArray* logs =
          [[NSMutableArray alloc] initWithCapacity:ok.logs.size()];
      for (const auto& log : ok.logs) {
        [logs addObject:[NSData dataWithBytes:reinterpret_cast<const uint8_t*>(
                                                  log.data())
                                       length:log.size()]];
      }
      prefs[kLogs] = [logs copy];
      return true;
    }

    NSMutableDictionary* prefs;
  };

  NSMutableDictionary* prefs = [GetPrefs() mutableCopy];
  bool invalidate_verifier = std::visit(ResultVisitor {prefs}, result);

  SetPrefs([prefs copy]);
  ScheduleDownload();

  if (invalidate_verifier) {
    std::lock_guard guard(lock_);
    verifier_.reset();
  }
}

}  // namespace certificate_transparency
