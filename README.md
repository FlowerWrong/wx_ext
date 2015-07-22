# WxExt

Weixin extention, sougou weixin post spider and weixin api gem

## Dependency

phantomjs

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wx_ext', github: 'FlowerWrong/wx_ext'
```

And then execute:

    $ bundle

## Usage

See spec/wx_ext/

## Test

1. Change `spec/wx_ext/weixin_spec.rb` file username and pass
2. `rspec spec/wx_ext/weixin_spec.rb`
3. `rspec spec/wx_ext/sougou_weixin_spec.rb`

## Yard

`yardoc lib/*.rb lib/wx_ext/*.rb lib/wx_ext/api/*.rb lib/wx_ext/api/user/*.rb`

## Contributing

1. Fork it ( https://github.com/FlowerWrong/wx_ext/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
