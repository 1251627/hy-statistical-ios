Pod::Spec.new do |s|
  s.name         = 'HyStatistical'
  s.version      = '0.1.4'
  s.summary      = 'HyStatistical 数据埋点 iOS SDK'
  s.description  = '事件上报、批量发送、离线缓存、Keychain 持久化、自动采集生命周期'
  s.homepage     = 'https://github.com/1251627/hy-statistical-ios'
  s.license      = { :type => 'MIT' }
  s.author       = { 'Your Name' => 'your@email.com' }
  s.source       = { :git => 'https://github.com/1251627/hy-statistical-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.9'
  s.source_files = 'Sources/HyStatistical/**/*.swift'
  s.frameworks   = 'Foundation', 'UIKit', 'Security'
end
