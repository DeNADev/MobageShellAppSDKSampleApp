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

#import "MSSSAFooterView.h"

int const kFooterViewHeight = 50;

/**
 * アプリの画面下部に表示されるフッターです。
 */
@implementation MSSSAFooterView

- (IBAction)clickReloadButton:(UIButton *)sender {
    NSLog(@"webview: reload");
    [self.webViewSelector reload];
}

- (IBAction)clickBackButton:(UIButton *)sender {
    NSLog(@"webview: go back");
    [self.webViewSelector goBack];
    if (![self.webViewSelector canGoBack]) {
        [sender setEnabled:NO];
    }
}

- (IBAction)clickMenuButton:(UIButton *)sender {
    [self.webViewSelector evaluateJavaScriptString:@"app.menu.toggle();" callback:^(id result, NSError *error) {
        NSLog(@"open menu");
    }];
}

// touchable for transparent background
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *view in self.subviews) {
        if (!view.hidden && view.alpha > 0 && view.userInteractionEnabled &&
            [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    return NO;
}


@end
