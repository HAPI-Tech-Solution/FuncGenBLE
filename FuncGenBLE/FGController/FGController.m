//
//  FGController.m
//  FunctionGenBLE
//
//  Created by Takehisa Oneta on 2015/05/20.
//  Copyright (c) 2015年 Takehisa Oneta. All rights reserved.
//

#import "FGController.h"

extern double	gWaveBuffer[WAVE_BUFFER_SIZE];		// -1〜1

@implementation FGController

//------------------------------------------------------------------------------------------
/**
 *
 */
- (instancetype)init
{
	self = [super init];
	if (self != nil) {
		_characteristicDic = [NSMutableDictionary dictionary];
		[self initializeContoller];
	}
	return self;
}

//------------------------------------------------------------------------------------------
/**
 *
 */
- (void)initializeContoller
{
	bleAdvertising = [[BLEAdvertising alloc] init];
	bleAdvertising.delegate = self;
	blePeripheralAccess = nil;
}

//------------------------------------------------------------------------------------------
/**
 * スキャン開始
 */
- (void)peripheralScanStart
{
	[bleAdvertising scanStart];
}

/**
 * スキャン停止
 */
- (void)peripheralScanStop
{
	[bleAdvertising scanStop];
}

//--------------------------------------
// for BLEAdvertisingDelegate
/**
 * 所望のペリフェラルが存在した!
 */
- (void)didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"didConnectPeripheral");
	
	blePeripheralAccess = [[BLEPeripheralAccess alloc] initWithPeripheral:peripheral];
	blePeripheralAccess.delegate = self;
	{
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_RESET];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_DEVICE];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_OUTPUT];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_FREQUENCY];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_WAVEFORMINFO];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_WAVEFORMBLOCK];
		[blePeripheralAccess.characteristicUUIDs addObject:CHARACTERISTICS_UUID_WAVEFORMTOBUFFER];
	}
	[blePeripheralAccess discoverServices];
}

//------------------------------------------------------------------------------------------
// for BLEPeripheralAccessDelegate

//- (void)didFindCharacteristic:(CBCharacteristic *)characteristic
- (void)didFindCharacteristic:(CBCharacteristic *)characteristic c_uuid:(NSString *)c_uuid;
{
	[_characteristicDic setObject:characteristic forKey:c_uuid];
	
	NSLog(@"didFindCharacteristic");
}

//------------------------------------------------------------------------------------------

- (void)connect:(CBPeripheral *)peripheral
{
}

- (void)disconnect:(CBPeripheral *)peripheral
{	
}

- (BOOL)isConnected
{
	return (blePeripheralAccess != nil);
}

//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
/**
 * 出力デバイスの選択
 */
- (void)setDevice:(int)deviceId
{

}

//------------------------------------------------------------------------------------------
/**
 * 出力のON/OFF
 *
 * @param BOOL using	YES=ON、NO=OFF
 */
- (void)setOutput:(BOOL)using
{
	 if (blePeripheralAccess == nil)
		 return;

	uint8_t usingValue = using ? 1 : 0;
	NSData *data = [NSData dataWithBytes:(unsigned char *)&usingValue length:sizeof(uint8_t)];
	NSLog(@"setOutput: %@", data.description);
	
	CBCharacteristic *characteristic = [_characteristicDic objectForKey:CHARACTERISTICS_UUID_OUTPUT];
	[blePeripheralAccess writeWithResponse:characteristic value:data];
}

//------------------------------------------------------------------------------------------
/**
 * 周波数設定
 */
- (void)setFrequencey:(UInt32)freq
{
	if (blePeripheralAccess == nil)
		return;
	
	NSData *data = [NSData dataWithBytes:(unsigned char *)&freq length:sizeof(UInt32)];
	NSLog(@"setFrequencey: %@", data.description);
	
	CBCharacteristic *characteristic = [_characteristicDic objectForKey:CHARACTERISTICS_UUID_OUTPUT];
	[blePeripheralAccess writeWithResponse:characteristic value:data];
}

//------------------------------------------------------------------------------------------
/**
 * 波形データ送信
 */
- (void)transferWaveBuffer
{
	if (blePeripheralAccess == nil)
		return;

//#define WAVEFORM_BUFFER_SIZE	8192
#define WAVEFORM_BUFFER_SIZE	360
	
	// gWaveBuffer --> waveformBuffer
	uint16_t waveformBuffer[WAVEFORM_BUFFER_SIZE];
	for (int i = 0; i < WAVEFORM_BUFFER_SIZE; i++) {
		int pt = (int)((double)i * (double)WAVE_BUFFER_SIZE / (double)WAVEFORM_BUFFER_SIZE);
		
		double dt = (gWaveBuffer[pt] + 1.0) / 2.0;		// -1.0〜1.0 を 0.0〜1.0 に変換する
		uint16_t dd = (uint16_t)(dt * (double)0xffff);	// 0.0〜1.0 を 0x0000〜0xffff に変換する
		waveformBuffer[i] = dd;
		//NSLog(@"%d: %d: %f: %d", i, pt, dt, dd);
	}
	
	
	WaveformInfo waveformInfo;
	{
		waveformInfo.waveSize = WAVEFORM_BUFFER_SIZE * 2;
		waveformInfo.bitPerData = 12;
		waveformInfo.blockSize = FGC_BUFFERTRANSFER_MAX;
		waveformInfo.blockMaxNum = waveformInfo.waveSize / waveformInfo.blockSize;
	}
	NSData *data = [NSData dataWithBytes:(unsigned char *)&waveformInfo length:sizeof(WaveformInfo)];
	NSLog(@"WaveformInfo: %@", data.description);
	
	CBCharacteristic *characteristic = [_characteristicDic objectForKey:CHARACTERISTICS_UUID_WAVEFORMINFO];
	[blePeripheralAccess writeWithResponse:characteristic value:data];


	WaveformBlock waveformBlock;
	int block_max = waveformInfo.blockMaxNum;	// (WAVEFORM_BUFFER_SIZE * 2) / FGC_BUFFERTRANSFER_MAX;
	for (int i = 0; i < block_max; i++) {
		waveformBlock.blockNo = i;
		waveformBlock.length = 16;      // WaveformBlock.bufferの有効な長さ
		memcpy(	waveformBlock.buffer,
				((uint8_t *)waveformBuffer) + (i * FGC_BUFFERTRANSFER_MAX),
				waveformBlock.length	);
		NSData *data = [NSData dataWithBytes:(unsigned char *)&waveformBlock length:sizeof(WaveformBlock)];
		//NSLog(@"WaveformBlock: %@", data.description);

		characteristic = [_characteristicDic objectForKey:CHARACTERISTICS_UUID_WAVEFORMBLOCK];
		[blePeripheralAccess writeWithResponse:characteristic value:data];
	}


	{
		characteristic = [_characteristicDic objectForKey:CHARACTERISTICS_UUID_WAVEFORMTOBUFFER];
		NSData *data = [NSData dataWithBytes:nil length:0];
		[blePeripheralAccess writeWithResponse:characteristic value:data];
	}

}

/**
 * リセット
 */
- (void)reset;
{
	
}

/**
 * デバイス情報取得
 */
- (int)getDevice
{
	return 0;
}

/**
 * 出力状態の取得
 *
 * @return BOOL YES=ON、NO=OFF
 */
- (BOOL)getOutput
{
	return YES;
}

/**
 * 出力周波数の取得
 */
- (UInt32)getFrequencey
{
	return 100;
}

@end
