Pod::Spec.new do |s|
  s.name         = "Pool"
  s.version      = "0.2"
  s.license      = { :type => "MIT" }
  s.homepage     = "https://github.com/delba/Pool"
  s.author       = { "Damien" => "damien@delba.io" }
  s.summary      = "Seamless data sharing across nearby devices"
  s.source       = { :git => "https://github.com/delba/Pool.git", :tag => "v0.2" }

  s.ios.deployment_target = "8.0"

  s.source_files = "Source/**/*.{swift, h}"

  s.requires_arc = true
end
