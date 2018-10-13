Pod::Spec.new do |s|
  s.name         = "EyeTracker"
  s.version      = "0.1.0"
  s.summary      = "Track gazing position with ARKit"
  s.homepage     = "https://github.com/sidepelican/EyeTracker"
  s.license      = "MIT"
  s.author             = { "iceman" => "side.junktown@gmail.com" }
  s.social_media_url   = "http://twitter.com/iceman5499"
  s.platform     = :ios, "12.0"
  s.source       = { :git => "https://github.com/sidepelican/EyeTracker.git", :tag => "#{s.version}" }
  s.source_files  = "EyeTracker/*.swift"
  s.framework  = "ARKit"
  s.swift_version = '4.2'
end
