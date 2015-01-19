# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wx_ext/version'

Gem::Specification.new do |spec|
  spec.name          = 'wx_ext'
  spec.version       = WxExt::VERSION
  spec.authors       = ['flowerwrong']
  spec.email         = ['sysuyangkang@gmail.com']
  spec.summary       = %q{A gem to hack mp.weixin.qq.com and weixin base api.}
  spec.description   = %q{This gem provide hack mp.weixin.qq.com and weixin open api.}
  spec.homepage      = 'http://thecampus.cc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'yard', '~> 0.8'
  spec.add_development_dependency 'rspec', '~> 3.1'

  spec.add_dependency 'rest_client', '~> 1.8'
  spec.add_dependency 'nokogiri', '~> 1.6'
end
