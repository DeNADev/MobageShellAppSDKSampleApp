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

#import "MSSSADomainWhiteList.h"

/**
 * WebView で表示するサイトのドメインのホワイトリストです。
 *
 * セキュリティのため、ゲームの WebView 内で表示されるサイトのドメインを制限します。
 *
 * リストは Info.plist の MSSSADomainWhiteList から読み込みます。
 *
 */
@interface MSSSADomainWhiteList ()

@property (nonatomic, strong) NSMutableArray *whiteDomains;

@end

@implementation MSSSADomainWhiteList

+ (instancetype)getInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _whiteDomains = [[NSMutableArray alloc] initWithArray:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MSSSADomainWhiteList"]];
    }
    return self;
}

/**
 * 指定されたホストをホワイトリストに追加します。
 *
 * @param host ホスト名。
 */
- (void)addWhiteHost:(NSString *)host
{
    if (!host) {
        return;
    }

    if (![_whiteDomains containsObject:host]) {
        [_whiteDomains addObject:host];
    }
}

/**
 * 指定されたホストがホワイトリストに含まれているかどうかを返します。
 *
 * @param host ホスト名。
 * @return host がホワイトリストに含まれていれば YES。host がホワイトリスト内のドメインのサブドメインの場合も YES を返します。
 */
- (BOOL)containsHost:(NSString *)host
{
    if (!host) {
        return NO;
    }

    for (NSString *domain in _whiteDomains) {
        if ([domain hasPrefix:@"."]) {
            if ([host hasSuffix:domain]) {
                return YES; // Backward match by domain - skip and render the site
            }
        } else {
            if ([host isEqualToString:domain]) {
                return YES; // Coincident - skip and render the site
            }

            NSString *dotDomain = [NSString stringWithFormat:@".%@", domain];
            if ([host hasSuffix:dotDomain]) {
                return YES; // Backward match by domain - skip and render the site
            }
        }
    }

    return NO;
}

@end
