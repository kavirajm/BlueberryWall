//
//  ScannerDelegate.h
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol ScannerDelegate <NSObject>

- (void) centralManager:(CBCentralManager*) manager didPeripheralSelected:(CBPeripheral*) peripheral;

@end
