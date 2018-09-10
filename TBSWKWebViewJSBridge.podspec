#
# Be sure to run `pod lib lint TBSWKWebViewJSBridge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TBSWKWebViewJSBridge'
  s.version          = '1.0.0'
  s.summary          = 'js和native通讯，只用于WKWebView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
页面上的js已初始化时需要调用window.webkit.messageHandlers.Bridge.postMessage('{ "handlerName": "bridgeLoaded" }')
1.js调用ios

window.webkit.messageHandlers.Bridge在webkit初始化时已声明，js可直接调用，无需等待。
js向ios发送消息: window.webkit.messageHandlers.Bridge.postMessage(message)
message JSON
handlerName String 调用bridge的名字，如share、alert
data Object 传递给native的数据
callbackId String callback的id，ios回调时，改名为responseId
ios回调：window.WebViewJavascriptBridge._handleMessageFromNative(message)
message JSON
responseData Object 给js的数据
responseId String 值为js传过来的callbackId
2.ios调用js

ios调用：window.WebViewJavascriptBridge._handleMessageFromNative(message)
message JSON
handlerName String 值为Events (JavaScript Handler)
data Object 传递给js的数据
callbackId String= 暂无
                       DESC

  s.homepage         = 'https://github.com/fupenghua/TBSJSBridgeForWKWebView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fupenghua' => '390908980@qq.com' }
  s.source           = { :git => 'https://github.com/fupenghua/TBSJSBridgeForWKWebView.git', :tag => s.version.to_s }
  s.source_files = 'TBSWKWebViewJSBridge/*.{h,m}'
  s.resource     = 'TBSWKWebViewJSBridge/JSBridge.bundle'
  s.ios.deployment_target = '8.0'

  s.source_files = 'TBSWKWebViewJSBridge/Classes/**/*'
  
end
