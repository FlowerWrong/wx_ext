# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wx_ext/version'

Gem::Specification.new do |spec|
  spec.name          = 'wx_ext'
  spec.version       = WxExt::VERSION
  spec.authors       = ['flowerwrong']
  spec.email         = ['sysuyangkang@gmail.com']
  spec.summary       = %q{a gem to hack mp.weixin.qq.com}
  spec.description   = %q{a gem to hack mp.weixin.qq.com}
  spec.homepage      = 'http://thecampus.cc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_development_dependency 'rspec'
  spec.add_dependency 'rest_client'
  spec.add_dependency 'nokogiri'
  # spec.add_dependency 'mechanize'
  # spec.add_dependency 'phantomjs', '~> 1.9.7.1'
  # spec.add_dependency 'capybara'
  # spec.add_dependency 'poltergeist'
end
