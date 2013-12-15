Pod::Spec.new do |s|

  s.name         = "SKMuteSwitchDetector"
  s.version      = "0.0.1"
  s.summary      = "Helper class to detect mute switch state."


  s.license      = { :type => 'MIT', :file => 'license.txt' }
  s.author       = { "Filipe Pina" => "fopina@gmail.com" }

  s.platform     = :ios, '6.0'
  s.homepage     = "http://https://github.com/fopina/MuteDetector"
  s.source       = { :git => "https://github.com/fopina/MuteDetector.git", :commit => "85140eb34da8e4d10026917947a7d609963ca51b"}


  s.source_files  = 'MuteDetector/SKMuteSwitchDetector.{h,m}'

  s.public_header_files = 'MuteDetector/SKMuteSwitchDetector.h'

  s.frameworks = 'AVFoundation'

  s.requires_arc = true

end
