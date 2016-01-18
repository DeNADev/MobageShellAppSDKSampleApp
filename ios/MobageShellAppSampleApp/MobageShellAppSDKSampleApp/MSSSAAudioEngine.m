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

#import "MSSSAAudioEngine.h"

#define FADE_SEED 0.01f
#define SEQUENCE_INTERVAL 0.5f
#define DECREASING_VOLUME_RATE 0.3f

typedef enum AUDIO_FADESTATE
{
    AUDIO_FADERESET = 0,
    AUDIO_FADEIN,
    AUDIO_FADEOUT,
    AUDIO_FADESTATEMAX
} AudioFadeState;

typedef enum AUDIO_PLAYSTATE
{
    AUDIO_STOP = 0,
    AUDIO_STOPPING,
    AUDIO_PLAY,
    AUDIO_STATEMAX
} AudioPlayState;

@interface MSSSAAudioEngine() {
    NSMutableDictionary *_soundEffects;

    AVAudioPlayer *_playerForMusic;
    AVAudioPlayer *_playerForSE;

    NSString*	_currentPlayerPath;
    float		_currentVolume;

    NSString*	_nextPlayerPath;
    float		_nextPlayerFadeTime;
    int			_nextPlayerLoopCount;

    float		_fadeSeedVolume;

    BOOL		_pauseFlag;
    BOOL		_pausedBeforeInterruption;

    NSTimer*	_fadeTimer;

    AudioFadeState _fadeState;
    AudioPlayState _playState;

    float _lastVolumeLevel;
}
@end

/**
 * サウンド(ミュージック、SE)の再生を行うクラスの実装です。
 */
@implementation MSSSAAudioEngine

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _soundEffects = [[NSMutableDictionary alloc] init];
    _playState = AUDIO_STOP;
    _fadeState = AUDIO_FADERESET;
    _pauseFlag = NO;
    _nextPlayerFadeTime = 0.0;
    _nextPlayerLoopCount = -1;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    [audioSession setActive:YES error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAudioSessionInterruptNotification:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:nil];
    _playerForMusic = nil;
    _currentPlayerPath = nil;
    _nextPlayerPath = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}


static MSSSAAudioEngine* _instance = nil;
+ (MSSSAAudioEngine*)sharedEngine
{
    @synchronized(self) {
        if (!_instance) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (void)preloadEffect:(NSString*)filePath
{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    _soundEffects[filePath] = data;
}

- (void)playBackgroundMusic:(NSString*)filePath fadeDuration:(float)fadeDuration loopCount:(int)loopCount
{
    NSLog(@"PLAY PATH = %@", filePath);
    
    [self audioPlay:filePath fadeTime:fadeDuration currentTime: 0.0 loopCount:loopCount ];
}

- (void)playEffect:(NSString*)filePath
{
    if (filePath == nil) {
        NSLog(@"filePath is required when playing sound effect");
        return;
    }
    
    NSData* data = _soundEffects[filePath];
    if (!data) {
        NSLog(@"loaded from file");
        data = [NSData dataWithContentsOfFile:filePath];
        _soundEffects[filePath] = data;
    } else {
        NSLog(@"loaded from cache");
    }

    NSError* error = nil;
    _playerForSE = [[AVAudioPlayer alloc] initWithData:data error:&error];
    if (error) {
        NSLog(@"failed to initialize audio player for %@", filePath);
        return;
    }
    _playerForSE.numberOfLoops = 0;
    [_playerForSE prepareToPlay];
    [_playerForSE play];
}

- (void)stopBackgroundMusic:(float)fadeDuration
{
    NSLog(@"STOP");

    // 明示的にストップが呼ばれたので
    // 次のファイルが格納されていてもリセットする
    if (_nextPlayerPath != nil) {
        _nextPlayerPath = nil;
    }
    
    @synchronized(self) {
        [self audioStop:fadeDuration];
    }
}

- (void)pauseBackgroundMusic
{
    NSLog(@"PAUSE");
    
    if (!_playerForMusic) {
        return;
    }
    
    @synchronized(self) {
        if (_pauseFlag == NO) {
            _pauseFlag = YES;
            [_playerForMusic pause];
        }
    }
}

- (void)resumeBackgroundMusic
{
    if(_playerForMusic == nil) {
        return;
    }
    
    @synchronized(self) {
        if (_pauseFlag == YES) {
            _pauseFlag = NO;
            if (_playState != AUDIO_STOPPING) {
                _playState = AUDIO_PLAY;
            }
            [_playerForMusic play];
        }
    }
}

- (void)audioPlay:(NSString*)path
         fadeTime:(float)fadeTime
      currentTime:(double)currentTime
        loopCount:(int)loopCount
{
    
    @synchronized(self) {
        
        // パスが同じだったら再生しない
        if ([path isEqualToString: _currentPlayerPath] && _pauseFlag == NO) {
            return;
        }
        
        // 再生中や再生停止中の場合、次の音声ファイルをスタンバる
        if (_playState == AUDIO_PLAY || _playState == AUDIO_STOPPING) {
            // もし既に存在していたら入れ替えるために解放
            if (_nextPlayerPath != nil) {
                _nextPlayerPath = nil;
            }
            _nextPlayerPath = [[NSString alloc] initWithString: path];
            _nextPlayerFadeTime = fadeTime;
            _nextPlayerLoopCount = loopCount;
        }
        
        if (_playState == AUDIO_PLAY && _pauseFlag == YES) {
            _pauseFlag = NO;
            [self audioStop : 0.0];
            return;
        } else if (_playState == AUDIO_PLAY && _pauseFlag == NO) {
            [self audioStop : fadeTime];
            return;
        } else if (_playState == AUDIO_STOPPING && _pauseFlag == YES) {
            _pauseFlag = NO;
            [self audioStop : 0.0];
            return;
        } else if (_playState == AUDIO_STOPPING && _pauseFlag == NO) {
            if (fadeTime == 0.0) {
                [self audioStop : 0.0];
            }
            return;
        } else if (_playState == AUDIO_STOP) {
            _pauseFlag = NO;
            if (_playerForMusic != nil) {
                _playerForMusic = nil;
            }
            
            _currentPlayerPath = [[NSString alloc] initWithString: path];
            _playState = AUDIO_PLAY;
            // 初期化
            NSError* error = nil;
            _playerForMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:&error];
            if (error) {
                NSLog(@"failed to initialize audio player for %@", path);
            }
            _playerForMusic.meteringEnabled = YES;
            _playerForMusic.numberOfLoops = loopCount;
            _playerForMusic.delegate = self;
            _currentVolume = _playerForMusic.volume;
            _fadeState = AUDIO_FADERESET;
            _playState = AUDIO_STOP;
            _fadeSeedVolume = 0.0;
            _pauseFlag = NO;
        }
        
        
        if (_playerForMusic.playing) {
            return;
        }
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
        [audioSession setActive:YES error:nil];
        
        // Fade中のボリュームは信用しない
        if (_fadeState == AUDIO_FADERESET) {
            _currentVolume = _playerForMusic.volume;
        }
        
        // シークごとのボリューム増減値の計算
        _fadeSeedVolume = _currentVolume / (fadeTime / FADE_SEED);
        
        // 再生ステータスの変更
        _playState = AUDIO_PLAY;
        
        // フェード時間が設定されていたら
        if (fadeTime > 0.0) {
            if(_fadeTimer.isValid) {
                [_fadeTimer invalidate];
                _fadeTimer = nil;
                _fadeState = AUDIO_FADERESET;
            }
            
            if(_fadeState == AUDIO_FADERESET) {
                // フェードリセット状態の場合
                _playerForMusic.volume = 0.0f;
                _fadeTimer = [NSTimer scheduledTimerWithTimeInterval:FADE_SEED
                                                              target:self
                                                            selector:@selector(audioFadein)
                                                            userInfo:nil
                                                             repeats:YES];
            } else if(_fadeState == AUDIO_FADEOUT) {
                // フェードアウト中の場合
                _fadeTimer = [NSTimer scheduledTimerWithTimeInterval:FADE_SEED
                                                              target:self
                                                            selector:@selector(audioFadein)
                                                            userInfo:nil
                                                             repeats:YES];
            }
        }
        _playerForMusic.currentTime = currentTime;
        
        
        [_playerForMusic prepareToPlay];
        [_playerForMusic play];
    }
}

// 再生停止
- (void)audioStop:(float)fadeTime
{
    if (_playerForMusic == nil) {
        return;
    }
    
    @synchronized(self) {
        
        if (_playerForMusic != nil) {
            switch (_playState) {
                case AUDIO_STOPPING:
                case AUDIO_PLAY:
                    if (_pauseFlag == NO) {
                        _playState = AUDIO_STOPPING;
                    } else {
                        _playState = AUDIO_STOP;
                        fadeTime = 0.0;
                        _pauseFlag = NO;
                    }
                    break;
                    
                default:
                    break;
            }
        }
        
        
        // Fade中のボリュームは信用しない
        if (_fadeState == AUDIO_FADERESET) {
            _currentVolume = _playerForMusic.volume;
        }
        _fadeSeedVolume = _currentVolume / (fadeTime / FADE_SEED);
        
        if (fadeTime > 0.0) {
            if (_fadeTimer.isValid) {
                [_fadeTimer invalidate];
                _fadeTimer = nil;
                _fadeState = AUDIO_FADERESET; // Add.
            }
            
            if (_fadeState == AUDIO_FADERESET || _fadeState == AUDIO_FADEIN) {
                _fadeTimer = [NSTimer scheduledTimerWithTimeInterval:FADE_SEED
                                                              target:self
                                                            selector:@selector(audioFadeout)
                                                            userInfo:nil
                                                             repeats:YES];
            }
        } else {
            // 再生中、ポーズ中に音声再生を即停止する
            if (_playerForMusic != nil) {
                // タイマーが設定されていたら停止する。
                if (_fadeTimer.isValid) {
                    [_fadeTimer invalidate];
                    _fadeTimer = nil;
                    _fadeState = AUDIO_FADERESET;
                }
                _playState = AUDIO_STOP;
                _fadeState = AUDIO_FADERESET;
                
                [_playerForMusic stop];
                _playerForMusic.currentTime = 0.0f;
                
                // 再生終了処理
                if (_playerForMusic != nil) {
                    _playerForMusic = nil;
                }
                
                _currentPlayerPath = nil;
                
                // 次に再生すべきものがある場合
                if (_nextPlayerPath != nil) {
                    NSString* path = [NSString stringWithString: _nextPlayerPath];
                    _nextPlayerPath = nil;
                    float fadeTime = _nextPlayerFadeTime;
                    int loopCount = _nextPlayerLoopCount;
                    _nextPlayerFadeTime = 0.0;
                    _nextPlayerLoopCount = 0;
                    [self playBackgroundMusic:path fadeDuration:fadeTime loopCount:loopCount];
                }
            }
        }
    }
}


-(void)audioFadein
{
    
    @synchronized(self) {
        if (_playerForMusic.playing) {
            if ((_playerForMusic.volume+_fadeSeedVolume) <= _currentVolume) {
                if (_fadeState == AUDIO_FADERESET) {
                    // フェードイン開始
                    _fadeState = AUDIO_FADEIN;
                }
                // PAUSEだったら一旦Fadeinをやめる。タイマーは死なない
                if (_pauseFlag == NO) {
                    // Fadein
                    _playerForMusic.volume = _playerForMusic.volume+_fadeSeedVolume;
                }
            } else {
                // フェードイン完了
                _fadeState = AUDIO_FADERESET;
                // タイマーを止める
                if (_fadeTimer.isValid) {
                    [_fadeTimer invalidate];
                    _fadeTimer = nil;				 }
            }
        }
    }
}

-(void)audioFadeout
{
    @synchronized(self) {
        if (_playerForMusic.volume <= 0.0f) {
            // フェードアウト完了
            _fadeState = AUDIO_FADERESET;
            // フェードアウトしきったので、即停止
            [self audioStop: 0.0];
        } else {
            if (_fadeState == AUDIO_FADERESET) {
                _fadeState = AUDIO_FADEOUT;
            }
            
            // PAUSEだったら一旦Fadeoutをやめる。タイマーは死なない
            if (_pauseFlag == NO) {
                // Fadeout
                _playerForMusic.volume = _playerForMusic.volume-_fadeSeedVolume;
            }
        }
    }
}

- (void) decreaseVolumeLevel {
    _lastVolumeLevel = _playerForMusic.volume;
    _playerForMusic.volume = _lastVolumeLevel * DECREASING_VOLUME_RATE;
}

- (void) restoreLastVolumeLevel {
    _playerForMusic.volume = _lastVolumeLevel;
}

+(void) end {
    _instance = nil;
}

#pragma mark AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSAssert([NSThread isMainThread], @"Not main thread");
    @synchronized(self) {
        // 再生終了処理
        if (_playerForMusic != nil) {
            _playState = AUDIO_STOP;
            _fadeState = AUDIO_FADERESET;
            _pauseFlag = NO;
            _currentPlayerPath = nil;
            _playerForMusic = nil;
        }
    }
}

#pragma mark AVAudioSessionDelegate

- (void) beginInterruption {
    NSLog(@"AVAudioSessionDelegate beginInterruption");
    _pausedBeforeInterruption = _pauseFlag;
    // pause sound if playing
    [self pauseBackgroundMusic];
}

- (void) endInterruptionWithFlags:(NSUInteger)flags {
    NSLog(@"AVAudioSessionDelegate endInterruptionWithFlags:ShouldResume=%d", !!(flags & AVAudioSessionInterruptionOptionShouldResume));
    if (flags & AVAudioSessionInterruptionOptionShouldResume) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:YES error:nil];
        if (!_pausedBeforeInterruption) {
            // resume sound if paused
            [self resumeBackgroundMusic];
        }
    }
}

#pragma mark - AVAudioSessionInterruptionNotification Observer
- (void)didAudioSessionInterruptNotification:(NSNotification *)notification {
    NSNumber *interruptionType = notification.userInfo[AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = notification.userInfo[AVAudioSessionInterruptionOptionKey];
    switch ([interruptionType integerValue]) {
        case AVAudioSessionInterruptionTypeBegan:
            NSLog(@"Interruption began");
            [self beginInterruption];
            break;
        case AVAudioSessionInterruptionTypeEnded:
        default:
            NSLog(@"Interruption ended");
            [self endInterruptionWithFlags:[interruptionOption unsignedIntegerValue]];
            break;
    }
}

@end

