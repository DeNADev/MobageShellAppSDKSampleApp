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
import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;
import android.os.Handler;
import android.util.Log;

/**
 * サウンド(ミュージック、SE)の再生を行うクラスです。 
 */
public class SACSound implements MediaPlayer.OnCompletionListener, SoundPool.OnLoadCompleteListener {
    private static enum FADE_STAT { RESET, FADEIN_START, FADEIN, FADEOUT, PAUSE, RESUME };
    private static enum STAT { STOP, PLAY, PAUSE, DEEP_PAUSE };

    private static final String TAG = "SACSound";
    private static final int SOUNDEFFECT_MAX = 100;
    private static final int REPEAT_INTERVAL = 100; // milliseconds.    
    private static final Float VOLUME_DEFAULT = 1.0f;
    private static final Float VOLUME_MINIMUM = 0.0f;
    private static final Float TIME_IMMIDIATE_CAP = 0.1f;
    
    private int loopCounter = 0;
    private SACSoundAssets soundAssets;
    private Map<String,SoundEntry> soundMap = new HashMap<String,SoundEntry>();
    private static SoundPool soundPoolSE;
    private static SACSound shellAppSound = null;
    private Context context;
    
    private static Handler handler = new Handler();
    private static Runnable runnable = null;
    private static boolean wasPlayedBeforeDeepPause = false;
    private static PlaySet nowPlayingMusic = null;
    private static PlaySet nextMusic = null;
    private static FADE_STAT fadeStat = FADE_STAT.RESET;
    private static FADE_STAT lastFadeStat = FADE_STAT.RESET;
    private static STAT stat = STAT.STOP;
    private static Float runnableDuration = 0.1f;
    private static MediaPlayer mp;
    private static AudioManager.OnAudioFocusChangeListener afChangeListener;
    private static boolean holdingAudioFocus = false;

    public class PlaySet {
        String musicName = null;
        Float duration = 0.0f;
        int loopTimes = 0;
        PlaySet(String musicName, Float duration, int loopTimes) {
            this.musicName = musicName;
            this.duration = duration;
            this.loopTimes = loopTimes;
        }
    }
    
    private class SoundEntry {
        public static final int STATE_UNLOADED = 0;
        public static final int STATE_LOADING  = 1;
        public static final int STATE_LOADED   = 2;
        public String uri;
        public int state;
        public int poolId;
        public SoundEntry(String uri) {
            this.uri = uri;
            this.state = STATE_UNLOADED;
            this.poolId = -1;
        }
    }

    private SACSound(Context context) {
        this.context = context.getApplicationContext();
        if (mp == null) {
            mp = new MediaPlayer();
        }
        runnable = new RunnableFade();
        soundAssets = SACSoundAssets.getInstance(context);
    }
    
    public static SACSound getInstance(Context context) {
        if(shellAppSound == null) {
            shellAppSound = new SACSound(context);
        }
        return shellAppSound;
    }
    
    /**
     * SEを再生します。
     * 
     * @param soundName サウンドファイルの名前。名前は予め SACSoundAssets に登録しておく必要があります。
     */
    public void playSE(String soundName) {
        if(soundPoolSE == null) {
            soundPoolSE = new SoundPool(SOUNDEFFECT_MAX, AudioManager.STREAM_MUSIC, 0);
            soundPoolSE.setOnLoadCompleteListener(this);
        }

        SoundEntry entry = lookupSE(soundName);
        if(entry != null) {
            switch (entry.state) {
            case SoundEntry.STATE_UNLOADED:
                loadSE(entry);
                break;
            case SoundEntry.STATE_LOADING:
                break;
            case SoundEntry.STATE_LOADED:
                soundPoolSE.play(entry.poolId, VOLUME_DEFAULT, VOLUME_DEFAULT, 0, 0, 1.0F);
                break;
            }
        }
    }
    
    private SoundEntry lookupSE(String soundName) {
        SoundEntry entry = soundMap.get(soundName);
        if (entry == null) {
            String uri = soundAssets.get(soundName);
            if (uri == null) {
                Log.e(TAG, "lookupSE: sound name is not registered: " + soundName);
                return null;
            }
            entry = new SoundEntry(uri);
            soundMap.put(soundName, entry);
        }
        return entry;
    }
    
    private void loadSE(SoundEntry entry) {
        final String androidAssetPrefix = "file:///android_asset/";
        final String resourcePrefix = "android.resource://" + context.getPackageName() + "/";
        if (entry.uri.startsWith(androidAssetPrefix)) {
            String path = entry.uri.substring(androidAssetPrefix.length());
            entry.poolId = loadSEFromAssets(path);
            if (entry.poolId != -1) {
                entry.state = SoundEntry.STATE_LOADING;
            }
        } else if (entry.uri.startsWith(resourcePrefix)) {
            int resId = Integer.parseInt(entry.uri.substring(resourcePrefix.length()));
            entry.poolId = soundPoolSE.load(context, resId, 1);
            entry.state = SoundEntry.STATE_LOADING;
        } else if (entry.uri.startsWith("file://")) {
            String path = entry.uri.substring("file://".length());
            entry.poolId = soundPoolSE.load(path, 1);
            entry.state = SoundEntry.STATE_LOADING;
        } else {
            String path = entry.uri;
            entry.poolId = soundPoolSE.load(path, 1);
            entry.state = SoundEntry.STATE_LOADING;
        }
    }
    
    private int loadSEFromAssets(String path) {
        try {
            AssetFileDescriptor fd = context.getAssets().openFd(path);
            int poolId = soundPoolSE.load(fd, 1);
            fd.close();
            return poolId;
        } catch (IOException e) {
            Log.e(TAG, "loadSEFromAssets: Failed to load asset: " + path, e);
            return -1;
        }
    }
    
    @Override
    public void onLoadComplete(SoundPool soundPool, int poolId, int status) {
        SoundEntry entry = null;
        // linear search here for at most 100 entries
        for (SoundEntry e : soundMap.values()) {
            if (e.poolId == poolId) {
                entry = e;
                break;
            }
        }
        if (entry != null && entry.state == SoundEntry.STATE_LOADING) {
            if (status == 0) {
                entry.state = SoundEntry.STATE_LOADED;
                soundPoolSE.play(poolId, VOLUME_DEFAULT, VOLUME_DEFAULT, 0, 0, 1.0F);
            } else {
                Log.e(TAG, "onLoadComplete: failed to load sound effect: status=" + status);
                entry.state = SoundEntry.STATE_UNLOADED;
            }
        }
    }
    
    /**
     * ミュージックを再生します。
     *
     * @param musicName サウンドファイルの名前。名前は予め SACSoundAssets に登録しておく必要があります。
     * @param duration  ミュージックが切り替わる際のフェードの長さ(秒)。0 の場合はフェードしません。
     * @param loopTimes ループ再生する回数。-1 の場合は無限ループします。
     */
    public synchronized void playMusic(String musicName, Float duration, int loopTimes) {
        switch(stat) {
        case PAUSE:
            stopImmidate();
        case STOP:
            if (soundAssets.get(musicName) != null) {
                nowPlayingMusic = new PlaySet(musicName, duration, loopTimes);
                if(duration >= TIME_IMMIDIATE_CAP) { // Fade on
                    runnableDuration = duration;
                    volumeSliderAndMusicChanger(FADE_STAT.FADEIN_START);
                } else {
                    volumeSliderAndMusicChanger(FADE_STAT.RESET);
                }
                startImmidiate(nowPlayingMusic);
                stat = STAT.PLAY;
            }
            break;
        case PLAY:
            if(nowPlayingMusic != null && musicName.equals(nowPlayingMusic.musicName)) break;
            if (soundAssets.get(musicName) != null) {
                if(duration >= TIME_IMMIDIATE_CAP) { // Fade out and Change music
                    nextMusic = new PlaySet(musicName, duration, loopTimes);
                    volumeSliderAndMusicChanger(FADE_STAT.FADEOUT);
                } else { // play immediate
                    volumeSliderAndMusicChanger(FADE_STAT.RESET);
                    nowPlayingMusic = new PlaySet(musicName, duration, loopTimes);
                    stopImmidate();
                    startImmidiate(nowPlayingMusic);
                }
                stat = STAT.PLAY;
            } else {
                stopMusic(duration);
            }
            break;
        case DEEP_PAUSE:
            if (soundAssets.get(musicName) != null) {
                stopImmidate();
                nowPlayingMusic = new PlaySet(musicName, duration, loopTimes);
                if(duration >= TIME_IMMIDIATE_CAP) { // Fade on
                    runnableDuration = duration;
                    volumeSliderAndMusicChanger(FADE_STAT.FADEIN_START);
                } else {
                    volumeSliderAndMusicChanger(FADE_STAT.RESET);
                }
                startImmidiate(nowPlayingMusic);
                pauseImmidate();
                stat = STAT.DEEP_PAUSE;
            } else {
                stopMusic(duration);
            }
            break;
        default:
            break;
        }
    }
    
    /**
     * ミュージックを停止します。
     * 
     * @param duration  ミュージックが切り替わる際のフェードの長さ(秒)。0 の場合はフェードしません。
     */
    public synchronized void stopMusic(Float duration) {
        switch(stat) {
        case PLAY:
            if(duration >= TIME_IMMIDIATE_CAP) { // Fade out and Change music
                runnableDuration = duration;
                volumeSliderAndMusicChanger(FADE_STAT.FADEOUT);
            } else {
                volumeSliderAndMusicChanger(FADE_STAT.RESET);
                stopImmidate();
                stat = STAT.STOP;
                nowPlayingMusic = null;
            }
            break;
        case DEEP_PAUSE:
        case PAUSE:
            stopImmidate();
        case STOP:
        default:
            volumeSliderAndMusicChanger(FADE_STAT.RESET);
            stat = STAT.STOP;
            nowPlayingMusic = null;
            break;
        }
        loopCounter = 0;
    }

    /**
     * 再生中のミュージックを一時停止します。
     */
    public synchronized void pauseMusic() {
        switch(stat) {
        case PLAY:
            volumeSliderAndMusicChanger(FADE_STAT.PAUSE);
            pauseImmidate();
            stat = STAT.PAUSE;
            break;
        case STOP:
        case DEEP_PAUSE:
        case PAUSE:
        default:
            // DO NOTHING.
            break;
        }
    }
    
    private synchronized void deepPauseMusic() {
        switch(stat) {
        case PLAY:
            volumeSliderAndMusicChanger(FADE_STAT.PAUSE);
            pauseImmidate();
            stat = STAT.DEEP_PAUSE;
            wasPlayedBeforeDeepPause = true;
            break;
        case STOP:
        case DEEP_PAUSE:
        case PAUSE:
        default:
            // DO NOTHING.
            break;
        }
    }
    
    /**
     * 一時停止中のミュージックを再生します。
     */
    public synchronized void resumeMusic() {
        switch(stat) {
        case PLAY:
        case STOP:
        case DEEP_PAUSE:
            // DO NOTHING.
            break;
        case PAUSE:
            volumeSliderAndMusicChanger(FADE_STAT.RESUME);
            resumeImmidate();
            stat = STAT.PLAY;
            break;
        default:
            break;
        }
        return;
    }

    private synchronized void deepResumeMusic() {
        switch(stat) {
        case PLAY:
        case STOP:
        case PAUSE:
            // DO NOTHING.
            break;
        case DEEP_PAUSE:
            if(wasPlayedBeforeDeepPause) {
                volumeSliderAndMusicChanger(FADE_STAT.RESUME);
                resumeImmidate();
                stat = STAT.PLAY;
            } else {
                stat = STAT.PAUSE;
            }
            wasPlayedBeforeDeepPause = false;
            break;
        default:
            break;
        }
        return;
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        if(!mp.isLooping()) { // Looping limited
            if(loopCounter >= nowPlayingMusic.loopTimes) {
                volumeSliderAndMusicChanger(FADE_STAT.RESET);
                loopCounter = 0;
                nowPlayingMusic = null;
                stopImmidate();
                stat = STAT.STOP;
            } else {
                loopCounter++;
                mp.start();
            }
        }
    }

    private void volumeSliderAndMusicChanger(FADE_STAT fs) {
        if(mp == null) {
            mp = new MediaPlayer();
        }
        switch(fs) {
        case RESET:
            mp.setVolume(VOLUME_DEFAULT, VOLUME_DEFAULT);
            handler.removeCallbacks(runnable);
            fadeStat = fs;
            runnable = new RunnableFade();
            break;
        case FADEIN_START:
        case FADEIN:
        case FADEOUT:
            fadeStat = fs;
            handler.postDelayed(runnable, REPEAT_INTERVAL);
            break;
        case PAUSE:
            lastFadeStat = fadeStat;
            fadeStat = fs;
            break;
        case RESUME:
            fadeStat = lastFadeStat;
            handler.postDelayed(runnable, REPEAT_INTERVAL);
            break;
        default:
            fadeStat = fs;
            break;
        }
    }

    private class RunnableFade implements Runnable {
        private Float tempVolume = VOLUME_DEFAULT;
        @Override
        public void run() {
            Float tmpFadeTime;
            switch (fadeStat) {
            case FADEIN_START:
                tempVolume = VOLUME_MINIMUM;
                fadeStat = FADE_STAT.FADEIN;
            case FADEIN:
                tmpFadeTime = nextMusic!=null?nowPlayingMusic.duration:runnableDuration;
                tempVolume += VOLUME_DEFAULT / ((tmpFadeTime * 1000) / REPEAT_INTERVAL );
                if(tempVolume <= VOLUME_DEFAULT) { // FadeIn Completed
                    mp.setVolume(tempVolume, tempVolume);
                    handler.postDelayed(this, REPEAT_INTERVAL);
                } else {
                    mp.setVolume(VOLUME_DEFAULT, VOLUME_DEFAULT);
                }
                break;
            case FADEOUT:
                tmpFadeTime = nextMusic!=null?nextMusic.duration:runnableDuration;
                tempVolume -= VOLUME_DEFAULT / ((tmpFadeTime * 1000) / REPEAT_INTERVAL );
                mp.setVolume(tempVolume, tempVolume);
                if(tempVolume <= VOLUME_MINIMUM) { // FadeOut Completed
                    tempVolume = 0.0f;
                    mp.setVolume(tempVolume, tempVolume);
                    stopImmidate();
                    if (nextMusic != null) {
                        nowPlayingMusic = nextMusic;
                        nextMusic = null;
                        runnableDuration = nowPlayingMusic.duration;
                        fadeStat = FADE_STAT.FADEIN_START;
                        handler.post(this);
                        startImmidiate(nowPlayingMusic);
                        stat = STAT.PLAY;
                    } else {
                        nowPlayingMusic = null;
                        stat = STAT.STOP;
                        tempVolume = VOLUME_DEFAULT;
                        handler.removeCallbacks(runnable);
                    }
                } else {
                    mp.setVolume(tempVolume, tempVolume);
                    handler.postDelayed(runnable, REPEAT_INTERVAL);
                }                   
                    
                break;
            case RESET:
                tempVolume = VOLUME_DEFAULT;
                mp.setVolume(tempVolume, tempVolume);
                break;
            case PAUSE:
            case RESUME:
            default:
                break;
            }
        }
    }
    
    // Low Layer Method
    private void stopImmidate() {
        if(mp != null) {
            mp.stop();
//          mp.seekTo(0);
            mp.setOnCompletionListener(null);
            mp.release();
            mp = null;
        }
    }
    
    private void startImmidiate(PlaySet playSet) {
        if (mp == null) {
            mp = new MediaPlayer();
            mp.setVolume(VOLUME_DEFAULT, VOLUME_DEFAULT);
        }
        String uri = soundAssets.get(playSet.musicName);
        try {
            final String androidAssetPrefix = "file:///android_asset/";
            if (uri.startsWith(androidAssetPrefix)) {
                String path = uri.substring(androidAssetPrefix.length());
                AssetFileDescriptor fd = context.getAssets().openFd(path); 
                mp.setDataSource(fd.getFileDescriptor(), fd.getStartOffset(), fd.getLength());
                fd.close();
            } else {
                mp.setDataSource(context, Uri.parse(uri));
            }
            mp.prepare();
            mp.setLooping(playSet.loopTimes==-1?true:false);
            if (!holdingAudioFocus) {
                holdingAudioFocus = true;
                requestAudioFocus();
            }
            mp.start();
            mp.setOnCompletionListener(this);
        } catch (Exception e) {
            Log.e(TAG, "startImmediate: Failed to play music: " + uri, e);
        }       
    }

    private void pauseImmidate() {
        mp.pause();
    }

    private void resumeImmidate() {
        mp.start();
    }
    
    static void release() {
        if(soundPoolSE != null) {
            soundPoolSE.release();
            soundPoolSE = null;
        }
    }

    public void onResume() {
        if (stat == STAT.STOP) {
            holdingAudioFocus = false;
            return;
        }
        if (holdingAudioFocus) {
            boolean result = requestAudioFocus();
            if (result) {
                deepResumeMusic();
            }
        }
    }

    public void onPause() {
        if (holdingAudioFocus) {
            deepPauseMusic();
            abandonAudioFocus();
        }
    }

    private boolean requestAudioFocus() {
        final AudioManager am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);

        if (afChangeListener == null) {
            afChangeListener = new AudioManager.OnAudioFocusChangeListener() {
                public void onAudioFocusChange(int focusChange) {
                    if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                        // Pause playback
                        deepPauseMusic();
                    } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                        // Resume playback
                        deepResumeMusic();
                    } else if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
                        am.abandonAudioFocus(afChangeListener);
                        // Stop playback
                        deepPauseMusic();
                    }
                }
            };
        }
       
        int result = am.requestAudioFocus(afChangeListener,
                                          AudioManager.STREAM_MUSIC,
                                          AudioManager.AUDIOFOCUS_GAIN);
        return (result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED);
    }

    private void abandonAudioFocus() {
        AudioManager am = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        am.abandonAudioFocus(afChangeListener);
    }
}
