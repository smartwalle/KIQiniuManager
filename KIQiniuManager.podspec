Pod::Spec.new do |s|
  s.name         = "KIQiniuManager"
  s.version      = "0.1"
  s.summary      = "KIQiniuManager"

  s.description  = <<-DESC
                   KIQiniuManager.
                   DESC

  s.homepage     = "https://github.com/smartwalle/KIQiniuManager"
  s.license      = "MIT"
  s.author             = { "SmartWalle" => "smartwalle@gmail.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/smartwalle/KIQiniuManager.git", :branch => "master" }

  s.source_files  = "KIQiniuManager/KIQiniuManager/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

  s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "AFNetworking", "~> 2.5.4"
  s.dependency "Qiniu", "~> 7.0.0"
  s.dependency "KIAdditions/NSString"
end
