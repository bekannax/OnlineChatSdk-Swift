Pod::Spec.new do |spec|
  s.name             = 'OnlineChatSdk'
  s.version          = '0.0.2'
  s.summary          = 'A small library containing a wrapper for the WKWebView.'
  s.swift_versions   = '5.0'
  s.description      = 'A small library containing a wrapper for the WKWebView.'
  s.homepage         = 'https://github.com/bekannax/OnlineChatSdk-Swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'bekannax' => 'bekannax@gmail.com' }
  s.source           = { :git => 'https://github.com/bekannax/OnlineChatSdk-Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'OnlineChatSdk/Classes/**/*'
end
