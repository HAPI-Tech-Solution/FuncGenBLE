//
//  BLEAdvertising.h


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "BLEPeripheralAccess.h"

//---------------------------------------------------------

@protocol BLEAdvertisingDelegate <NSObject>
- (void)didConnectPeripheral:(CBPeripheral *)peripheral;
@end

//---------------------------------------------------------

@interface BLEAdvertising : NSObject
{
	BLEPeripheralAccess *peripheralAccess;
}

-(id)init;
-(BOOL)scanStart;
-(void)scanStop;


@property (nonatomic, assign) id<BLEAdvertisingDelegate> delegate;

@property BOOL	isScanning;
@property (strong)	CBCentralManager         *centralManager;
@property (strong, nonatomic) NSMutableArray *peripherals;

@end

//---------------------------------------------------------
