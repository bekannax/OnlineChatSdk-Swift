Pod::Spec.new do |s|
  s.name             = 'OnlineChatSdk'
  s.version          = '0.3.5'
  s.summary          = 'A small library containing a wrapper for the WKWebView.'
  s.swift_versions   = '5.0'
  s.homepage         = 'https://github.com/bekannax/OnlineChatSdk-Swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'bekannax' => 'bekannax@gmail.com' }
  s.source           = { :git => 'https://github.com/bekannax/OnlineChatSdk-Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/OnlineChatSdk/**/*'
  s.resource_bundles = {
    'OnlineChatSdk' => ['Sources/OnlineChatSdk/**/*']
  }
end
