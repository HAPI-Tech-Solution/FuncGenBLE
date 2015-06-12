//
//  WavefFormView.m
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/13.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import "WaveFormView.h"

#import "Defines.h"
#import "Utils.h"

//----------------------------------------------------------------
//----------------------------------------------------------------

@implementation WaveFormView


- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		//waveformRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
		
	}
	return self;
}

//----------------------------------------------------------------

- (void)setWaveBuffer:(double *)buffer
{
	_waveBuffer = buffer;
}

- (double *)getWaveBuffer
{
	return _waveBuffer;
}

//----------------------------------------------------------------

- (void)setWaveFormRect:(CGRect)rect
{
	self.frame = rect;
	//[self setNeedsDisplay];
}

//----------------------------------------------------------------

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	
	NSLog(@"WaveFormView: drawRect");
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect drawRect = CGRectMake(rect.origin.x, rect.origin.y,rect.size.width, rect.size.height);
	CGContextSetRGBFillColor(context, 0.0f, 0.0, 0.0f, 0.0f);
	CGContextFillRect(context, drawRect);
	CGContextStrokePath(context);

	[self drawWaveForm:context];
	CGContextStrokePath(context);
}

//----------------------------------------------------------------
/**
 * x = 0〜WAVE_BUFFER_SIZE を waveformRect.origin.x〜 + waveformRect.origin.x + waveformRect.size.width に変換する
 */
- (CGFloat)changeX:(CGFloat)x
{
	return self.frame.origin.x + (x * self.frame.size.width / WAVE_BUFFER_SIZE);
	//return self.frame.origin.x + x;
}

/**
 * y = -1〜1 を (waveformRect.origin.y + waveformRect.size.height) 〜 waveformRect.origin.y に変換する
 */
- (CGFloat)changeY:(CGFloat)y
{
	CGFloat yy = (y + 1.0) / 2.0;
	//return waveformRect.origin.y + waveformRect.size.height - (yy * waveformRect.size.height);
	return self.frame.origin.y + self.frame.size.height - (yy * self.frame.size.height);
}

//----------------------------------------------------------------
/**
 * 波形描画
 */
- (void)drawWaveForm:(CGContextRef)context
{
	CGContextSetStrokeColorWithColor(context, UIColor.yellowColor.CGColor);
	CGContextSetLineWidth(context, 1.0);

	CGFloat fx = [self changeX:0];
	CGFloat fy = [self changeY:_waveBuffer[0]];
	CGContextMoveToPoint(context, fx, fy);
	
	for (int x = 1; x < WAVE_BUFFER_SIZE; x++) {
		fx = [self changeX:x];
		fy = [self changeY:_waveBuffer[x]];
		CGContextAddLineToPoint(context, fx, fy);

		//NSLog(@"%f:%f", fx, fy);
	}
	CGContextStrokePath(context);
}

//----------------------------------------------------------------
//----------------------------------------------------------------
/**
 *
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	WaveBufferOne	one;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];

	if ([self bufferPointFromViewPoint:location bufferPoint:&one]) {
NSLog(@"touchesBegan: x:%d y:%f", one.x, one.y);
		_waveBuffer[one.x] = one.y;
		lastOne = one;
		[self setNeedsDisplay];
	}

	lastTouchPoint = location;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	WaveBufferOne	one;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	
	if ([self bufferPointFromViewPoint:location bufferPoint:&one]) {
		//NSLog(@"touchesMoved: x:%d y:%f", one.x, one.y);
		_waveBuffer[one.x] = one.y;

		{
			// one.x と lastOne.xが連続でない場合、その間にある値を補完する
			if (abs(one.x - lastOne.x) >= 1) {
				if (one.x < lastOne.x) {
					for (int x = one.x; x < lastOne.x; x++) {
						_waveBuffer[x] = one.y;
					}
				} else if (one.x > lastOne.x) {
					for (int x = lastOne.x; x < one.x; x++) {
						_waveBuffer[x] = one.y;
					}
				}
			}
		}
		
		lastOne = one;
		[self setNeedsDisplay];
	}


	lastTouchPoint = location;
}
/*
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	WaveBufferOne	one;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	if ([self bufferPointFromViewPoint:location bufferPoint:&one]) {
		NSLog(@"touchesEnded: x:%f y:%f = x:%d y:%f", location.x, location.y, one.x, one.y);
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	WaveBufferOne	one;

	UITouch *touch = [touches anyObject];
	CGPoint location = [touch locationInView:self];
	NSLog(@"touchesCancelled: x:%f y:%f", location.x, location.y);
	
	if ([self bufferPointFromViewPoint:location bufferPoint:&one]) {
		NSLog(@"touchesEnded: x:%f y:%f = x:%d y:%f", location.x, location.y, one.x, one.y);
	}
}
*/

- (BOOL)bufferPointFromViewPoint:(CGPoint)point bufferPoint:(WaveBufferOne *)bufferPoint
{
#if 0
	if ((point.x < waveformRect.origin.x) ||
		(waveformRect.origin.x + waveformRect.size.width < point.x)	) {
		return NO;
	}
	if ((point.y < waveformRect.origin.y) ||
		(waveformRect.origin.y + waveformRect.size.height < point.y)	) {
		return NO;
	}
	
	int x = (point.x - waveformRect.origin.x) * (waveformRect.size.width / WAVE_BUFFER_SIZE);
	double y = ((point.y - waveformRect.origin.y) / waveformRect.size.height) * -2.0 + 1.0;

	bufferPoint->x = x;
	bufferPoint->y = y;
#else
	if ((point.x < self.frame.origin.x) ||
		(self.frame.origin.x + self.frame.size.width < point.x)	) {
		return NO;
	}
	if ((point.y < self.frame.origin.y) ||
		(self.frame.origin.y + self.frame.size.height < point.y)	) {
		return NO;
	}
	
	int x = (point.x - self.frame.origin.x) * (self.frame.size.width / WAVE_BUFFER_SIZE);
	double y = ((point.y - self.frame.origin.y) / self.frame.size.height) * -2.0 + 1.0;

	bufferPoint->x = x;
	bufferPoint->y = y;
#endif

	return YES;
}


//----------------------------------------------------------------

@end
