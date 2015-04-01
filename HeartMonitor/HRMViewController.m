//
//  HRMViewController.m
//  HeartMonitor
//
//  Created by Harvey Zhang on 3/28/15.
//  Copyright (c) 2015 HappyGuy. All rights reserved.
//

#import "HRMViewController.h"

@interface HRMViewController ()

@end

@implementation HRMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.polarH7DeviceInfo = nil;
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.heartImage.image = [UIImage imageNamed:@"HeartImage"];
    
    // Clear out textview
    self.deviceInfoTV.text = @"";
    self.deviceInfoTV.textColor = [UIColor blueColor];
    self.deviceInfoTV.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.deviceInfoTV.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:25];
    self.deviceInfoTV.userInteractionEnabled = NO;
    
    // Create a Heart Rate BPM Label
    self.heartRateBPMLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 75, 50)];
    self.heartRateBPMLabel.textColor = [UIColor whiteColor];
    self.heartRateBPMLabel.text = [NSString stringWithFormat:@"%i", 0];
    self.heartRateBPMLabel.font = [UIFont fontWithName:@"CondensedMedium" size:28];
    
    [self.heartImage addSubview:self.heartRateBPMLabel];
    
    // Scan for all available Bluetooth LE devices
    NSArray *services = @[[CBUUID UUIDWithString:kPolarH7_HRM_SERVICE_HeartRate_UUID],
                          [CBUUID UUIDWithString:kPolarH7_HRM_SERVICE_DeviceInfo_UUID]];
    /*
     *  @param delegate The delegate that will receive central role events.
     *  @param queue    The dispatch queue on which the events will be dispatched.
     *
     *  @discussion     The initialization call. The events of the central role will be dispatched on the provided queue.
     *                  If <i>nil</i>, the main queue will be used.
     *
     - (instancetype)initWithDelegate:(id<CBCentralManagerDelegate>)delegate queue:(dispatch_queue_t)queue;
     */
    CBCentralManager *centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    [centralMgr scanForPeripheralsWithServices:services options:nil]; // start searching for BLE devices that have these services.
    
    // Once the central manager is initialized, you immediately need to check its state. This tells you if the device that your app is running on is compliant with the Bluetooth LE standard.
    self.centralManager = centralMgr;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CBCentralManagerDelegate methods
/*!
 *  @method centralManagerDidUpdateState:
 *
 *  @param central  The central manager whose state has changed.
 *
 *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
 *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
 *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
 *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
 *                  manager become invalid and must be retrieved or discovered again.
 *
 *  @see            state
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // Determine the state of the peripheral
    // Ensures that your device is Bluetooth Low Energy compliant and it can be used as the central device object of your CBCentralManager.
    switch ([central state])
    {
        // If the state changes to xxxPoweredOff, then all peripheral objects that have been obtained from the central manager become invalid and must be re-discovered.
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth LE hardware is powered off"); break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth LE hardware is powered on and ready"); break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth LE state is unauthorized"); break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth LE state is unknown"); break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth LE hardware is unsupported on this platform"); break;
        default:
            NSLog(@"Do nothing by default");
            break;
    }
}

/*!
 *  @method centralManager:didDiscoverPeripheral:advertisementData:RSSI:
 *
 *  @param central              The central manager providing this update.
 *  @param peripheral           A <code>CBPeripheral</code> object.
 *  @param advertisementData    A dictionary containing any advertisement and scan response data.
 *  @param RSSI                 The current RSSI of <i>peripheral</i>, in dBm. A value of <code>127</code> is reserved and indicates the RSSI
 *								was not available.
 *
 *  @discussion                 This method is invoked while scanning, upon the discovery of <i>peripheral</i> by <i>central</i>. A discovered peripheral must be retained in order to use it; otherwise, it is assumed to not be of interest and will be cleaned up by the central manager. For a list of <i>advertisementData</i> keys, see {@link CBAdvertisementDataLocalNameKey} and other similar constants.
 *
 *  @seealso                    CBAdvertisementData.h
 *
 When a peripheral with one of the designated services is discoved, the delegate method is called with the peripheral object, the advertisement data, and RSSI.
 
 Note: RSSI stands for Received Singal Strength Indicator. Use RSSI, you can estimate the distance between Central and Peripheral.
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if ([localName length] > 0)
    {
        NSLog(@"Found one device named: %@", localName);
        [self.centralManager stopScan];
        
        self.ploarH7HRMPeripheral = peripheral;
        [self.centralManager connectPeripheral:self.ploarH7HRMPeripheral options:nil];
    }
}

// method called whenever you have successfully connected to the Bluetooth LE peripheral
// This method is invoked when a connection initiated by {@link connectPeripheral:options:} has succeeded.
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    
    /*!
     *  @param serviceUUIDs A list of <code>CBUUID</code> objects representing the service types to be discovered. If <i>nil</i>,
     *						all services will be discovered, which is considerably slower and not recommended.
     *
     *  @discussion			Discovers available service(s) on the peripheral.
     
     - (void)discoverServices:(NSArray *)serviceUUIDs;
     */
    [peripheral discoverServices:nil];
    
    self.connectedState = [NSString stringWithFormat:@"Connected: %@", peripheral.state == CBPeripheralStateConnected ? @"YES" : @"NO"];
    NSLog(@"%@", self.connectedState);
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Connection attempts fails with error:%@", error.localizedFailureReason);
}

#pragma mark - CBPeripheralDelegate methods
// Invoked when you discover the Peripheral's available services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService * service in peripheral.services)
    {
        NSLog(@"Discovered service: %@", service.UUID);
        
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

// Invoked when you discover the characteristics of a specificed service.
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_SERVICE_HeartRate_UUID]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            // Request heart beat notifications
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_Measurement_UUID]])
            {
                // You subscribe to this characteristic, which tells CBCentralManager to watch for when this characteristic changes and notify your code using setNotifyxxx:forCharxxx when it does
                [self.ploarH7HRMPeripheral setNotifyValue:YES forCharacteristic:aChar];
                NSLog(@"Found heart beat measurement characteristic");
            } else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_BodyLocation_UUID]]) {
                [self.ploarH7HRMPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found body sensor location characteristic");
            }
        }
        
    } else if ([service.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_SERVICE_DeviceInfo_UUID]]) {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_MakerName_UUID]])
            {
                [self.ploarH7HRMPeripheral readValueForCharacteristic:aChar];
                NSLog(@"Found maker name characteristic");
            }
        }
    }
}

// Invoked when you retrieve a specified characteristic's value, or when the peripheral device notifies your app that the characteristic's value has changed.
// Called when CBPeripheral reads a value (or update a value periodically).
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // check to see which characteristic's value has been updated, then read in the value
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_Measurement_UUID]]) {
        [self getHeartBPMData:characteristic error:error];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_MakerName_UUID]]) {
        [self getMakerName:characteristic];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kPolarH7_HRM_CHARACTERISTIC_BodyLocation_UUID]]) {
        [self getBodyLocation:characteristic];
    }
    
    self.deviceInfoTV.text = [NSString stringWithFormat:@"%@\n%@\n%@\n", self.connectedState, self.bodyLocation, self.makerName];
}

#pragma mark - Helpers for retrieving CBCharacteristic information for Heart Rate, Maker Name, and Body Location
// Get the heart rate BPM information
-(void)getHeartBPMData: (CBCharacteristic *)aChar error:(NSError *)error
{
    NSData *data = [aChar value];
    const uint8_t *reportData = [data bytes]; // get the byte sequence of your data object
    uint16_t bpm = 0;
    
    if ( (reportData[0] & 0x01) == 0 ) { // get the 1st bit
        bpm = reportData[1];  // Retieve the BPM value via 2nd bit
    } else { // 2nd bit is set
        // retrieve the BPM value at 2nd byte and convert this to a 16-bit value based on the host's native byte order
        bpm = CFSwapInt16LittleToHost( *(uint16_t *)(&reportData[1]) );
    }
    
    // Display the heart rate value to UI
    if (aChar.value || !error)
    {
        self.heartRate = bpm;
        self.heartRateBPMLabel.text = [NSString stringWithFormat:@"%i bpm", bpm];
        self.heartRateBPMLabel.font = [UIFont fontWithName:@"Futura-CondensedMedium" size:28];
        [self doHeartBeatAnimation];
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self
                                                         selector:@selector(doHeartBeatAnimation) userInfo:nil repeats:NO];
    }
}

// Get the manufacturer name of the device
-(void)getMakerName: (CBCharacteristic *)aChar
{
    NSString *aName = [[NSString alloc] initWithData:aChar.value encoding:NSUTF8StringEncoding];
    self.makerName = [NSString stringWithFormat:@"Manufacturer: %@", aName];
}

// Get the body location of the device
-(void)getBodyLocation: (CBCharacteristic *)aChar
{
    NSData *sensorData = aChar.value;
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData) {
        uint8_t bodyLoc = bodyData[0];
        self.bodyLocation = [NSString stringWithFormat:@"Body Location: %@", bodyLoc == 1 ? @"Chest" : @"Undefined"];
    } else {
        self.bodyLocation = [NSString stringWithFormat:@"Body Location: N/A"];
    }
}

// To perform a heartbeat animation
-(void)doHeartBeatAnimation
{
    CALayer *layer = self.heartImage.layer;
    
    // perform basic, single-keyframe animation for the layer
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulseAnimation.toValue = [NSNumber numberWithFloat:1.1];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    pulseAnimation.duration = 60. / self.heartRate / 2.;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]; // define the pacing of animation
    
    [layer addAnimation:pulseAnimation forKey:@"scale"];
    self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(doHeartBeatAnimation) userInfo:nil repeats:NO];
}

// Another example of Core Bluetooth devices is iBeacons. 

@end
