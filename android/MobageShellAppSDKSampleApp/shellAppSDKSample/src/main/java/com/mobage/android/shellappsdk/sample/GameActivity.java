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

package com.mobage.android.shellappsdk.sample;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Window;
import android.webkit.WebView;

import com.mobage.android.shellappsdk.FOXHelper;
import com.mobage.android.shellappsdk.MobageContext;
import com.mobage.android.shellappsdk.MobageError;
import com.mobage.android.shellappsdk.api.RemoteNotification;
import com.mobage.android.shellappsdk.api.RemoteNotificationListener;
import com.mobage.android.shellappsdk.api.RemoteNotificationPayload;
import com.mobage.android.shellappsdk.session.MobageSession;
import com.mobage.android.shellappsdk.session.TrackingEventListener;

/**
 * WebView を配置するメインの Activity です。
 */
public class GameActivity extends Activity {
    private static final String TAG = "GameActivity";
    private static final int FINISH_DIALOG = 0xff;

    private FooterView mFooter;
    private GameWebView mWebView;
    private MobageContext mMobageContext;
    private boolean isStatusPause = false;
    private SplashScreenController mSplashScreenController;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        requestWindowFeature(Window.FEATURE_NO_TITLE);

        setContentView(Res.layout("main"));

        // Google Play Services が利用可能かチェックします。
        if (SACUtils.checkPlayServices(this)) {
            // Google Play Services が利用可能な場合
        } else {
            // Google Play Services が利用できない場合
        }

        // MobageContext のインスタンスを初期化します。
        mMobageContext = MobageContext.getInstance(this);
        // Embedded Key/Embedded Secret を設定します。Sandbox用と本番用で値が異なります。
        // Embedded Key/Embedded Secret は独自ロジックで暗号化することをお勧めします。
        mMobageContext.setClientCredentials("_EMBEDDED_KEY_", "_EMBEDDED_SECRET_");

        //リモート通知機能を使う場合は必ず以下のようにコールして下さい。
//        mMobageContext.setClientCredentials("_EMBEDDED_KEY_","_EMBEDDED_SECRET_", MobageContext.ServerMode.SANDBOX);
//        mMobageContext.setFirebaseDefaultApp();

        // WebView を初期化します。
        mWebView = (GameWebView)findViewById(Res.id("webView"));
        setupWebView(mWebView);
        
        // フッターを初期化します。
        mFooter = (FooterView)findViewById(Res.id("footer"));
        mFooter.setWebView(mWebView);

        // スプラッシュスクリーンを表示します。
        mSplashScreenController = new SplashScreenController();
        mSplashScreenController.showSplashScreen(this);

        // Intent を処理します。
        handleIntent(getIntent());
        
        // Google In-app Billing サービスにバインドします。
        mMobageContext.getBillingController().bindBillingService(this);
        
        // サウンドファイルを登録します。
        registerSoundAssets();

        // res/values/strings.xml から URL を読み込み、WebView で表示します。
        String url = getResources().getString(Res.string("url"));
        DomainWhiteList.getInstance(this).insert(Uri.parse(url).getHost());  // 初期URLをドメインホワイトリストに登録します。
        mWebView.loadUrl(url);
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
        
        // Google In-app Billing サービスからアンバインドします。
        mMobageContext.getBillingController().unbindBillingService(this);
        
        // サウンドプールを解放します。
        SACSound.release();
    }

    @Override
    public void onNewIntent(Intent intent) {
        // Intent を処理します。
        handleIntent(intent);
    }
    
    // Intent を処理します。
    private void handleIntent(Intent intent) {
        setIntent(intent);
        mMobageContext.getCallbackIntentReceiver().onReceiveIntent(intent);
        
        // Remote Notification のステータスバー通知をタップしてアプリ起動された場合の payload をここで受け取ることができます。
        Bundle extras = intent.getExtras();
        if (extras != null) {
            RemoteNotificationPayload payload = RemoteNotification.extractPayloadFromIntent(intent);
            Log.i(TAG, "Received Remote Notification payload via intent: " + payload);
        }
    }
    
    @Override
    public void onResume() {
        super.onResume();
        if (!SACUtils.isAndroidEmulator()) {
            SACUtils.checkPlayServices(this);
        }

        // 外部ブラウザから戻ってきたときにログイン完遂していない場合はキャンセルします。
        mMobageContext.getCallbackIntentReceiver().cancel();
        
        // フォアグラウンドにいる間に来た Remote Notification をアプリでハンドルする例です。
        RemoteNotification.setRemoteNotificationListener(new RemoteNotificationListener() {
            @Override
            public void handleReceive(Context context, Intent intent) {
                final RemoteNotificationPayload payload = RemoteNotification.extractPayloadFromIntent(intent);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        // フォアグラウンドにいる間に受信した Remote Notification をここで処理することができます。
                        Log.i(TAG, "Received Remote Notification at foreground: " + payload);
                    }
                });
            }
        });
        
        if (hasWindowFocus()) {
            SACSound.getInstance(this).onResume();
        }
        
        isStatusPause = false;
    }
    
    @Override
    public void onPause() {
        super.onPause();
        // バックグラウンドにいる間に来た Remote Notification をアプリでハンドルするのをやめ、ステータスバーに通知されるようにする例です。 
        RemoteNotification.setRemoteNotificationListener(null);
        
        SACSound.getInstance(this).onPause();
        isStatusPause = true;
    }
    
    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        if(hasFocus && !isStatusPause) {
            SACSound.getInstance(this).onResume();
        }
        super.onWindowFocusChanged(hasFocus);
    }
    
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent keyEvent) {
        if (keyEvent.getAction() == KeyEvent.ACTION_DOWN && keyCode == KeyEvent.KEYCODE_BACK) {
            // Back キー押下により前のページに戻るか、または終了確認ダイアログを表示します。
            if (mWebView.canGoBack()) {
                mWebView.goBack();
            } else {
                confirmFinish();
            }
            return true;
        }
        return super.onKeyDown(keyCode, keyEvent);
    }
    
    @Override
    public Dialog onCreateDialog(int id) {
        switch (id) {
        case FINISH_DIALOG:
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setTitle(Res.string("finish_dialog_title"));
            builder.setMessage(Res.string("finish_dialog_message"));
            builder.setPositiveButton(Res.string("finish_dialog_ok"), new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    SACSound.getInstance(GameActivity.this).stopMusic(0.0f);
                    finish();
                }
            });
            builder.setNegativeButton(Res.string("finish_dialog_cancel"), new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                }
            });
            return builder.create();
        }
        return null;
    }
    
    private void setupWebView(GameWebView webView) {
        // WebView に MobageContext をセットします(必須)。
        webView.setMobageContext(mMobageContext);
        
        // Navigation
        webView.setNavigationListener(new GameWebView.NavigationListener() {
            @Override
            public void onReceivedError(WebView webView, int errorCode, String description, String failingUrl) {
                mFooter.updateBackButtonState();
                mSplashScreenController.hideSplashScreen(GameActivity.this);
            }
            
            @Override
            public void onPageFinished(WebView webView, String url) {
                mFooter.updateBackButtonState();
                mSplashScreenController.hideSplashScreen(GameActivity.this);
            }
        });
    }
    
    // サウンドファイルを登録します。
    private void registerSoundAssets() {
        SACSoundAssets soundAssets = SACSoundAssets.getInstance(this);

        // APK の assets/sound/ 以下のファイルを全て登録します。アセットは拡張子を除いた名前で登録されます。
        soundAssets.addAllFilesFromAsssets("sound");
         
        // パスを指定して個別のファイルを登録します。この例の場合、APK内の res/raw/bgm1.ogg を "bgm1" という名前で参照できるようになります。
//      soundAssets.add("bgm1", "android.resource://" + getPackageName() + "/" + R.raw.bgm1);
         
        // パスを指定して個別のファイルを登録します。この例の場合、アプリのキャッシュディレクトリ内のファイルを登録します。
//      soundAssets.add("bgm1", new File(getCacheDir(), "bgm1.ogg").getPath());
    }
    
    // 終了確認ダイアログを表示します。
    @SuppressWarnings("deprecation")
    private void confirmFinish() {
        if (!isFinishing()) {
            showDialog(FINISH_DIALOG);
        }
    }
}
