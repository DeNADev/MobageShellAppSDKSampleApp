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

#import <Foundation/Foundation.h>
#import <MobageShellApp/MobageShellApp.h>

@class MSSSAViewController;

/**
 * iOSバージョンによって MSASUIWebView/MSASWKWebView を自動的に切り替えるクラスです。
 *
 * カスタムブリッジメソッドの設定も行っています。
 */
@interface MSSSAWebViewSelector : NSObject

+ (instancetype)sharedInstance;
- (UIView *)webview;
- (UIView *)newWebViewWithFrame:(CGRect)frame;
- (void)setDelegateWithController:(MSSSAViewController *)controller;
- (void)removeDelegate;
- (void)loadRequest:(NSURLRequest *)request;
- (void)evaluateJavaScriptString:(NSString *)js;
- (void)evaluateJavaScriptString:(NSString *)js callback:(void (^)(id result, NSError *error))callback;
- (BOOL)canGoBack;
- (BOOL)canGoForward;
- (void)goBack;
- (void)goForward;
- (void)reload;

- (BOOL)subscribe:(NSString *)method
     withCallback:(MSASJSBridgeCallback)callback;
- (MSASSession *)session;

@end
