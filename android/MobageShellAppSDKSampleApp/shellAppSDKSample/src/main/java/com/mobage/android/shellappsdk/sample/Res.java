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

/**
 * アプリのパッケージ名に関係なくリソースにアクセスできるようにするためのユーティリティです。
 */
public class Res {
    public static int id(String name) {
        return getResourceIdentifier(name, "id");
    }
    
    public static int string(String name) {
        return getResourceIdentifier(name, "string");
    }
    
    public static int layout(String name) {
        return getResourceIdentifier(name, "layout");
    }
    
    public static int color(String name) {
        return getResourceIdentifier(name, "color");
    }
    
    public static int raw(String name) {
        return getResourceIdentifier(name, "raw");
    }

    public static int drawable(String name) {
        return getResourceIdentifier(name, "drawable");
    }

    public static int style(String name) {
        return getResourceIdentifier(name, "style");
    }

    public static int array(String name) {
        return getResourceIdentifier(name, "array");
    }
    
    private static int getResourceIdentifier(String name, String type) {
        GameApplication application = GameApplication.getInstance();
        return application.getResources().getIdentifier(name, type, application.getPackageName());
    }
}
