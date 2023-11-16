
Pod::Spec.new do |spec|
  spec.name           = "YandexLoginSDK"
  spec.version        = "3.0.1"
  spec.summary        = "A library that helps third-party applications authorize in Yandex Services."
  spec.homepage       = "https://yandex.ru/dev/id/doc/"
  spec.license        = { type: 'Proprietary', text: '2023 © Yandex. All rights reserved.' }
  spec.author         = { "Yandex LLC" => "ios-dev@yandex-team.ru" }
  spec.platform       = :ios, "12.0"
  spec.swift_version  = "5.0"
  spec.source         = { :git => "https://github.com/yandexmobile/yandex-login-sdk-ios.git", :tag => "#{spec.version}" }
  spec.source_files   = "Sources/**/*"
  spec.frameworks     = "UIKit", "Security", "CryptoKit"
  spec.compiler_flags = "-Werror",
                        "-Wall",
                        "-Wsign-compare",
                        "-Wdocumentation-unknown-command",
                        "-Wdocumentation",
                        "-Wnewline-eof",
                        "-Woverriding-method-mismatch",
                        "-Wsuper-class-method-mismatch"
end
