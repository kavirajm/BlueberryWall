//
//  ScannerViewController.h
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include "ScannerDelegate.h"

@interface ScannerViewController : UIViewController <CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) CBCentralManager *bluetoothManager;
@property (weak, nonatomic) IBOutlet UITableView *devicesTable;
@property (strong, nonatomic) id <ScannerDelegate> delegate;
@property (strong, nonatomic) CBUUID *filterUUID;

/*!
 * Cancel button has been clicked
 */
- (IBAction)didCancelClicked:(id)sender;

@end
