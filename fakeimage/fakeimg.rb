require 'rtesseract'

image = RTesseract.new('/home/yy/dev/ruby/rails/gems/wx_ext/spec/seccode.jpg')
image.to_s #Getting the value