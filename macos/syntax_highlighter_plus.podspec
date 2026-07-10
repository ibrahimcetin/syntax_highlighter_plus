#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint syntax_highlighter_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'syntax_highlighter_plus'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*',
    '../src/oniguruma-6.9.10/src/regerror.c',
    '../src/oniguruma-6.9.10/src/regparse.c',
    '../src/oniguruma-6.9.10/src/regext.c',
    '../src/oniguruma-6.9.10/src/regcomp.c',
    '../src/oniguruma-6.9.10/src/regexec.c',
    '../src/oniguruma-6.9.10/src/reggnu.c',
    '../src/oniguruma-6.9.10/src/regenc.c',
    '../src/oniguruma-6.9.10/src/regsyntax.c',
    '../src/oniguruma-6.9.10/src/regtrav.c',
    '../src/oniguruma-6.9.10/src/regversion.c',
    '../src/oniguruma-6.9.10/src/st.c',
    '../src/oniguruma-6.9.10/src/onig_init.c',
    '../src/oniguruma-6.9.10/src/unicode.c',
    '../src/oniguruma-6.9.10/src/ascii.c',
    '../src/oniguruma-6.9.10/src/utf8.c',
    '../src/oniguruma-6.9.10/src/utf16_be.c',
    '../src/oniguruma-6.9.10/src/utf16_le.c',
    '../src/oniguruma-6.9.10/src/utf32_be.c',
    '../src/oniguruma-6.9.10/src/utf32_le.c',
    '../src/oniguruma-6.9.10/src/euc_jp.c',
    '../src/oniguruma-6.9.10/src/sjis.c',
    '../src/oniguruma-6.9.10/src/iso8859_1.c',
    '../src/oniguruma-6.9.10/src/iso8859_2.c',
    '../src/oniguruma-6.9.10/src/iso8859_3.c',
    '../src/oniguruma-6.9.10/src/iso8859_4.c',
    '../src/oniguruma-6.9.10/src/iso8859_5.c',
    '../src/oniguruma-6.9.10/src/iso8859_6.c',
    '../src/oniguruma-6.9.10/src/iso8859_7.c',
    '../src/oniguruma-6.9.10/src/iso8859_8.c',
    '../src/oniguruma-6.9.10/src/iso8859_9.c',
    '../src/oniguruma-6.9.10/src/iso8859_10.c',
    '../src/oniguruma-6.9.10/src/iso8859_11.c',
    '../src/oniguruma-6.9.10/src/iso8859_13.c',
    '../src/oniguruma-6.9.10/src/iso8859_14.c',
    '../src/oniguruma-6.9.10/src/iso8859_15.c',
    '../src/oniguruma-6.9.10/src/iso8859_16.c',
    '../src/oniguruma-6.9.10/src/euc_tw.c',
    '../src/oniguruma-6.9.10/src/euc_kr.c',
    '../src/oniguruma-6.9.10/src/big5.c',
    '../src/oniguruma-6.9.10/src/gb18030.c',
    '../src/oniguruma-6.9.10/src/koi8_r.c',
    '../src/oniguruma-6.9.10/src/cp1251.c',
    '../src/oniguruma-6.9.10/src/euc_jp_prop.c',
    '../src/oniguruma-6.9.10/src/sjis_prop.c',
    '../src/oniguruma-6.9.10/src/unicode_unfold_key.c',
    '../src/oniguruma-6.9.10/src/unicode_fold1_key.c',
    '../src/oniguruma-6.9.10/src/unicode_fold2_key.c',
    '../src/oniguruma-6.9.10/src/unicode_fold3_key.c',
    '../src/oniguruma-6.9.10/src/*.h',
    '../src/oniguruma-6.9.10/config.h'
  s.compiler_flags = '-DHAVE_CONFIG_H -I"${PODS_TARGET_SRCROOT}/../src/oniguruma-6.9.10" -I"${PODS_TARGET_SRCROOT}/../src/oniguruma-6.9.10/src"'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'syntax_highlighter_plus_privacy' => ['syntax_highlighter_plus/Sources/syntax_highlighter_plus/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'STRIP_STYLE' => 'non-global',
    'DEAD_CODE_STRIPPING' => 'NO'
  }
  s.swift_version = '5.0'
end
