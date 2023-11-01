require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name = "iapserver"
  spec.version = IAPServer::VERSION
  spec.authors = ["Cary"]
  spec.email = ["guojiashuang@live.com"]

  spec.summary = "苹果内购票据验证、苹果AppStore Connect API查询命令行工具"
  spec.description = "苹果内购票据验证、苹果AppStore Connect API查询命令行工具"
  spec.homepage = 'https://github.com/CaryGo/iapserver'
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files = Dir["lib/**/*.rb", "bin/*", 'assets/*'] #+ %w{ README.md LICENSE.txt CHANGELOG.md }
  spec.bindir = "bin"
  spec.executables = %w{ iapserver }
  spec.require_paths = %w{ lib }

  spec.add_runtime_dependency 'jwt', '~> 2.7'
  spec.add_runtime_dependency 'uuidtools', '~> 2.2.0'
  spec.add_runtime_dependency 'openssl', '~> 3.2'
  spec.add_runtime_dependency 'pathname'
  spec.add_runtime_dependency 'fileutils'
  
  spec.add_runtime_dependency 'colored2', '~> 3.1'
  spec.add_runtime_dependency 'commander', '~> 4.6'
end
