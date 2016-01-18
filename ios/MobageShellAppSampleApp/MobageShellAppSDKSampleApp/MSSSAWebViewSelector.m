/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 DeNA Co., Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 **/

#import "MSSSAWebViewSelector.h"
#import "MSSSAUIWebViewDelegate.h"
#import "MSSSAWKWebViewDelegate.h"

/**
 * iOSバージョンによって MSASUIWebView/MSASWKWebView を自動的に切り替えるクラスです。
 *
 * カスタムブリッジメソッドの設定も行っています。
 */
@implementation MSSSAWebViewSelector
{
    MSASUIWebView *_uiWebView;
    MSSSAUIWebViewDelegate *_uiDelegate;

    MSASWKWebView *_wkWebView;
    MSSSAWKWebViewDelegate *_wkDelegate;
}

static MSSSAWebViewSelector *sharedInstance;
static BOOL useWKWebView;



+ (instancetype)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[MSSSAWebViewSelector alloc] init];
    }
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        BOOL isMSSSAWKWebViewEnabled = [[[NSBundle mainBundle] infoDictionary][@"MSSSAWKWebViewEnabled"] boolValue];
        if (([[UIDevice currentDevice].systemVersion compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) && isMSSSAWKWebViewEnabled) {
            useWKWebView = YES;
            NSLog(@"Use WKWebView");
        } else {
            useWKWebView = NO;
            NSLog(@"Use UIWebView");
        }
    }
    return self;
}

- (UIView *)newWebViewWithFrame:(CGRect)frame
{
    UIView *webview = nil;
    if (useWKWebView) {
        _wkWebView = [[MSASWKWebView alloc] initWithFrame:frame];
        webview = _wkWebView;
    } else {
        _uiWebView = [[MSASUIWebView alloc] initWithFrame:frame];
        _uiWebView.dataDetectorTypes = UIDataDetectorTypeNone;
        _uiWebView.scalesPageToFit = YES;
        webview = _uiWebView;
    }
    webview.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    [self registerCustomBridgeMethods];

    return webview;
}

- (UIView *)webview
{
    if (useWKWebView) {
        return _wkWebView;
    } else {
        return _uiWebView;
    }
}

- (void)setDelegateWithController:(MSSSAViewController *)controller
{
    if (useWKWebView) {
        if (_wkWebView) {
            _wkDelegate = [[MSSSAWKWebViewDelegate alloc] initWithController:controller];
            _wkWebView.navigationDelegate = _wkDelegate;
            _wkWebView.UIDelegate = _wkDelegate;
        }
    } else {
        if (_uiWebView) {
            _uiDelegate = [[MSSSAUIWebViewDelegate alloc] initWithController:controller];
            _uiWebView.delegate = _uiDelegate;
        }
    }
}

- (void)removeDelegate
{
    if (useWKWebView) {
        if (_wkWebView) {
            _wkWebView.navigationDelegate = nil;
            _wkWebView.UIDelegate = nil;
            _wkDelegate = nil;
        }
    } else {
        if (_uiWebView) {
            _uiWebView.delegate = nil;
            _uiDelegate = nil;
        }
    }
}

- (void)loadRequest:(NSURLRequest *)request
{
    if (useWKWebView) {
        if (_wkWebView) {
            [_wkWebView loadRequest:request];
        }
    } else {
        if (_uiWebView) {
            [_uiWebView loadRequest:request];
        }
    }
}

- (void)evaluateJavaScriptString:(NSString *)js
{
    [self evaluateJavaScriptString:js callback:nil];
}

- (void)evaluateJavaScriptString:(NSString *)js
                        callback:(void (^)(id result, NSError *error))callback
{
    if (useWKWebView) {
        if (_wkWebView) {
            [_wkWebView evaluateJavaScript:js completionHandler:^(id result, NSError *error) {
                if (callback) {
                    callback(result, error);
                }
            }];
        }
    } else {
        if (_uiWebView) {
            NSString *result = [_uiWebView stringByEvaluatingJavaScriptFromString:js];
            if (callback) {
                callback(result, nil);
            }
        }
    }
}

- (BOOL)canGoBack
{
    if (useWKWebView) {
        if (_wkWebView) {
            return _wkWebView.canGoBack;
        }
    } else {
        if (_uiWebView) {
            return _uiWebView.canGoBack;
        }
    }
    return NO;
}

- (BOOL)canGoForward
{
    if (useWKWebView) {
        if (_wkWebView) {
            return _wkWebView.canGoForward;
        }
    } else {
        if (_uiWebView) {
            return _uiWebView.canGoForward;
        }
    }
    return NO;
}

- (void)goBack
{
    if (useWKWebView) {
        if (_wkWebView) {
            [_wkWebView goBack];
        }
    } else {
        if (_uiWebView) {
            [_uiWebView goBack];
        }
    }
}

- (void)goForward
{
    if (useWKWebView) {
        if (_wkWebView) {
            [_wkWebView goForward];
        }
    } else {
        if (_uiWebView) {
            [_uiWebView goForward];
        }
    }
}

- (void)reload
{
    if (useWKWebView) {
        if (_wkWebView) {
            [_wkWebView reload];
        }
    } else {
        if (_uiWebView) {
            [_uiWebView reload];
        }
    }
}

- (BOOL)subscribe:(NSString *)method
     withCallback:(MSASJSBridgeCallback)callback
{
    id<MSASWebView> tmpWebView = (id<MSASWebView>)self.webview;
    if (tmpWebView) {
        return [[tmpWebView bridge] subscribe:method withCallback:callback];
    } else {
        return NO;
    }
}

- (MSASSession *) session
{
    id<MSASWebView> tmpWebView = (id<MSASWebView>)self.webview;
    if (tmpWebView) {
        return [tmpWebView session];
    } else {
        return nil;
    }
}

// カスタムブリッジメソッドを設定します。
- (void)registerCustomBridgeMethods
{
    // handle customize bridge method
    [self subscribe:@"bridge.test" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        response(params);
    }];

    // init sound api
    [self subscribe:@"sdksample.Music.play" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        NSLog(@"music play");
        NSString *name = params[@"name"];

        double fadeTime = 0.0;
        NSNumber *fadeTimeParam = params[@"fadeTime"];
        if (fadeTimeParam && [fadeTimeParam isKindOfClass:[NSNumber class]]) {
            fadeTime = [fadeTimeParam doubleValue];
        }

        int loopCount = -1;
        NSNumber *loopCountTimeParam = params[@"loopCount"];
        if (loopCountTimeParam && [loopCountTimeParam isKindOfClass:[NSNumber class]]) {
            loopCount = [loopCountTimeParam intValue];
        }

        [[MSSSASound getInstance] playMusic:name fadeDuration:fadeTime loopCount:loopCount];

        response(@{});
    }];

    [self subscribe:@"sdksample.Music.pause" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        NSLog(@"music pause");
        [[MSSSASound getInstance] pauseMusic];
        response(@{});
    }];

    [self subscribe:@"sdksample.Music.resume" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        NSLog(@"music resume");
        [[MSSSASound getInstance] resumeMusic];
        response(@{});
    }];

    [self subscribe:@"sdksample.Music.stop" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        NSLog(@"music stop");
        double fadeTime = 0.0;
        NSNumber *fadeTimeParam = params[@"fadeTime"];
        if (fadeTimeParam && [fadeTimeParam isKindOfClass:[NSNumber class]]) {
            fadeTime = [fadeTimeParam doubleValue];
        }

        [[MSSSASound getInstance] stopMusic:fadeTime];

        response(@{});
    }];

    [self subscribe:@"sdksample.SoundEffect.play" withCallback:^(NSString *method, NSDictionary *params, MSASJSBridgeResponse response) {
        NSLog(@"sound effect play");
        NSString *name = params[@"name"];

        [[MSSSASound getInstance] playSE:name];

        response(@{});
    }];

}

@end
