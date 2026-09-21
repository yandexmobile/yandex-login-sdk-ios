
Pod::Spec.new do |spec|
  spec.name           = "YandexLoginSDK"
  spec.version        = "3.2.0"
  spec.summary        = "A library that helps third-party applications authorize in Yandex Services."
  spec.homepage       = "https://yandex.ru/dev/id/doc/"
  spec.license        = { type: 'Proprietary', text: '2024 © Yandex. All rights reserved.' }
  spec.author         = { "Yandex LLC" => "ios-dev@yandex-team.ru" }
  spec.platform       = :ios, "12.0"
  spec.swift_version  = "5.0"
  spec.source         = { :git => "https://github.com/yandexmobile/yandex-login-sdk-ios.git", :tag => "#{spec.version}" }
  spec.source_files   = "Sources/**/*", "Vendor/CertificateTransparency/*.{h,mm,cc}"
  spec.public_header_files = "Vendor/CertificateTransparency/CertificateTransparency.h"
  spec.private_header_files = "Vendor/CertificateTransparency/{auto_*,builtin_*,crypto_*,ct_*,ec_*,internal_*,log_*,multi_*,public_*,rsa_*,safe_*}.h"
  spec.exclude_files = "Vendor/CertificateTransparency/include/**/*"
  spec.preserve_paths = "Vendor/CertificateTransparency/LICENSE", "Vendor/CertificateTransparency/UPSTREAM.md"
  spec.libraries = "c++"
  spec.pod_target_xcconfig = {
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++20",
    "CLANG_CXX_LIBRARY" => "libc++"
  }
  spec.frameworks     = "UIKit", "Security", "CryptoKit", "WebKit"
  spec.compiler_flags = "-Werror",
                        "-Wno-shorten-64-to-32",
                        "-Wno-documentation-deprecated-sync",
                        "-Wall",
                        "-Wsign-compare",
                        "-Wdocumentation-unknown-command",
                        "-Wdocumentation",
                        "-Wnewline-eof",
                        "-Woverriding-method-mismatch",
                        "-Wsuper-class-method-mismatch"
end
