#
# Be sure to run `pod lib lint AV360.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AV360'
  s.version          = '0.1.0'
  s.swift_version = '4.0'
    s.summary          = 'AV360 player for view video with 360 rotation'
  s.description      = 'AV360 is player to view video 360 degree with rotate device and swipe finger left right up and down'

  s.homepage         = 'https://github.com/sajidnawaz993/AV360'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sajid Nawaz' => 'sajidnawaz993@gmail.com' }
  s.source           = { :git => 'https://github.com/sajidnawaz993/AV360.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/SajidNawazSahi'

  s.ios.deployment_target = '13.0'

  s.source_files = 'AV360/Classes/**/*'
  s.resources = 'AV360/**/*.{png,jpeg,jpg,storyboard,xib,xcassets,json}'
  
  # s.resource_bundles = {
  #   'AV360' => ['AV360/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
