var webPage = require('webpage');
var page = webPage.create();

var system = require('system');
var args = system.args;
var openid = args[1];
var url = 'http://weixin.sogou.com/gzh?openid=' + openid;

page.open(url, function(status) {
    var aes = page.evaluate(function() {
        return window.aes;
    });
    console.log(aes);
    phantom.exit();
});
