//
//  WKWebViewJSBridge.m
//  WKWebViewExample
//
//  Created by 付朋华 on 2017/11/7.
//  Copyright © 2017年 Lunaria Software LLC. All rights reserved.
//

#import "WKWebViewJSBridge.h"
@import WebKit;

static NSString * const TBSScriptMessageHandler = @"Bridge";
static NSString * const TBSBridgeLoaded = @"bridgeLoaded";
@interface WKWebViewJSBridge ()<WKScriptMessageHandler>
{
    __weak WKWebView* _webView;
    long _uniqueId;
}
@property (nonatomic, strong) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;//callHandler的
@property (nonatomic, strong) WKUserContentController* userController;
@property (nonatomic, strong) WKWebViewConfiguration * webConfig;
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;

@end

@implementation WKWebViewJSBridge

+ (instancetype)bridge {
    WKWebViewJSBridge *bridge = [[WKWebViewJSBridge alloc] init];
    return bridge;
}


- (void)dealloc {
    _messageHandlers = nil;
    _responseCallbacks = nil;
    _startupMessageQueue = nil;
    _webConfig = nil;
    [_userController removeScriptMessageHandlerForName:TBSScriptMessageHandler];
    _userController = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _uniqueId = 0;
       _startupMessageQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma ---mark property
- (NSMutableDictionary *)messageHandlers {
    if (!_messageHandlers) {
        _messageHandlers = [[NSMutableDictionary alloc] init];
        __weak typeof(self) weakSelf = self;
        dispatch_block_t handler = ^() {
            __strong typeof(weakSelf) self = weakSelf;
            [self dealWithMessageQuene];
        };
        self.messageHandlers[TBSBridgeLoaded] = [handler copy];

    }
    return _messageHandlers;
}

- (NSMutableDictionary *)responseCallbacks {
    if (!_responseCallbacks) {
        _responseCallbacks = [[NSMutableDictionary alloc] init];
    }
    return _responseCallbacks;
}

- (WKWebViewConfiguration*)webConfig {
    
    if (!_webConfig) {
        // Create WKWebViewConfiguration instance
        _webConfig = [[WKWebViewConfiguration alloc]init];
        _webConfig.userContentController = self.userController;
    }
    return _webConfig;
    
}

- (WKUserContentController *)userController {
    if (!_userController) {
        _userController = [[WKUserContentController alloc]init];
        [_userController addScriptMessageHandler:self name:TBSScriptMessageHandler];
    }
    return _userController;
}


- (void)setWebView:(WKWebView *)webView {
    _webView = webView;
}

#pragma mark -WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *messageHandlerName = message.name;
    if ([messageHandlerName isEqualToString:TBSScriptMessageHandler]) {
        NSDictionary *body = [self objectFromJSONString:message.body];
        NSString *responseId = body[@"responseId"];
        if (responseId) {
            TBSWVJBResponseCallback handler = self.responseCallbacks[responseId];
            if (handler) {
                id responseData = body[@"responseData"];
                handler(responseData);
                [self.responseCallbacks removeObjectForKey:responseId];
            }
        } else {
            NSString *handlerName = body[@"handlerName"];
            if (handlerName) {
                TBSWVJBHandler handler = self.messageHandlers[handlerName];
                if (handler) {
                    id params = body[@"data"];
                    NSString *callbackId = body[@"callbackId"];
                    TBSWVJBResponseCallback responseCallback = NULL;
                    if (callbackId) {
                        responseCallback = ^(id responseData) {
                            if (responseData == nil) {
                                responseData = [NSNull null];
                            }
                            NSDictionary* msg = @{@"responseId":callbackId, @"responseData":responseData};
                            [self _queueMessage:msg];
                        };
                    }
                    handler(params, responseCallback);
                }
            }
        }
    }
}

#pragma ---mark deal with message

- (void)dealWithMessageQuene {
    NSString* js = [self handlerJS];
    [self _evaluateJavascript:js];
    if (self.startupMessageQueue) {
        NSArray* queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queuedMessage in queue) {
            [self _dispatchMessage:queuedMessage];
        }
    }
}
- (void) _evaluateJavascript:(NSString *)javascriptCommand {
    [_webView evaluateJavaScript:javascriptCommand completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        
    }];
}

- (void)_queueMessage:(NSDictionary *)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(id)message{
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\u0000" withString:@""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromNative('%@');",  messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];
        
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}

- (NSString *)_serializeMessage:(id)message pretty:(BOOL)pretty{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:(NSJSONWritingOptions)(pretty ? NSJSONWritingPrettyPrinted : 0) error:nil] encoding:NSUTF8StringEncoding];
}

- (NSArray*)_deserializeMessageJSON:(NSString *)messageJSON {
    return [NSJSONSerialization JSONObjectWithData:[messageJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
}

- (void)sendData:(id)data responseCallback:(TBSWVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    if (handlerName) {
        NSMutableDictionary* message = [NSMutableDictionary dictionary];
        if (handlerName)
            message[@"handlerName"] = handlerName;
        
        if (data)  message[@"data"] = data;
        
        if (responseCallback) {
            NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
            self.responseCallbacks[callbackId] = [responseCallback copy];
            message[@"callbackId"] = callbackId;
        }
        [self _queueMessage:message];
    }
}


#pragma ---mark registerHandler
- (void)registerHandler:(NSString *)handlerName handler:(TBSWVJBHandler)handler {
    if (handlerName) {
        self.messageHandlers[handlerName] = [handler copy];
    }
}

- (void)removeHandler:(NSString *)handlerName {
    [self.messageHandlers removeObjectForKey:handlerName];
}

#pragma ---mark callHandler
- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(TBSWVJBResponseCallback)responseCallback {
    [self sendData:data responseCallback:responseCallback handlerName:handlerName];
}



#pragma ---mark  helpers
-(NSString *)handlerJS {
    NSBundle *curBundle = [NSBundle bundleForClass:self.class];
    NSString *curBundleDirectory = @"JSBridge.bundle";

    NSString *path =[curBundle pathForResource:@"WebViewJavaScriptBridge" ofType:@"js" inDirectory:curBundleDirectory];
    NSString *handlerJS = [NSString stringWithContentsOfFile:path encoding:kCFStringEncodingUTF8 error:nil];
    handlerJS = [handlerJS stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return handlerJS;
}

- (id)objectFromJSONString:(NSString *)jsonString {
    return [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

@end
