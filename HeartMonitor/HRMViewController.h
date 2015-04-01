//
//  HRMViewController.h
//  HeartMonitor
//
//  Created by Harvey Zhang on 3/28/15.
//  Copyright (c) 2015 HappyGuy. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <QuartzCore/QuartzCore.h>

// or another way to use @import <#module#>
//@import CoreBluetooth;
//@import QuartzCore;

/// Step-1: Add the appropriate Services and Characteristics for your device according to your device and the specification.

// For Polar H7 Heart Rate Monitor Services UUIDs
#define kPolarH7_HRM_SERVICE_DeviceInfo_UUID   @"180A"
#define kPolarH7_HRM_SERVICE_HeartRate_UUID    @"180D"

// For Polar H7 Heart Rate Monitor Characteristics UUIDs
#define kPolarH7_HRM_CHARACTERISTIC_Measurement_UUID    @"2A37"
#define kPolarH7_HRM_CHARACTERISTIC_BodyLocation_UUID   @"2A38"
#define kPolarH7_HRM_CHARACTERISTIC_MakerName_UUID      @"2A29"

/* Step-2: Conforming to the Delegate
This VC needs to conform the CBCentralManagerDelegate protocol to allow the delegate to monitor the discovery, connectivity, and retrieval of peripheral devices.

It also needs to conform to CBPeripheralDelegate protocol so it can monitor the discovery, exploration, and interaction of a remote peripheral's services and characteristics.
 */
@interface HRMViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *ploarH7HRMPeripheral;

// Properties for your object controls
@property (nonatomic, weak) IBOutlet UIImageView *heartImage;
@property (nonatomic, weak) IBOutlet UITextView *deviceInfoTV;

// Properties to hold characteristics for the peripheral device
@property (nonatomic, strong) NSString *connectedState;
@property (nonatomic, strong) NSString *bodyLocation;
@property (nonatomic, strong) NSString *makerName;
@property (nonatomic, strong) NSString *polarH7DeviceInfo;

// Properties to handle storing the heart beat BPM
@property (nonatomic, assign) unsigned short heartRate;
@property (nonatomic, strong) UILabel *heartRateBPMLabel;
@property (nonatomic, strong) NSTimer *pulseTimer;


// Get the heart rate BPM information
-(void)getHeartBPMData: (CBCharacteristic *)aChar error:(NSError *)error;

// Get the manufacturer name of the device
-(void)getMakerName: (CBCharacteristic *)aChar;

// Get the body location of the device
-(void)getBodyLocation: (CBCharacteristic *)aChar;

// To perform a heartbeat animation
-(void)doHeartBeatAnimation;

@end
