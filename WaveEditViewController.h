//
//  WaveEditViewController.h
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FGController.h"

@class WaveScreenView;
@class WaveFormView;
@class FrequencyTuneView;


@interface WaveEditViewController : UIViewController
{
	FGController	*fgController;

	FrequencyTuneView	*frequencyTuneView;
	
	CGRect		waveformScrollRect;
	CGRect		waveformRect;

	WaveScreenView	*waveScreenView;
	UIScrollView	*waveFormScrollView;
	WaveFormView	*waveFormView;
	
	UIActivityIndicatorView	*bleAccessActivityIndicatorView;
	
	uint32_t		frequency;
}

//----------------------------------------------------------------

@end
