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

import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.util.AttributeSet;
import android.util.Log;
import android.webkit.WebView;

import com.mobage.android.shellappsdk.webkit.JSBridge;
import com.mobage.android.shellappsdk.webkit.JSBridgeCallback;
import com.mobage.android.shellappsdk.webkit.JSBridgeResponse;
import com.mobage.android.shellappsdk.webkit.MobageWebChromeClient;
import com.mobage.android.shellappsdk.webkit.MobageWebView;
import com.mobage.android.shellappsdk.webkit.MobageWebViewClient;

/**
 * MobageWebView を継承した、ゲームコンテンツ用の WebView です。
 * 
 * 以下の機能実装を行っています。
 * 
 * - カスタムブリッジメソッドの設定
 * - ドメインホワイトリストのチェック (セキュリティのため)
 * - file: スキーマのチェック (セキュリティのため)
 * - 読み込み中プログレス表示
 *
 */
public class GameWebView extends MobageWebView {
    private static final String TAG = "GameWebView";
    
    private NavigationListener mNavigationListener;
    private SACProgressDialog mLoadingDialog;
    private DomainWhiteList mDomainWhiteList;

    public GameWebView(Context context) {
        super(context);
        if (!isInEditMode()) {
            init(context);
        }
    }

    public GameWebView(Context context, AttributeSet attrs) {
        super(context, attrs);
        if (!isInEditMode()) {
            init(context);
        }
    }

    public GameWebView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        if (!isInEditMode()) {
            init(context);
        }
    }
    
    private void init(Context context) {
        // WebView の設定
        getSettings().setUseWideViewPort(true);
        getSettings().setAllowFileAccess(false);
        setHorizontalScrollBarEnabled(false);
        setVerticalScrollBarEnabled(true);
        setHorizontalScrollbarOverlay(true);
        setVerticalScrollbarOverlay(true);
        setWebViewClient(new MyWebViewClient());
        setWebChromeClient(new MobageWebChromeClient());    // もし WebChromeClient を設定したい場合は、MobageWebChromeClient のサブクラスを設定してください。
        
        // UserAgent の設定 : もし UserAgent を独自に設定したい場合は、WebSettings#setUserAgentString() の代わりにこのメソッドを利用してください。
//        setUserAgentString(getSettings().getUserAgentString() + " MyUserAgent");
        
        // カスタムブリッジメソッドの設定
        registerCustomBridgeMethods();
        
        // ドメインホワイトリスト
        mDomainWhiteList = DomainWhiteList.getInstance(context);
    }
    
    // カスタムブリッジメソッドの設定
    private void registerCustomBridgeMethods() {
        JSBridge bridge = getJSBridge();
        bridge.subscribe("bridge.test", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                response.submit(parameters);
            }
        });
        
        // sdksample.Music.*
        bridge.subscribe("sdksample.Music.play", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                try {
                    String name = parameters.getString("name");
                    Float fadeTime = (float)parameters.optDouble("fadeTime", 0.0);
                    int loopCount = parameters.optInt("loopCount", -1);
                    SACSound.getInstance(getContext()).playMusic(name, fadeTime, loopCount);
                } catch (JSONException e) {
                    Log.e(TAG, "Failed to parse JSON", e);
                }
                response.submit(new JSONObject());
            }
        });
        bridge.subscribe("sdksample.Music.pause", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                SACSound.getInstance(getContext()).pauseMusic();
                response.submit(new JSONObject());
            }
        });
        bridge.subscribe("sdksample.Music.resume", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                SACSound.getInstance(getContext()).resumeMusic();
                response.submit(new JSONObject());
            }
        });
        bridge.subscribe("sdksample.Music.stop", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                Float fadeTime = (float)parameters.optDouble("fadeTime", 0.0);
                SACSound.getInstance(getContext()).stopMusic(fadeTime);
                response.submit(new JSONObject());
            }
        });
        // sdksample.SoundEffect.*
        bridge.subscribe("sdksample.SoundEffect.play", new JSBridgeCallback() {
            @Override
            public void handleMessage(String method, JSONObject parameters, JSBridgeResponse response) {
                try {
                    String name = parameters.getString("name");
                    SACSound.getInstance(getContext()).playSE(name);
                } catch (JSONException e) {
                    Log.e(TAG, "Failed to parse JSON", e);
                }
                response.submit(new JSONObject());
            }
        });
    }
    
    public void setNavigationListener(NavigationListener listener) {
        mNavigationListener = listener;
    }
    
    @Override
    public void loadUrl(String url) {
        Uri uri = Uri.parse(url);
        if (!"javascript".equalsIgnoreCase(uri.getScheme())) {
            // "file:" スキーマが指定された場合、セキュリティのため読み込みを中止します。
            if ("file".equalsIgnoreCase(uri.getScheme())) {
                super.loadUrl("about:blank");
                Log.w(TAG, "Prevented loading file URL: " + url);
                return;
            }
            // ホワイトリストに含まれていないドメインを開こうとした場合、ブラウザで開きます。
            if (handleExternalDomainUrl(url)) {
                Log.w(TAG, "Prevented loading external URL: " + url);
                return;
            }
        }
        super.loadUrl(url);
    }
    
    public void showLoadingDialog() {
        dismissLoadingDialog();
        if (getContext() instanceof Activity && !((Activity)getContext()).isFinishing()) {
            mLoadingDialog = new SACProgressDialog(getContext());
            mLoadingDialog.show();
        }
    }
    
    public void dismissLoadingDialog() {
        if (mLoadingDialog != null && mLoadingDialog.isShowing()) {
            mLoadingDialog.dismiss();
        }
        mLoadingDialog = null;
    }
    
    // ホワイトリストに含まれていないドメインを開こうとした場合、ブラウザで開きます。
    private boolean handleExternalDomainUrl(String url) {
        Uri uri = Uri.parse(url);
        String host = uri.getHost();
        if (mDomainWhiteList.containsHost(host)) {
            return false;
        }

        // No match - Sending Intent to External Browser
        if ("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme())) {
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            intent.addCategory(Intent.CATEGORY_BROWSABLE);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (getContext() instanceof Activity) {
                getContext().startActivity(intent);
            }
        }
        return true;
    }

    private class MyWebViewClient extends MobageWebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView webView, String url) {
            boolean handled = super.shouldOverrideUrlLoading(webView, url);
            if (handled) {
                return true;
            }
            Uri uri = Uri.parse(url);
            // "file:" スキーマが指定された場合、セキュリティのため読み込みを中止します。
            if ("file".equalsIgnoreCase(uri.getScheme())) {
                webView.loadUrl("about:blank");
                Log.w(TAG, "Prevented loading file URL: " + url);
                return true;
            }
            // ホワイトリストに含まれていないドメインを開こうとした場合、ブラウザで開きます。
            if (handleExternalDomainUrl(url)) {
                Log.w(TAG, "Prevented loading external URL: " + url);
                return true;
            }
            return false;
        }

        @Override
        public void onLoadResource(WebView webView, String url) {
            super.onLoadResource(webView, url);
            Uri uri = Uri.parse(url);
            // "file:" スキーマが指定された場合、セキュリティのため読み込みを中止します。
            if ("file".equalsIgnoreCase(uri.getScheme())) {
                webView.loadUrl("about:blank");
                Log.w(TAG, "Prevented loading file URL: " + url);
            }
        }

        @Override
        public void onPageStarted(WebView webView, String url, Bitmap favicon) {
            super.onPageStarted(webView, url, favicon);
            showLoadingDialog();
        }
        
        @Override
        public void onPageFinished(WebView webView, String url) {
            super.onPageFinished(webView, url);
            dismissLoadingDialog();
            if (mNavigationListener != null) {
                mNavigationListener.onPageFinished(webView, url);
            }
        }

        @Override
        public void onReceivedError(WebView webView, int errorCode, String description, String failingUrl) {
            super.onReceivedError(webView, errorCode, description, failingUrl);
            dismissLoadingDialog();
            if (mNavigationListener != null) {
                mNavigationListener.onReceivedError(webView, errorCode, description, failingUrl);
            }
        }
    }
    
    public static interface NavigationListener {
        public void onPageFinished(WebView webView, String url);
        public void onReceivedError(WebView webView, int errorCode, String description, String failingUrl);
    }
}
