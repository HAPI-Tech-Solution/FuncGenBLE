//
//  WaveScreenView.h
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Defines.h"
#import "Utils.h"
#import "WaveFormView.h"

//----------------------------------------------------------------

@interface WaveScreenView : UIView
{
	//CGRect			waveformScrollRect;
	//CGRect			waveformRect;

	WaveKind	waveKind;
}

@property (nonatomic, assign, setter=setWaveFormRect:)	CGRect	waveFormRect;


- (void)setWaveKind:(WaveKind)waveKind;
- (WaveKind)getWaveKind;


@end
