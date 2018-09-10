//
//  WKWebViewJSBridge.h
//  WKWebViewExample
//
//  Created by 付朋华 on 2017/11/7.
//  Copyright © 2017年 Lunaria Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebKit;

typedef void (^TBSWVJBResponseCallback)(id responseData);
typedef void (^TBSWVJBHandler)(id data, TBSWVJBResponseCallback responseCallback);
//typedef NSDictionary WVJBMessage;

@interface WKWebViewJSBridge : NSObject
@property (nonatomic, strong, readonly) WKWebViewConfiguration * webConfig;
+ (instancetype)bridge;
- (void)setWebView:(WKWebView *)webView;
- (void)registerHandler:(NSString *)handlerName handler:(TBSWVJBHandler)handler;
- (void)removeHandler:(NSString *)handlerName;

- (void)callHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(id)data;
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(TBSWVJBResponseCallback)responseCallback;
@end
