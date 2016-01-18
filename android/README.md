Mobage ShellApp SDK Android Sample Application
================================================================================

確認可能な機能一覧
--------------------------------------------------------------------------------
- ログイン機能
- Bank機能
- Remote Notification機能
- ドメインホワイトリスト機能
- サウンド機能
- スプラッシュスクリーン機能


サンプルアプリケーションの動作方法
--------------------------------------------------------------------------------
1. `MobageShellAppSDKSampleApp/`以下にMobage ShellApp SDKのライブラリプロジェクトを追加してください。

2. 当プロジェクトをAndroid Studioで開いてください。

3. `shellAppSDKSample/build.gradle`内の`_MOBAGE_APPLICATION_ID_`を
パートナーデベロッパーサイトにおいて登録したアプリケーションID(1202XXXXのような8桁の数字列)に置き換えてください。

4. `shellAppSDKSample/src/main/res/values/strings.xml`内の`_INITIAL_URL_`を、
サーバー側サンプルコードを設置したURLに置き換えてください。

5. `shellAppSDKSample/src/main/java/com/mobage/android/shellappsdk/sample/GameActivity.java`内の`_EMBEDDED_KEY_`、`_EMBEDDED_SECRET_`を、
パートナーデベロッパーサイトにおいて登録したアプリケーションの`Embedded Key`、`Embedded Secret`に置き換えてください。


補足
--------------------------------------------------------------------------------
### ドメインホワイトリストの追加方法
ゲームの初期URL(`shellAppSDKSample/src/main/res/values/strings.xml`で指定する`_INITIAL_URL_`)はデフォルトでホワイトリストに組み込まれます。
それ以外にホワイトリストに加えたいドメインがある場合は、`shellAppSDKSample/src/main/res/values/domain_white_list.xml`に追加してください。

### サウンドファイルの追加方法
このサンプルにはサウンドファイルは付属していません。確認の際には`shellAppSDKSample/src/main/assets/sound`以下にサウンドファイルを追加してください。

### スプラッシュスクリーンの変更方法
サンプルでは起動時にスプラッシュスクリーンを表示する機能があります。
`shellAppSDKSample/src/main/res/drawable-nodpi/splash.png`が表示されますので画像データは適宜差し替えてください。


動作確認環境
--------------------------------------------------------------------------------
- Android Studio 1.5.1
- Mac OS X 10.11.2
