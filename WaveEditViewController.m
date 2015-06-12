//
//  WaveEditViewController.m
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import "WaveEditViewController.h"
#import "WaveFromViews/WaveScreenView.h"
#import "FrequencyTuneView.h"

double	gWaveBuffer[WAVE_BUFFER_SIZE];		// val=-1〜1

//----------------------------------------------------------------


@interface WaveEditViewController () <UIScrollViewDelegate, FrequencyTuneViewDelegate>
	//<UIPickerViewDelegate, UIPickerViewDataSource, BLEAdvertisingDelegate, BLEPeripheralAccessDelegate>
//
@property (weak, nonatomic) IBOutlet UIButton *waveSineButton;
@property (weak, nonatomic) IBOutlet UIButton *waveSquareButton;
@property (weak, nonatomic) IBOutlet UIButton *waveTriangleButton;
@property (weak, nonatomic) IBOutlet UIButton *waveSawtoothButton;
@property (weak, nonatomic) IBOutlet UIButton *waveFreehandButton;
//
@property (weak, nonatomic) IBOutlet UIView *waveScreenParentView;	// waveformの親view
//@property (weak, nonatomic) IBOutlet UISlider *waveScaleSlider;

//
@property (weak, nonatomic) IBOutlet UIButton *sendWaveFormButton;
@property (weak, nonatomic) IBOutlet UIButton *outputButton;

@property (weak, nonatomic) IBOutlet UILabel *waveKindLabel;

@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UIButton *frequencyUpButton;
@property (weak, nonatomic) IBOutlet UIButton *frequencyDownButton;

@end

//----------------------------------------------------------------

@implementation WaveEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	frequency = 8333;		// 周波数初期値

	{
		_waveKindLabel.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.8];
		_waveKindLabel.textColor = [UIColor blueColor];
		_waveKindLabel.font = [UIFont fontWithName:@"AppleGothic" size:12];
		_waveKindLabel.textAlignment = UIBaselineAdjustmentAlignCenters;
		_waveKindLabel.text = @"Fixed";
	}
	
	fgController = [[FGController alloc] init];
	[fgController peripheralScanStart];
	
	// 波形フォーム設定
	{
		CGRect wspvFrame = _waveScreenParentView.frame;
		wspvFrame.origin.x = 0;
		wspvFrame.origin.y = 0;
		
		//_waveScreenParentView.backgroundColor = [UIColor clearColor];

		// 波形描画スクリーンView
		waveScreenView = [[WaveScreenView alloc] initWithFrame:wspvFrame];
		{
			waveScreenView.backgroundColor = [UIColor blackColor];
			waveScreenView.userInteractionEnabled = NO;
		}
		[_waveScreenParentView addSubview:waveScreenView];

	
		// ScrollView
		waveformScrollRect = CGRectMake(10, 10, wspvFrame.size.width - 20, wspvFrame.size.height - 20);
		waveFormScrollView = [[UIScrollView alloc] initWithFrame:waveformScrollRect];
		{
			waveFormScrollView.backgroundColor = [UIColor clearColor];
			waveFormScrollView.minimumZoomScale = 0.1;
			waveFormScrollView.maximumZoomScale = 1;
		}
		[waveScreenView addSubview:waveFormScrollView];

		
		// 波形表示View
		waveformRect = CGRectMake(0, 0, WAVE_BUFFER_SIZE, waveformScrollRect.size.height);
		waveFormView = [[WaveFormView alloc] initWithFrame:waveformRect];
		{
			waveFormView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
			[waveFormView setWaveBuffer:gWaveBuffer];
		}
		[waveFormScrollView addSubview:waveFormView];

		waveFormScrollView.contentSize = waveFormView.bounds.size;
		[waveFormScrollView flashScrollIndicators];

		
		// スケール設定
		[waveScreenView setWaveFormRect:waveformScrollRect];
	}
	
	// 周波数表示
	{
		[self updateFrequency];
		
		// 周波数設定ポップアップview
		frequencyTuneView = [[FrequencyTuneView alloc] initWithFrame:CGRectMake(100, 100, 180, 164)];
		{
			//frequencyTuneView.backgroundColor = [UIColor whiteColor];
			frequencyTuneView.hidden = YES;
			frequencyTuneView.delegate = self;
			frequencyTuneView.frequency = frequency;
		}
		[self.view addSubview:frequencyTuneView];
		[self.view bringSubviewToFront:frequencyTuneView];
		
	}
	
	// ボタン類
	{
		[_outputButton setImage:[UIImage imageNamed:@"008_00-wave_on"] forState:UIControlStateNormal];
		
	}

	
	bleAccessActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.frame];
	{
		bleAccessActivityIndicatorView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.6];
		bleAccessActivityIndicatorView.hidden = YES;
	}
	[self.view addSubview:bleAccessActivityIndicatorView];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// 
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	
}

//----------------------------------------------------------------
/*
- (IBAction)waveScaleSliderHandle:(id)sender {
	
	float val = _waveScaleSlider.value;
	//NSLog(@"waveScaleSlider: %f", val);
	
	CGRect f = waveScreenView.frame;
	f.size.width = (CGFloat)WAVE_BUFFER_SIZE * val;
	[waveScreenView setWaveFormRect:f];
	[waveScreenView setNeedsDisplay];

	f = waveFormView.frame;
	f.size.width = (CGFloat)WAVE_BUFFER_SIZE * val;
	[waveFormView setWaveFormRect:f];
	[waveFormView setNeedsDisplay];
		
}
*/

//----------------------------------------------------------------
//----------------------------------------------------------------
#pragma mark - 波形選択ボタンハンドル

- (IBAction)sineWaveButtonHandle:(id)sender {
	waveScreenView.userInteractionEnabled = NO;

	[self makeSineWave];
	_waveKindLabel.text = [Utils waveKindString:WaveKind_Sine];
	[self replaceBuffer];
}

- (IBAction)squareButtonHandle:(id)sender {
	waveScreenView.userInteractionEnabled = NO;

	[self makeSquareWave];
	_waveKindLabel.text = [Utils waveKindString:WaveKind_Square];
	[self replaceBuffer];
}

- (IBAction)triangeButtonHandle:(id)sender {
	waveScreenView.userInteractionEnabled = NO;

	[self makeTriangleWave];
	_waveKindLabel.text = [Utils waveKindString:WaveKind_Triangle];
	[self replaceBuffer];
}

- (IBAction)sawtoothButtonHandle:(id)sender {
	waveScreenView.userInteractionEnabled = NO;

	[self makeSawtoothWave];
	_waveKindLabel.text = [Utils waveKindString:WaveKind_Sawtooth];
	[self replaceBuffer];
}

- (IBAction)freehandButtonHandle:(id)sender {
	waveScreenView.userInteractionEnabled = YES;

	// 現在のwaveを利用
	_waveKindLabel.text = [Utils waveKindString:WaveKind_Freehand];
	[self replaceBuffer];
}

- (void)replaceBuffer
{
	[waveFormView setWaveBuffer:gWaveBuffer];
	[waveScreenView setNeedsDisplay];
	[waveFormScrollView setNeedsDisplay];
	[waveFormView setNeedsDisplay];
}

//----------------------------------------------------------------
//----------------------------------------------------------------
#pragma mark - 波形生成
/**
 * 波形生成
 */
- (void)waveBufferClear
{
	for (int i = 0; i < WAVE_BUFFER_SIZE; i++) {
		gWaveBuffer[i] = 0;
	}
}

- (void)makeSineWave
{
	for (int x = 0; x < WAVE_BUFFER_SIZE; x++) {
		double rad = (x * 360.0 / WAVE_BUFFER_SIZE) * M_PI / 180.0;
		gWaveBuffer[x] = sin(rad);
	}
}

- (void)makeSquareWave
{
	gWaveBuffer[0] = 0.0;
	for (int x = 1; x < WAVE_BUFFER_SIZE - 1; x++) {
		double y =  (x < (WAVE_BUFFER_SIZE / 2)) ? 1.0 : -1.0;
		gWaveBuffer[x] = y;
	}
	gWaveBuffer[WAVE_BUFFER_SIZE - 1] = 0.0;
}

- (void)makeTriangleWave
{
	double y = 0;
	double yPerOne = 1.0 / (WAVE_BUFFER_SIZE / 4);
	
	gWaveBuffer[0] = y;
	for (int x = 1; x < WAVE_BUFFER_SIZE; x++) {
		if (x < (WAVE_BUFFER_SIZE / 4)) {				// 角度換算 = 0 - 90
			y += yPerOne;
		} else if (x < (WAVE_BUFFER_SIZE * 3 / 4)) {	// 角度換算 = 90 -270
			y -= yPerOne;
		} else {										// 角度換算 = 270 - 360
			y += yPerOne;
		}
		gWaveBuffer[x] = y;
	}
}

- (void)makeSawtoothWave
{
	double y = 0;
	double yPerOne = 1.0 / (WAVE_BUFFER_SIZE / 2);
	
	gWaveBuffer[0] = y;
	for (int x = 1; x < WAVE_BUFFER_SIZE; x++) {
		if (x == (WAVE_BUFFER_SIZE / 2)) {
			y = -1.0;
		}
		y += yPerOne;
		gWaveBuffer[x] = y;
	}
}

//----------------------------------------------------------------
#pragma mark - FuncGen操作ボタンハンドル
/**
 */
- (IBAction)sendButtonHandle:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^{
		bleAccessActivityIndicatorView.hidden = NO;
		[bleAccessActivityIndicatorView startAnimating];

		[fgController transferWaveBuffer];

		[bleAccessActivityIndicatorView stopAnimating];
		bleAccessActivityIndicatorView.hidden = YES;
	});
}

- (IBAction)outputButtonHandle:(id)sender
{
	if (_outputButton.tag == 0) {
		[fgController setOutput:YES];
		_outputButton.tag = 1;
		//[_outputButton setTitle:@"OFF" forState:UIControlStateNormal];
		[_outputButton setImage:[UIImage imageNamed:@"008_00-wave_on"] forState:UIControlStateNormal];

	} else {
		[fgController setOutput:NO];
		_outputButton.tag = 0;
		//[_outputButton setTitle:@"ON" forState:UIControlStateNormal];
		[_outputButton setImage:[UIImage imageNamed:@"008_00-wave_off"] forState:UIControlStateNormal];

	}
}

//----------------------------------------------------------------
/**
 */
#pragma mark - 周波数変更

#define FUNCGEN_MIN_FREQUENCY	10
#define FUNCGEN_MAX_FREQUENCY	(100 * 1000)

// for FrequencyTuneViewDelegate
- (void)didChangeValue:(int32_t)value
{
	frequency = value;
	[self updateFrequency];
}

- (void)didClose
{
	frequencyTuneView.hidden = YES;
	[self.view sendSubviewToBack:frequencyTuneView];
}


- (IBAction)frequencyUpButtonHandle:(id)sender {
	frequency++;
	[self updateFrequency];
}

- (IBAction)frequencyDownButtonHandle:(id)sender {
	frequency--;
	[self updateFrequency];
}

- (IBAction)frequencyTapButtonHandle:(id)sender {
	// 周波数表示エリアの直上に貼ってあるUIButtonがタップされた
	frequencyTuneView.hidden = NO;
	[self.view bringSubviewToFront:frequencyTuneView];

}

- (void)updateFrequency
{
	//_frequencyLabel.text = [NSString stringWithFormat:@"%d", frequency];

	NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
	[format setNumberStyle:NSNumberFormatterDecimalStyle];
	[format setGroupingSeparator:@","];
	[format setGroupingSize:3];
	_frequencyLabel.text = [format stringForObjectValue:[NSNumber numberWithInt:frequency]];	
}


//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------

@end
