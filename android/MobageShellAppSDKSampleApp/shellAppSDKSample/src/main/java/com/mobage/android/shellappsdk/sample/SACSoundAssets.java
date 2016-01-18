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

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

/**
 * サウンド再生用のアセットを登録します。
 * 
 * ここで登録した名前でサウンドの再生を指示することができます。
 */
public class SACSoundAssets {
    private static final String TAG = "SACSoundAssets";
    
    private static SACSoundAssets sInstance;
    
    private Context mAppContext;
    private Map<String,String> mEntries = new HashMap<String, String>();
    
    private SACSoundAssets(Context context) {
        mAppContext = context.getApplicationContext();
    }

    public static SACSoundAssets getInstance(Context context) {
        if(sInstance == null) {
            sInstance = new SACSoundAssets(context);
        }
        return sInstance;
    }
    
    /**
     * APK内の assets に含まれるサウンドアセットを全て登録します。
     * 
     * アセットは拡張子を除いた名前で登録されます。
     * 
     * @param dir  assets/ 以下のサブディレクトリの名前。
     */
    public void addAllFilesFromAsssets(String dir) {
        AssetManager assetManager = mAppContext.getAssets();
        String[] list;
        try {
            list = assetManager.list(dir);
        } catch (IOException e) {
            Log.e(TAG, "addAllFilesFromAsssets: Failed to list assets", e);
            return;
        }
        if (list == null) {
            return;
        }
        for (String name : list) {
            String url = "file:///android_asset/" + dir + "/" + name;
            String baseName = SACUtils.stripExtensionFromFileName(name);
            add(baseName, url);
        }
    }

    /**
     * サウンド再生用のアセットを登録します。
     * 
     * @param name リソースを識別する名前。
     * @param uri リソースのURI。
     *             APK内の assets の場合 "file:///android_asset/path/music.ogg"
     *             APK内の res/raw の場合 "android.resource://{package_name}/{resource_id}"
     */
    public void add(String name, String uri) {
        mEntries.put(name, uri);
    }
    
    String get(String name) {
        return mEntries.get(name);
    }
}
