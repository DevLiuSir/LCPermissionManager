Pod::Spec.new do |spec|
  spec.name         = "LCPermissionManager"

  spec.version      = "1.0.2"
  
  spec.summary      = "LCPermissionManager is a convenient wrapper on the macOS permissions API"

  spec.description  = <<-DESC
  LCPermissionManager is a convenient wrapper around the macOS permission API, including accessibility, screen recording, and full disk access permissions
                   DESC

  spec.homepage         = "https://github.com/DevLiuSir/LCPermissionManager"
  
  spec.license          = { :type => "MIT", :file => "LICENSE" }
  
  spec.author           = { "Marvin" => "93428739@qq.com" }
  
  spec.swift_versions   = ['5.0']
  
  spec.platform         = :osx
  
  spec.osx.deployment_target = "10.15"

  spec.source           = { :git => "https://github.com/DevLiuSir/LCPermissionManager.git", :tag => "#{spec.version}" }
  
  spec.source_files     = "Sources/LCPermissionManager/**/*.{h,m,swift}"
  
  spec.resource         = 'Sources/LCPermissionManager/Resources/**/*.strings'
  
  spec.resource_bundles = {
    'LCPermissionManager' => ['Sources/LCPermissionManager/Resources/*.bundle']
  }

end