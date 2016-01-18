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

import com.mobage.android.shellappsdk.api.RemoteNotification;
import com.mobage.android.shellappsdk.api.RemoteNotificationClient;
import com.mobage.android.shellappsdk.api.RemoteNotificationPayload;

import android.app.Application;
import android.app.Notification;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * アプリケーションのプロセスに紐付いたクラスです。
 * 
 * onCreate() にて  RemoteNotification.setRemoteNotificationClient() を呼び出すことで
 * Remote Notification の挙動をカスタマイズすることができます。
 */
public class GameApplication extends Application {
    protected static final String TAG = "GameApplication";
    
    private static GameApplication sInstance;
    
    public GameApplication() {
        sInstance = this;
    }
    
    public static GameApplication getInstance() {
        return sInstance;
    }

    @Override
    public void onCreate() {
        RemoteNotification.setRemoteNotificationClient(new RemoteNotificationClient() {
            /**
             * アプリの Activity を含んだプロセスが起動していない場合でも、このメソッドで Remote Notification を
             * 受け取ることができます。
             *
             * またこのメソッドから true を返すことで、デフォルトのステータスバー通知や
             * setRemoteNotificationListener() にて設定したリスナーの呼び出しを抑制することができます。
             *
             * @param context Remote Notification 受信サービスが動作している context。
             * @param intent 受信した intent。
             */
            public boolean handleMessage(Context context, Intent intent) {
                RemoteNotificationPayload payload = RemoteNotification.extractPayloadFromIntent(intent);
                Log.i(TAG, "Received Remote Notification: " + payload);
                return false;    // ここで true を返した場合、デフォルトのステータスバー通知や setRemoteNotificationListener() にて設定したリスナーの呼び出しは行われません。
            }
            
            /**
             * Remote Notification のステータスバー通知をカスタマイズすることができます。
             * 
             * @param notification SDK が生成し、これから表示しようとする Notification インスタンス。
             * @param context Remote Notification 受信サービスが動作している context。
             * @param intent 受信した intent。
             */
            public void tweakNotification(Notification notification, Context context, Intent intent) {
                Log.i(TAG, "Tweaking Notification: " + notification);
//                notification.defaults |= Notification.DEFAULT_SOUND;
//                notification.vibrate = new long[]{0, 200, 100, 200, 100, 200};
            }
        });
    }

}
