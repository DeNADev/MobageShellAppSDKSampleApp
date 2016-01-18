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

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageButton;
import android.widget.RelativeLayout;

/**
 * アプリの画面下部に表示されるフッターです。
 * 
 *  res/layout/footer.xml にてレイアウトが定義されています。
 */
public class FooterView extends RelativeLayout {
    private ImageButton mBackButton;
    private ImageButton mReloadButton;
    private ImageButton mMenuButton;
    
    private GameWebView mWebView;

    public FooterView(Context context) {
        super(context);
        if (!isInEditMode()) {
            init(context);
        }
    }

    public FooterView(Context context, AttributeSet attrs) {
        super(context, attrs);
        if (!isInEditMode()) {
            init(context);
        }
    }

    public FooterView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        if (!isInEditMode()) {
            init(context);
        }
    }
    
    private void init(Context context) {
        LayoutInflater.from(context).inflate(Res.layout("footer"), this);
        
        mBackButton = (ImageButton)findViewById(Res.id("backButton"));
        mBackButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mWebView.goBack();
            }
        });
        mBackButton.setEnabled(false);
        
        mReloadButton = (ImageButton)findViewById(Res.id("reloadButton"));
        mReloadButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mWebView.reload();
            }
        });
        
        mMenuButton = (ImageButton)findViewById(Res.id("menuButton"));
        mMenuButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Webアプリケーション内の JavaScript を呼び出す例です。
                mWebView.loadUrl("javascript:app.menu.toggle();");
            }
        });
    }
    
    public void setWebView(GameWebView webView) {
        mWebView = webView;
    }
    
    public void updateBackButtonState() {
        boolean enabled = mWebView.canGoBack();
        mBackButton.setEnabled(enabled);
    }
}
