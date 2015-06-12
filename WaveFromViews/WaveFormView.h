//
//  WaveFormView.h
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WaveEditViewController.h"
#import "Defines.h"
#import "Utils.h"

//----------------------------------------------------------------
typedef struct {
	int		x;		// 範囲 : 0〜WAVE_BUFFER_SIZE
	double	y;		// 範囲 : -1〜1
} WaveBufferOne;

@interface WaveFormView : UIView
{
	CGPoint			lastTouchPoint;
	WaveBufferOne	lastOne;
	
}

@property (nonatomic)	double *waveBuffer;

- (void)setWaveBuffer:(double *)buffer;
- (double *)getWaveBuffer;
- (void)setWaveFormRect:(CGRect)rect;

@end
