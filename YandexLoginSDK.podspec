Pod::Spec.new do |s|
  s.name                 = 'YandexLoginSDK'
  s.version              = '2.0.0'
  s.summary              = 'Yandex Login SDK'
  s.homepage             = 'https://tech.yandex.ru/'
  s.license              = { type: 'Proprietary', text: '2017 © Yandex. All rights reserved.' }
  s.authors              = { 'Yandex LLC' => 'ios-dev@yandex-team.ru' }
  s.source               = { git: 'https://github.com/yandexmobile/yandex-login-sdk-ios.git', tag: s.version.to_s }
  s.platform             = :ios, '7.0'
  s.source_files         = 'lib/Classes/**/*.{h,m}'
  s.private_header_files = 'lib/Classes/Private/**/*.h'
  s.frameworks           = 'CoreGraphics', 'Security', 'UIKit'
  s.compiler_flags       = '-Werror', '-Wall', '-Wsign-compare', 
                           '-Wdocumentation-unknown-command', '-Wdocumentation', '-Wnewline-eof',
                           '-Wobjc-interface-ivars', '-Woverriding-method-mismatch', '-Wsuper-class-method-mismatch'
  s.requires_arc         = true
end
