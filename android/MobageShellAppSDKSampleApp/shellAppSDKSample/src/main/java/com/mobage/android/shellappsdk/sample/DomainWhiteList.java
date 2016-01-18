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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import android.content.Context;

/**
 * WebView で表示するサイトのドメインのホワイトリストです。
 *
 * セキュリティのため、ゲームの WebView 内で表示されるサイトのドメインを制限します。
 *
 * リストは res/values/domain_white_list.xml から読み込みます。
 */
public class DomainWhiteList {
    private static DomainWhiteList sInstance;
    
    private List<String> mWhiteDomains;
    
    private DomainWhiteList(Context context) {
        mWhiteDomains = new ArrayList<String>();
        String[] domains = context.getResources().getStringArray(Res.array("domain_white_list"));
        mWhiteDomains.addAll(Arrays.asList(domains));
    }

    public static DomainWhiteList getInstance(Context context) {
        if(sInstance == null) {
            sInstance = new DomainWhiteList(context);
        }
        return sInstance;
    }
    
    /**
     * 指定されたホストをホワイトリストの先頭に追加します。
     * 
     * @param host ホスト名。
     */
    public void insert(String host) {
        mWhiteDomains.remove(host);
        mWhiteDomains.add(0, host);
    }
    
    /**
     * 指定されたホストがホワイトリストに含まれているかどうかを返します。
     *
     * @param host ホスト名。
     * @return host がホワイトリストに含まれていれば true。host がホワイトリスト内のドメインのサブドメインの場合も true を返します。
     */
    public boolean containsHost(String host) {
        if (host == null) {
            return false;
        }

        for (String domain : mWhiteDomains) {
            if (domain.startsWith(".")) {
                if (host.endsWith(domain)) {
                    return true;  // Backward match by domain - skip and render the site
                }
            } else {
                if (host.equals(domain)) {
                    return true;  // Coincident - skip and render the site
                }
                String dotDomain = "." + domain;
                if(host.endsWith(dotDomain)) {
                    return true;  // Backward match by domain - skip and render the site
                }
            }
        }

        return false;
    }
}
