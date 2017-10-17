
//MustinoViewController.h
//
//
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"

@interface MustinoViewController : UIViewController <CBCentralManagerDelegate, CBPeripheralDelegate, ScannerDelegate, CBPeripheralManagerDelegate, NSStreamDelegate>{
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
}


@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *battery;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UITextField *reg_textField;
@property (weak, nonatomic) IBOutlet UITextField *pair_textField;
@property (weak, nonatomic) IBOutlet UILabel *debug_text;
@property (weak, nonatomic) IBOutlet UILabel *debug_text2;
@property (weak, nonatomic) IBOutlet UIButton *reg_button;
@property (weak, nonatomic) IBOutlet UIButton *pair_button;

- (IBAction)register_clicked:(id)sender;
- (IBAction)pair_clicked:(id)sender;

- (IBAction)connectOrDisconnectClicked;
- (IBAction)testButtonClicked;
- (IBAction)testButtonTouchDown:(id)sender;

@end