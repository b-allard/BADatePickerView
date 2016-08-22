Pod::Spec.new do |s|
  s.name         = "BADatePickerView"
  s.version      = "0.0.1"
  s.summary      = "Custom UIDatePicker for iOS apps."
  s.homepage     = "https://github.com/b-allard/BADatePickerView"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Benjamin ALLARD" => "jobs@b-allard.be" }
  s.source       = { :git => "https://github.com/b-allard/BADatePickerView.git", :branch => "master" }
  s.platform     = :ios, '8.0'
  s.frameworks   = 'UIKit', 'CoreGraphics'
  s.source_files = 'BADatePickerView', 'BADatePickerView/**/*.{h,m}'
  s.requires_arc = true
end
