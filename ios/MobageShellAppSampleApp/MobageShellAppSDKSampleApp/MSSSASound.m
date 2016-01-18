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

#import "MSSSASound.h"
#import "MSSSAAudioEngine.h"

/**
 * サウンド(ミュージック、SE)の再生を行うクラスです。
 */
@implementation MSSSASound
static MSSSASound *sharedInstance_ = nil;

- (id)init
{
    self = [super init];
    if (self) {
        // TODO
    }
    return self;
}

- (void)dealloc
{
    [MSSSAAudioEngine end];
}

+ (MSSSASound*) getInstance
{
    if(!sharedInstance_) {
        sharedInstance_ = [[self alloc] init];
    }

    return sharedInstance_;
}

/**
 * SEを再生します。
 *
 * @param soundName サウンドファイルの名前。名前は予め MSSSASoundAssets に登録しておく必要があります。
 */
-(void)playSE:(NSString*) soundId
{
    NSString *resPath = [[MSSSASoundAssets getInstance] getSoundByName:soundId];
    [[MSSSAAudioEngine sharedEngine] playEffect:resPath];
}

/**
 * ミュージックを再生します。
 *
 * @param musicName    サウンドファイルの名前。名前は予め MSSSASoundAssets に登録しておく必要があります。
 * @param fadeDuration ミュージックが切り替わる際のフェードの長さ(秒)。0 の場合はフェードしません。
 * @param loopCount    ループ再生する回数。-1 の場合は無限ループします。
 */
-(void)playMusic:(NSString*) musicName fadeDuration:(float)fadeDuration loopCount:(int)loopCount
{
    NSString *resPath = [[MSSSASoundAssets getInstance] getSoundByName:musicName];
    if(resPath == nil){
        NSLog(@"music file for %@ is missing", musicName);
        return;
    }
    [[MSSSAAudioEngine sharedEngine] playBackgroundMusic:resPath fadeDuration:(float)fadeDuration loopCount:loopCount];
}

/**
 * ミュージックを停止します。
 *
 * @param fadeDuration ミュージックが切り替わる際のフェードの長さ(秒)。0 の場合はフェードしません。
 */
-(void)stopMusic:(float)fadeDuration
{
    [[MSSSAAudioEngine sharedEngine] stopBackgroundMusic:fadeDuration];
}

/**
 * 再生中のミュージックを一時停止します。
 */
-(void)pauseMusic
{
    [[MSSSAAudioEngine sharedEngine] pauseBackgroundMusic];
}

/**
 * 一時停止中のミュージックを再生します。
 */
-(void)resumeMusic
{
    [[MSSSAAudioEngine sharedEngine] resumeBackgroundMusic];
}

@end

