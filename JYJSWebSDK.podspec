#
# Be sure to run `pod lib lint JYJSWebSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html

#pod trunk push JYJSWebSDK.podspec
## pod spec lint JYJSWebSDK.podspec --verbose --use-libraries --allow-warnings
Pod::Spec.new do |s|
  s.name             = 'JYJSWebSDK'
  s.version          = '1.0.8'
  s.summary          = 'A short description of JYJSWebSDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/ljy0jy/JYJSWebSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ljy0jy' => 'ljygithub@protonmail.com' }
  s.source           = { :git => 'https://github.com/ljy0jy/JYJSWebSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.static_framework = true
  s.source_files = 'JYJSWebSDK/Classes/**/*'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  # s.resource_bundles = {
  #   'JYJSWebSDK' => ['JYJSWebSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'SVProgressHUD'
   s.dependency 'SKJavaScriptBridge', '~> 1.0.3'
   s.dependency 'lottie-ios', '~>  2.5.3'
   s.dependency 'AppsFlyerFramework'
end
