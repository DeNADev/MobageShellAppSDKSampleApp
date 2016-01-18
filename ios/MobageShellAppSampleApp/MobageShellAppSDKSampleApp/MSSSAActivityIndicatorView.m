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

#import <QuartzCore/QuartzCore.h>
#import "MSSSAActivityIndicatorView.h"

static const int kSpinnerBackgroundSize = 40;

/**
 * 読み込み中プログレス表示を行うViewです。
 */
@implementation MSSSAActivityIndicatorView

@synthesize spinner = _spinner;

- (id)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f];
        self.layer.cornerRadius = 4;
        self.clipsToBounds = true;
        self.hidden = YES;

        _spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(8, 8, 24, 24)];
        _spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [self addSubview:_spinner];
    }
    return self;
}

- (void)setCenter:(CGPoint)center
{
    self.frame = CGRectMake(0, 0, kSpinnerBackgroundSize, kSpinnerBackgroundSize);
    super.center = center;
}

- (void)startAnimating
{
    self.hidden = NO;
    [self.spinner startAnimating];
}

- (void)stopAnimating
{
    [self.spinner stopAnimating];
    self.hidden = YES;
}


@end
