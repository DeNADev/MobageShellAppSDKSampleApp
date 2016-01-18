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

#import "MSSSACommonWebViewDelegate.h"
#import "MSSSADomainWhiteList.h"
#import "MSSSAUtils.h"

/**
 * MSASUIWebView/MSASWKWebView からの共通のコールバックを処理します。
 *
 * ドメインホワイトリストのチェックを行っています(セキュリティのため)。
 */
@implementation MSSSACommonWebViewDelegate

+ (BOOL)shouldStartLoadWithRequest:(NSURLRequest *)request withController:(MSSSAViewController *)controller
{
    NSLog(@"Request URL: %@", [request.URL absoluteString]);

    // iframeなどmainDocumentでないところのwhitelistチェックしない
    if ([request.URL.absoluteString isEqualToString:request.mainDocumentURL.absoluteString] && [self handleExternalDomainUrl:request.URL]) {
        return NO;
    }

    return YES;
}

+ (BOOL)handleExternalDomainUrl:(NSURL *)url
{
    NSString *host = [url host];
    if ([[MSSSADomainWhiteList getInstance] containsHost:host]) {
        return NO;
    }

    if (![[UIApplication sharedApplication] openURL:url]) {
        [MSSSAUtils showOpenURLErrorDialog:url];
    }
    return YES;

}

@end
