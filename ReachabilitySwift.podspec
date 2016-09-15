Pod::Spec.new do |s|
  s.name         = 'ReachabilitySwift'
  s.version      = '2.4'
  s.homepage     = 'https://github.com/ashleymills/Reachability.swift'
  s.authors      = {
    'Ashley Mills' => 'ashleymills@mac.com'
  }
  s.summary      = 'Replacement for Apple\'s Reachability re-written in Swift with callbacks.'
  s.license      = { :type => 'MIT' }

# Source Info
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target  = "9.0"
  s.source       =  {
    :git => 'https://github.com/ashleymills/Reachability.swift.git',
    :branch => 'swift-2.3',
    :tag => 'v'+s.version.to_s
  }
  s.source_files = 'Reachability/Reachability.swift'
  s.framework    = 'SystemConfiguration'

  s.requires_arc = true
end
