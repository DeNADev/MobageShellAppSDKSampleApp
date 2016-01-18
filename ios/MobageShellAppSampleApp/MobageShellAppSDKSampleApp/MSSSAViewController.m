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

#import <AdSupport/AdSupport.h>
#import "MSSSAViewController.h"
#import "MSSSASoundAssets.h"
#import "MSSSADomainWhiteList.h"
#import "MSSSAUtils.h"

/**
 * WebView を配置するメインの ViewController です。
 */
@implementation MSSSAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // WebView を生成します。MSSSAWebViewSelector により、iOSバージョンによって MSASUIWebView/MSASWKWebView を自動的に切り替えます。
    _webViewSelector = [MSSSAWebViewSelector sharedInstance];
    [_webViewSelector newWebViewWithFrame:[self webviewFrame]];
    [_webViewSelector setDelegateWithController:self];

    // WebView から UserAgent を取得します(デバッグ用)。
    [_webViewSelector evaluateJavaScriptString:@"navigator.userAgent" callback:^(id result, NSError *error) {
        if (!error) {
            NSLog(@"MSASWebView UA: %@", result);
        }
    }];

    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:_webViewSelector.webview];

    // サウンドファイルを登録します。
    [self initializeSoundAssets];
    
    // フッターを初期化します。
    [self initializeFooter];
    
    // スピナーを初期化します。
    [self initializeSpinner];

    // Info.plist に指定された MSSSAInitialURL を読み込み、WebView で表示します。
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MSSSAInitialURL"]];
    if (url == nil) {
        [[NSException exceptionWithName:NSGenericException reason:@"initial url is null" userInfo:nil] raise];
    }
    [[MSSSADomainWhiteList getInstance] addWhiteHost:[url host]];  // 初期URLをドメインホワイトリストに登録します。
    [_webViewSelector loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// WebView のフレームを返します。
- (CGRect)webviewFrame
{
    float statusBarMargin = 0.0;
    if ([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        statusBarMargin = 20.0;
    }

    int frameWidth = [UIScreen mainScreen].applicationFrame.size.width;
    int frameHeight = [UIScreen mainScreen].applicationFrame.size.height;
    CGRect webviewFrame = CGRectMake(0, 0, frameWidth, frameHeight + statusBarMargin);

    return webviewFrame;
}

// サウンドファイルを登録します。
- (void)initializeSoundAssets
{
    // sound bundle
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *soundPath = [NSString stringWithFormat:@"%@/sounds", appPath];

    [[MSSSASoundAssets getInstance] addAllFilesFromPath:soundPath];
}

// スピナーを初期化します。
- (void)initializeSpinner
{
    _spinner = [[MSSSAActivityIndicatorView alloc] init];
    [_webViewSelector.webview addSubview:_spinner];
    CGPoint point = _webViewSelector.webview.center;
    CGPoint center = [_webViewSelector.webview convertPoint:point fromView:self.view];
    _spinner.center = center;
}

// フッターを初期化します。
- (void)initializeFooter
{
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"footer" owner:[MSSSAFooterView class] options:nil];
    if ([nibContents count] != 0) {
        _footerView = nibContents[0];
    }

    float height = self.view.frame.size.height;
    float width = self.view.frame.size.width;
    CGRect footerFrame = CGRectMake(0, height - kFooterViewHeight, width, kFooterViewHeight);
    _footerView.frame = footerFrame;
    _footerView.webViewSelector = _webViewSelector;
    [_footerView.backButton setEnabled:NO];

    [self.view addSubview:_footerView];
}

@end
