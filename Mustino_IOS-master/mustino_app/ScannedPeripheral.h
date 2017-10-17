//
//  ScannedPeripheral.h
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScannedPeripheral : NSObject

@property (strong, nonatomic) CBPeripheral* peripheral;
@property (assign, nonatomic) int RSSI;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI;

@end
