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

#import "MSSSAAppDelegate.h"
#import <MobageShellApp/MobageShellApp.h>

/**
 * アプリケーションに関するイベントを処理するクラスです。
 */
@implementation MSSSAAppDelegate

// デベロッパーサイトに記載されている Embedded Key/Embedded Secret に置き換えてください。
// Sandbox用と本番用で値が異なります。
#define MSSSA_EMBEDDED_KEY @"_EMBEDDED_KEY_"
#define MSSSA_EMBEDDED_SECRET @"_EMBEDDED_SECRET_"

// アプリのサーバサイドにかけているBasic認証の userid/password および realm に置き換えてください。
#define MSSSA_BASIC_AUTH_USERID @"userId"
#define MSSSA_BASIC_AUTH_PASSWORD @"password"
#define MSSSA_BASIC_AUTH_REALM @"realm"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Embedded Key/Embedded Secret を設定します。
    // Embedded Key/Embedded Secret は独自ロジックで暗号化することをお勧めします。
    [[MSASContext sharedInstance] setKey:MSSSA_EMBEDDED_KEY];
    [[MSASContext sharedInstance] setSecret:MSSSA_EMBEDDED_SECRET];

    // アプリケーションがリモート通知を受信できるように登録します。
    [MSASRemoteNotification registerForRemoteNotifications];

    // ステータスバーを設定します。
    [self initializeStatusBar];
    
    // Basic認証のパスワードを設定します。
    [self initializeBasicAuthentication];

    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
//  NSLog(@"device token: %@", deviceToken);
    // アプリケーションがリモート通知を送受信できるようにデバイストークンを保存します。
    [MSASRemoteNotification didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // アプリケーションがリモート通知を送受信できないことを通知します。
    [MSASRemoteNotification didFailToRegisterForRemoteNotificationsWithError:error];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Remote Notification のpayload をここで受け取ることができます。
    NSLog(@"Receive remote notification: %@", userInfo);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self application:application didReceiveRemoteNotification:userInfo];
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

// ログインを完了させるためにアプリを起動したURLを通知します。
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[MSASContext sharedInstance] handleOpenURL:url];
    return YES;
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    [[MSASContext sharedInstance] handleOpenURL:url];
    return YES;
}

// ステータスバーを「あり」に設定します。
-(void)initializeStatusBar {
    [self.window makeKeyAndVisible];
    if ([[UIDevice currentDevice].systemVersion compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
        // ステータスバーの背景を作成
        UIView *statusbarBackgroundView = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame];
        statusbarBackgroundView.backgroundColor = [UIColor whiteColor];
        [_window addSubview:statusbarBackgroundView];
    } else {
        // relayout
        UIView *mainView = self.window.rootViewController.view;
        mainView.frame = [UIScreen mainScreen].applicationFrame;
    }
    [UIApplication sharedApplication].statusBarHidden = NO;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
}

// Basic認証のパスワードを設定します。
-(void)initializeBasicAuthentication {

    // For basic authentication
    NSURL *initialURL = [NSURL URLWithString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MSSSAInitialURL"]];
    if (initialURL == nil) {
        return;
    }
    NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
    NSLog(@"port :%@", [initialURL port]);
    NSInteger port = [[initialURL port] integerValue];
    if (!port) {
        if ([@"http" isEqualToString:[initialURL scheme]]) {
            port = 80;
        } else if ([@"https" isEqualToString:[initialURL scheme]]) {
            port = 443;
        } else {
            NSLog(@"initialize basic auth: invalid scheme");
            return;
        }
    }
    NSURLCredential *credential = [NSURLCredential credentialWithUser:MSSSA_BASIC_AUTH_USERID password:MSSSA_BASIC_AUTH_PASSWORD persistence:NSURLCredentialPersistenceForSession];
    NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:[initialURL host]
                                                                                  port:port
                                                                              protocol:[initialURL scheme]
                                                                                 realm:MSSSA_BASIC_AUTH_REALM
                                                                  authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    [storage setCredential:credential forProtectionSpace:protectionSpace];
}

@end
