Mobage ShellApp SDK iOS Sample Application
================================================================================

確認可能な機能一覧
--------------------------------------------------------------------------------
- ログイン機能
- Bank機能
- Remote Notification機能
- ドメインホワイトリスト機能
- サウンド機能


サンプルアプリケーションの動作方法
--------------------------------------------------------------------------------
1. 当プロジェクトをXcodeで開いてください。

2. `sdk/`以下にパートナーデベロッパーサイトから取得したMobage ShellApp SDKのframeworkとbundleを追加してください。

3. プロジェクトの設定でGeneralのタブを開き
`_BUNDLE_IDENTIFIER_`をパートナーデベロッパーサイトに設定したものと同じ`CFBundleIdentifier`に置き換えてください。

4. プロジェクトの設定でInfoのタブを開き、`_INITIAL_URL_`をサーバー側サンプルコードを設置したURLに置き換えてください。

5. `MobageShellAppSampleApp/MSSSAAppDelegate.m`内の`_EMBEDDED_KEY_`、`_EMBEDDED_SECRET_`を、
パートナーデベロッパーサイトにおいて登録したアプリケーションの`Embedded Key`、`Embedded Secret`に置き換えてください。


補足
--------------------------------------------------------------------------------
### Basic認証の設定
サーバーサイドにBasic認証をかけている場合、クライアント側で認証を突破できるよう以下の設定を行ってください。
`MobageShellAppSampleApp/MSSSAAppDelegate.m`内の
```
#define MSSSA_BASIC_AUTH_USERID @"userId"
#define MSSSA_BASIC_AUTH_PASSWORD @"password"
#define MSSSA_BASIC_AUTH_REALM @"realm"
```
のuserId、password、realmそれぞれを、Webサーバーに設定したBasic認証の設定値に置き換えてください。

### ドメインホワイトリストの追加方法
ゲームの初期URL（`Info.plist`で指定する`_INITIAL_URL_`）はデフォルトでホワイトリストに組み込まれます。
それ以外にホワイトリストに加えたいドメインがある場合は、`Info.plist`の`MSSSADomainWhiteList`に値を追加してください。

### サウンドファイルの追加方法
このサンプルにはサウンドファイルは付属していません。
確認の際には`Resources/sounds`以下にサウンドファイルを追加してください。


動作確認環境
--------------------------------------------------------------------------------
- Xcode 7.2
- Mac OS X 10.11.2
