Pod::Spec.new do |spec|
  spec.name             = 'OnlineChatSdk'
  spec.version          = '0.0.3'
  spec.summary          = 'A small library containing a wrapper for the WKWebView.'
  spec.swift_versions   = '5.0'
  spec.homepage         = 'https://github.com/bekannax/OnlineChatSdk-Swift'
  spec.license          = { :type => 'MIT', :file => 'LICENSE' }
  spec.authors          = { 'bekannax' => 'bekannax@gmail.com' }
  spec.source           = { :git => 'https://github.com/bekannax/OnlineChatSdk-Swift.git', :tag => s.version.to_s }
  spec.ios.deployment_target = '8.0'
  spec.source_files = 'OnlineChatSdk/Classes/**/*'
end
