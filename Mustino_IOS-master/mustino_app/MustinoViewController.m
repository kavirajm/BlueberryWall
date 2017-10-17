//
//  MustinoViewController.m
//
//
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//


#import "MustinoViewController.h"
#import "ScannerViewController.h"
#import "Constants.h"
#import <AVFoundation/AVFoundation.h>
#import "HelpViewController.h"


@interface MustinoViewController () {
    CBUUID *proximityImmediateAlertServiceUUID;
    CBUUID *proximityLinkLossServiceUUID;
    CBUUID *proximityAlertLevelCharacteristicUUID;
    CBUUID *batteryServiceUUID;
    CBUUID *batteryLevelCharacteristicUUID;
    BOOL isImmidiateAlertOn, isAppInBackgound, isBackButtonPressed;;
    bool isPressed;
    bool isVibrate;
    bool isVibrate2;
}

/*!
 * This property is set when the device successfully connects to the peripheral. It is used to cancel the connection
 * after user press Disconnect button.
 */
@property (strong, nonatomic) CBPeripheral *proximityPeripheral;
@property (strong, nonatomic)CBPeripheralManager *peripheralManager;
@property (strong, nonatomic)CBCharacteristic *immidiateAlertCharacteristic;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation MustinoViewController
@synthesize bluetoothManager;
@synthesize backgroundImage;
@synthesize battery;
@synthesize deviceName;
@synthesize connectButton;
@synthesize proximityPeripheral;
@synthesize testButton;
@synthesize audioPlayer;



-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        proximityImmediateAlertServiceUUID = [CBUUID UUIDWithString:proximityImmediateAlertServiceUUIDString];
        proximityLinkLossServiceUUID = [CBUUID UUIDWithString:proximityLinkLossServiceUUIDString];
        proximityAlertLevelCharacteristicUUID = [CBUUID UUIDWithString:proximityAlertLevelCharacteristicUUIDString];
        batteryServiceUUID = [CBUUID UUIDWithString:batteryServiceUUIDString];
        batteryLevelCharacteristicUUID = [CBUUID UUIDWithString:batteryLevelCharacteristicUUIDString];
    }
    return self;
}

- (void)viewDidLoad
{
    if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
    
    // Rotate the vertical label
    //self.verticalLabel.transform = CGAffineTransformMakeRotation(-M_PI / 2);
    [self initGattServer];
    self.immidiateAlertCharacteristic = nil;
    isImmidiateAlertOn = NO;
    isAppInBackgound = NO;
    isBackButtonPressed = NO;
    [self initSound];
    [self initNetworkCommunication];

}

- (void)initNetworkCommunication {
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)"192.168.2.51", 8080, &readStream, &writeStream);
    
	inputStream = (__bridge NSInputStream *)readStream;
	outputStream = (__bridge NSOutputStream *)writeStream;
    
	[inputStream setDelegate:self];
	[outputStream setDelegate:self];
	[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inputStream open];
	[outputStream open];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initSound
{
    NSError *error  = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"high" ofType:@"mp3"]];
    audioPlayer = [[AVAudioPlayer alloc]
                   initWithContentsOfURL:url
                   error:&error];
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@",
              [error localizedDescription]);
    } else {        
        [audioPlayer prepareToPlay];
    }
}


-(void)appDidEnterBackground:(NSNotification *)_notification
{
    isAppInBackgound = YES;
    NSString *message = [NSString stringWithFormat:@"You are still connected to %@",proximityPeripheral.name];
    [self showBackgroundAlert:message];
}

-(void)showBackgroundAlert:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.alertAction = @"Show";
    notification.alertBody = message;
    notification.hasAction = NO;
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.timeZone = [NSTimeZone  defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

-(void)showForegroundAlert:(NSString *)message
{
     NSLog(@"FOREGROUND ALERT");
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"nRF Toolbox" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    [alert show];
}

-(void)appDidBecomeActiveBackground:(NSNotification *)_notification
{
    isAppInBackgound = NO;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (IBAction)register_clicked:(id)sender {
    NSLog(@"Registering...");
    [self writeToServer: [NSString  stringWithFormat:@"register:%@",self.reg_textField.text]];
}

- (IBAction)pair_clicked:(id)sender {
    NSLog(@"Pairing...");
    [self writeToServer: [NSString  stringWithFormat:@"pair:%@",self.pair_textField.text]];
    [self connect];
}

- (IBAction)backgroundclick:(id)sender {
    [self.reg_textField resignFirstResponder];
    [self.pair_textField resignFirstResponder];
}


- (void) connect
{
    NSLog(@"Connecting...");
    [self writeToServer: [NSString  stringWithFormat:@"connect:%@",self.reg_textField.text]];
    
}

- (IBAction)connectOrDisconnectClicked {
    NSLog(@"connect button pressed");
    if (proximityPeripheral != nil)
    {
        [bluetoothManager cancelPeripheralConnection:proximityPeripheral];
    }
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // The 'scan' seque will be performed only if connectedPeripheral == nil (if we are not connected already).
    return ![identifier isEqualToString:@"scan"] || proximityPeripheral == nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"scan"])
    {
        // Set this contoller as scanner delegate
        ScannerViewController *controller = (ScannerViewController *)segue.destinationViewController;
        controller.filterUUID = proximityLinkLossServiceUUID;
        controller.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"help"]) {
        isBackButtonPressed = NO;
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"-PROXIMITY profile allows you to connect to your Proximity sensor.\n\n-You can find your valuables attached with Proximity tag by pressing FindMe button on creen and you can find your phone by pressing relevant button on your tag.\n\n-A notification will appear on your phone screen when you go away from your connected tag."];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (proximityPeripheral != nil && isBackButtonPressed)
    {
        [bluetoothManager cancelPeripheralConnection:proximityPeripheral];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    isBackButtonPressed = YES;
}


- (IBAction)testButtonClicked
{
    NSLog(@"TestPressed");
    if (self.immidiateAlertCharacteristic) {
        if (isImmidiateAlertOn) {
            [self mustLow];
        }
        else {
            [self mustHigh];
        }
    }
}

- (IBAction)testButtonTouchDown:(id)sender {
    NSLog(@"Testtouchdown");
    if (self.immidiateAlertCharacteristic) {
        if (isImmidiateAlertOn) {
            [self mustLow];
        }
        else {
            [self mustHigh];
        }
    }
}

-(void) enabletestButton
{
    testButton.enabled = YES;
    [testButton setBackgroundColor:[UIColor blackColor]];
    [testButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) disabletestButton
{
    testButton.enabled = NO;
    [testButton setBackgroundColor:[UIColor lightGrayColor]];
    [testButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
}


-(void)initGattServer
{
    self.peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
}

-(void)addServices
{
    NSLog(@"addServices");
    CBMutableService *service = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:@"1802"] primary:YES];
    service.characteristics = [NSArray arrayWithObject:[self createCharacteristic]];
    [self.peripheralManager addService:service];
    
}

-(CBMutableCharacteristic *)createCharacteristic
{
    NSLog(@"createCharacteristic");
    CBCharacteristicProperties properties = CBCharacteristicPropertyWriteWithoutResponse;
    CBAttributePermissions permissions = CBAttributePermissionsWriteable;
    CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:@"2A06"] properties:properties value:nil permissions:permissions];
    return characteristic;
    
}

-(void)mustHigh
{
    if (self.immidiateAlertCharacteristic) {
        NSLog(@"must_high");
        uint8_t val = 2;
        NSData *data = [NSData dataWithBytes:&val length:1];
        [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
        isImmidiateAlertOn = true;
        [testButton setTitle:@"SilentMe" forState:UIControlStateNormal];
    }
}

-(void)mustLow
{
    if (self.immidiateAlertCharacteristic) {
        NSLog(@"must_low");
        uint8_t val = 0;
        NSData *data = [NSData dataWithBytes:&val length:1];
        [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
        isImmidiateAlertOn = false;
        [testButton setTitle:@"Buzz" forState:UIControlStateNormal];
    }
    
}

#pragma mark High and Low methods
- (void) pingLow {
    NSLog(@"sendto server 0");
    [self writeToServer: [NSString  stringWithFormat:@"mustino_t:%d",0]];

   
}

-(void) pingHigh
{
    NSLog(@"sendto server 1");
   
    [self writeToServer: [NSString  stringWithFormat:@"mustino_t:%d",1]];
}

-(void) playSoundOnce
{
    NSLog(@"sendto server I am online");
    
}


- (void) writeToServer:(NSString *)sentdata
{
    if ([outputStream streamStatus] != NSStreamStatusOpen) {
        NSLog(@"reconnecting...", nil);
        [self initNetworkCommunication];
    }
    NSString *response  = sentdata;
	NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSUTF8StringEncoding]];
	[outputStream write:[data bytes] maxLength:[data length]];
    
}



- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
	NSLog(@"stream event %i", streamEvent);
	switch (streamEvent) {
		case NSStreamEventOpenCompleted:
			NSLog(@"Stream opened");
			break;
            
		case NSStreamEventHasBytesAvailable:
            
			if (theStream == inputStream) {
				uint8_t buffer[1024];
				int len;
                //				int i = 0;
                
				while ([inputStream hasBytesAvailable]) {
					len = [inputStream read:buffer maxLength:sizeof(buffer)];
					if (len > 0) {
						NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
						if (nil != output) {
							NSLog(@"server said: %@", output);
                            self.debug_text.text = [NSString stringWithFormat:@"server said: %@", output];
                            
                            if ([output intValue]==1) {
                                
                                if (self.immidiateAlertCharacteristic) {
                                    NSLog(@"immidiateAlertOn");
                                    uint8_t val = 2;
                                    NSData *data = [NSData dataWithBytes:&val length:1];
                                    [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
                                    isImmidiateAlertOn = true;
                                    [testButton setTitle:@"SilentMe" forState:UIControlStateNormal];
                                }

                            }
                            else if ([output intValue]==0){
                                if (self.immidiateAlertCharacteristic) {
                                    NSLog(@"immidiateAlertOff");
                                    uint8_t val = 0;
                                    NSData *data = [NSData dataWithBytes:&val length:1];
                                    [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
                                    isImmidiateAlertOn = false;
                                    [testButton setTitle:@"Buzz" forState:UIControlStateNormal];
                                }

                            }
                            else if([output rangeOfString:@"register"].location == NSNotFound){
                                self.reg_button.enabled = FALSE;
                                self.reg_textField.enabled = FALSE;
                                
                            }
                            else if([output rangeOfString:@"paired"].location == NSNotFound){
                                self.pair_button.enabled = FALSE;
                                self.pair_textField.enabled = FALSE;
                                
                            }
                            else{
                                NSLog(@"No action yet");
                                
                            }
                           
                            NSLog(@"serv:isvibrate:%d",isVibrate);
                            
                            if(([output intValue]==1)&&(isVibrate)){
                                NSLog(@"vibrating....!!!");
                                uint8_t val = 0;
                                NSData *data = [NSData dataWithBytes:&val length:1];
                                [proximityPeripheral writeValue:data forCharacteristic:self.immidiateAlertCharacteristic type:CBCharacteristicWriteWithoutResponse];
                                
                                NSLog(@"serv:isvibrate:%@",data);
                                
                                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                                isVibrate2 = TRUE;
                                
                            }
                            else if([output intValue]==1){
                                isVibrate2=TRUE;
                            }
                            else{
                                isVibrate2=FALSE;
                            }
                        }
                    }
                }
            }
			break;
            
		case NSStreamEventErrorOccurred:
		{
			[theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			NSLog(@"Can not connect to the host!");
			
            
			break;
		}
            
		case NSStreamEventEndEncountered:
			break;
            
		default:
			NSLog(@"Unknown event");
	}
}




#pragma mark CBPeripheralManager delegates
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    NSLog(@"peripheralManagerDidUpdateState");
    switch ([peripheral state]) {
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"State is Off");
            break;
            
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"State is on");
            [self addServices];
            break;
            
        default:
            break;
    }
}


-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error in adding service");
    }
    else {
        NSLog(@"service added successfully");
    }
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"didReceiveReadRequest");
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *attributeRequest = [requests objectAtIndex:0];
    if ([attributeRequest.characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
        const uint8_t *data = [attributeRequest.value bytes];
        int alertLevel = data[0];
        NSLog(@"Alert Level is: %d",alertLevel);
        switch (alertLevel) {
            case 0:
                NSLog(@"No alert");
                [self pingLow];
                break;
            case 1:
                NSLog(@"Low alert");
                [self pingHigh];
                break;
            case 2:
                NSLog(@"High alert");
                [self pingHigh];
                
                break;
                
            default:
                break;
        }
        
    }
}


#pragma mark Scanner Delegate methods

-(void)centralManager:(CBCentralManager *)manager didPeripheralSelected:(CBPeripheral *)peripheral
{
    // We may not use more than one Central Manager instance. Let's just take the one returned from Scanner View Controller
    bluetoothManager = manager;
    bluetoothManager.delegate = self;
    
    // The sensor has been selected, connect to it
    proximityPeripheral = peripheral;
    proximityPeripheral.delegate = self;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
    [bluetoothManager connectPeripheral:proximityPeripheral options:options];
}

#pragma mark Central Manager delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        // TODO
    }
    else
    {
        // TODO
        NSLog(@"Bluetooth not ON");
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        [deviceName setText:peripheral.name];
        [connectButton setTitle:@"DISCONNECT" forState:UIControlStateNormal];
        
        [self enabletestButton];
    });

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveBackground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    if (isAppInBackgound) {
        NSString *message = [NSString stringWithFormat:@"%@ is within range!",proximityPeripheral.name];
        [self showBackgroundAlert:message];
    }
    
    // Peripheral has connected. Discover required services
    [proximityPeripheral discoverServices:@[proximityLinkLossServiceUUID, proximityImmediateAlertServiceUUID, batteryServiceUUID]];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Connecting to the peripheral failed. Try again" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
        proximityPeripheral = nil;
        [self disabletestButton];
        [self clearUI];
    });
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *message = [NSString stringWithFormat:@"%@ is out of range!",proximityPeripheral.name];
        if (error) {
            NSLog(@"error in disconnection");
            self.immidiateAlertCharacteristic = nil;
            [self disabletestButton];
            NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnNotificationKey];
            [bluetoothManager connectPeripheral:proximityPeripheral options:options];
            if (isAppInBackgound) {
                [self showBackgroundAlert:message];
            }
            else {
                [self showForegroundAlert:message];
            }
            [self playSoundOnce];
            
        }
        else {
            // Scanner uses other queue to send events. We must edit UI in the main queue
            
                NSLog(@"disconnected");
                [connectButton setTitle:@"CONNECT" forState:UIControlStateNormal];
                proximityPeripheral = nil;
                [self disabletestButton];
                [self clearUI];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            
        }
    });
}

#pragma mark CBPeripheral delegates
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices inside %@",peripheral.name);
    for (CBService *service in peripheral.services) {
        NSLog(@"service found: %@",service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
            NSLog(@"Linkloss service is found");
            [proximityPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A06"]] forService:service];
        }
        else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1802"]]) {
            NSLog(@"Immidiate Alert service is found");
            [proximityPeripheral discoverCharacteristics:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A06"]] forService:service];
        }
        else if ([service.UUID isEqual:batteryServiceUUID])
        {
            NSLog(@"Battery service found");
            [proximityPeripheral discoverCharacteristics:nil forService:service];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
                NSLog(@"Alert level characteristic is found under Linkloss service");
                uint8_t val = 1;
                NSData *data = [NSData dataWithBytes:&val length:1];
                NSLog(@"writing Alert level characteristic");
                [proximityPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    }
    else if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1802"]]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"2A06"]]) {
                NSLog(@"Alert level characteristic is found under Immidiate Alert service");
                self.immidiateAlertCharacteristic = characteristic;
            }
        }
    }
    else if ([service.UUID isEqual:batteryServiceUUID]) {
        
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
                NSLog(@"Battery Level characteristic is found");
                [proximityPeripheral readValueForCharacteristic:characteristic];
            }
        }
        
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([characteristic.UUID isEqual:batteryLevelCharacteristicUUID]) {
            const uint8_t *array = [characteristic.value bytes];
            uint8_t batteryLevel = array[0];
             //   NSLog(@"battery value received %d",batteryLevel);
            NSString* text = [[NSString alloc] initWithFormat:@"%d%%", batteryLevel];
            [battery setTitle:text forState:UIControlStateDisabled];
            if (battery.tag == 0)
            {
                // If battery level notifications are available, enable them
                if (([characteristic properties] & CBCharacteristicPropertyNotify) > 0)
                {
                    NSLog(@"battery has notifications");
                    battery.tag = 1; // mark that we have enabled notifications
                    
                    // Enable notification on data characteristic
                    [proximityPeripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else
                {
                    NSLog(@"battery don't have notifications");
                }
            }
        }
        });
    }
    else {
        NSLog(@"error in Battery value");
    }
}

- (void) clearUI
{
    deviceName.text = @"DEFAULT PROXIMITY";
    [battery setTitle:@"n/a" forState:UIControlStateDisabled];
    battery.tag = 0;
    isAppInBackgound = NO;
    isImmidiateAlertOn = NO;
    self.immidiateAlertCharacteristic = nil;
}


@end
