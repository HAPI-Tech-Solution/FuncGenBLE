//
//  FrequencyTuneView.h
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Defines.h"
#import "Utils.h"

//----------------------------------------------------------------

@protocol FrequencyTuneViewDelegate <NSObject>
- (void)didChangeValue:(int32_t)value;
- (void)didClose;
@end

//----------------------------------------------------------------

@interface FrequencyTuneView : UIView <UIPickerViewDelegate, UIPickerViewDataSource>
{
	UIPickerView	*khzPickerView;
	UIPickerView	*hzPickerView;
}

@property	uint32_t frequency;

@property (nonatomic, assign) id<FrequencyTuneViewDelegate> delegate;

@end
