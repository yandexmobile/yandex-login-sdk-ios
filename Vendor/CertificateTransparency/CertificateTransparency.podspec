Pod::Spec.new do |s|
  s.name                   = 'CertificateTransparency'
  s.version                = '0.0.19'
  s.summary                = 'Certificate Transparency support for custom root CA in SecTrust evaluation'
  s.homepage               = "https://github.com/yandex/domestic-roots-mobile/tree/main/ios"
  s.author                 = { "Sergey Kuznetsov" => "kuznetsovs@yandex-team.ru" }
  s.source                 = { :git => 'https://github.com/yandex/domestic-roots-mobile', :branch => 'main' }
  s.license                = 'MIT'
  s.swift_version          = '5'
  s.requires_arc           = true
  s.ios.deployment_target  = '11.0'
  s.prefix_header_file     = false
  s.frameworks             = 'Security'
  s.libraries              = 'c++'
  s.default_subspec        = 'Static'

  common_compiler_flags = [
    '-fmerge-all-constants',
    '-fno-aligned-new',
    '-fno-exceptions',
    '-fno-omit-frame-pointer',
    '-fno-rtti',
    '-fno-strict-aliasing',
    '-fobjc-arc',
    '-fobjc-call-cxx-cdtors',
    '-fstack-protector',
    '-ftrivial-auto-var-init=pattern',
    '-fvisibility-inlines-hidden',
    '-fvisibility=hidden',
    '-std=c++20',
    '-Wno-documentation-deprecated-sync',
    '-Wno-shorten-64-to-32',
  ]
  common_public_header_files = [
    'CertificateTransparency.h',
  ]
  common_source_files = [
    'CertificateTransparency.h',
    'CertificateTransparency.mm',
    'auto_update_log_verifier.h',
    'auto_update_log_verifier.mm',
    'builtin_logs.cc',
    'builtin_logs-inc.h',
    'builtin_logs.h',
    'builtin_root_certs.h',
    'builtin_root_certs.mm',
    'crypto_bytebuilder.cc',
    'crypto_bytebuilder.h',
    'crypto_bytestring.cc',
    'crypto_bytestring.h',
    'ct_log_downloader.h',
    'ct_log_downloader.mm',
    'ct_objects_extractor.cc',
    'ct_objects_extractor.h',
    'ct_serialization.cc',
    'ct_serialization.h',
    'ct_version.h',
    'ec_public_key.h',
    'ec_public_key.mm',
    'internal_types.h',
    'log_verifier.cc',
    'log_verifier.h',
    'multi_log_verifier.cc',
    'multi_log_verifier.h',
    'public_key.h',
    'public_key.mm',
    'rsa_public_key.h',
    'rsa_public_key.mm',
    'safe_cstring.h',
  ]
  s.subspec 'Static' do |s|
    s.pod_target_xcconfig = {
      'OTHER_CFLAGS[config=Release]' => '-DNDEBUG',
      'DEFINES_MODULE' => 'YES'
    }
    s.compiler_flags = common_compiler_flags
    s.public_header_files = common_public_header_files
    s.source_files = common_source_files
  end

  s.subspec 'Dynamic' do |s|
    s.pod_target_xcconfig = {
      'OTHER_CFLAGS[config=Release]' => '-DNDEBUG -DCERTIFICATE_TRANSPARENCY_DYNAMIC_FRAMEWORK',
      'OTHER_CFLAGS' => '-DCERTIFICATE_TRANSPARENCY_DYNAMIC_FRAMEWORK',
      'DEFINES_MODULE' => 'YES'
    }
    s.compiler_flags = common_compiler_flags
    s.public_header_files = common_public_header_files
    s.source_files = common_source_files
  end
end
