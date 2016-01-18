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

#import "MSSSASoundAssets.h"

@interface MSSSASoundAssets()

@property (nonatomic, strong) NSMutableDictionary *soundMap;

@end

/**
 * サウンド再生用のアセットを登録します。
 *
 * ここで登録した名前でサウンドの再生を指示することができます。
 */
@implementation MSSSASoundAssets

- (instancetype)init
{
    self = [super init];
    if (self) {
        _soundMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)getInstance
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

/**
 * 指定された path 以下のサウンドアセットを全て登録します。
 *
 * アセットは拡張子を除いた名前で登録されます。
 *
 * @param path パス名。
 *
 */
- (void)addAllFilesFromPath:(NSString *)path
{
    // Recursively enumerating files in a directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *soundURL = [NSURL URLWithString:path];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:soundURL
                                          includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        errorHandler:^BOOL(NSURL *url, NSError *error)
    {
        if (error) {
            NSLog(@"[addAllFilesFromBundle] error %@ (%@)", error, url);
            return NO;
        }
        return YES;
    }];

    for (NSURL *fileURL in enumerator) {
        NSString *fileName;
        [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];

        NSNumber *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];

        if (![isDirectory boolValue]) {
            fileName = [[fileName lastPathComponent] stringByDeletingPathExtension];
            [self addSound:fileName path:[fileURL path]];
        }
    }

}

-(void)addSound:(NSString *)soundName ofType:(NSString *)ext
{
    NSBundle *resBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"res" ofType:@"bundle"]];
    NSBundle *rawBundle = [NSBundle bundleWithPath:[resBundle pathForResource:@"raw" ofType:@"bundle"]];
    NSString *fileName = [rawBundle pathForResource:soundName ofType:ext];
    _soundMap[soundName] = fileName;
}

/**
 * サウンド再生用のアセットを登録します。
 *
 * @param soundName リソースを識別する名前。
 * @param filePath リソースのパス。
 */
- (void)addSound:(NSString *)soundName path:(NSString *)filePath
{
    _soundMap[soundName] = filePath;
}

- (NSString *)getSoundByName:(NSString *)soundName
{
    return _soundMap[soundName];
}


@end
