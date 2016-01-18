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

#import "MSSSAUIWebViewDelegate.h"
#import "MSSSACommonWebViewDelegate.h"

/**
 * MSASUIWebView からのコールバックを処理します。
 */
@implementation MSSSAUIWebViewDelegate
@synthesize controller;

- (id) initWithController:(MSSSAViewController*)ctl
{
    if (self = [super init]) {
        controller = ctl;
    }
    return self;
}

#pragma mark UIWebViewDelegage methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [MSSSACommonWebViewDelegate shouldStartLoadWithRequest:request withController:controller];
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.controller.spinner startAnimating];
    NSLog(@"webViewStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.controller.spinner stopAnimating];
    NSLog(@"webViewDidFinishLoad");
    [self.controller.footerView.backButton setEnabled:[self.controller.webViewSelector canGoBack]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.controller.spinner stopAnimating];
    NSLog(@"didFailLoadWithError");
    if (error.code == NSURLErrorCancelled) {return;}
    if(error.code == 101) return; // ignore error "The URL can’t be shown"
    if(error.code == 102) return; // ignore error "Frame load interrupted"

    NSLog(@"didfailload %@",error);
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", @"") message:NSLocalizedString(@"network connection is not avaiable", @"")
                              delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}
@end
