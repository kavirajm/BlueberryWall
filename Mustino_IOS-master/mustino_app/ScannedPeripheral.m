//
//  ScannedPeripheral.m
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//


#import "ScannedPeripheral.h"

@implementation ScannedPeripheral
@synthesize peripheral;
@synthesize RSSI;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI
{
    ScannedPeripheral* value = [ScannedPeripheral alloc];
    value.peripheral = peripheral;
    value.RSSI = RSSI;
    return value;
}

-(BOOL)isEqual:(id)object
{
    ScannedPeripheral* other = (ScannedPeripheral*) object;
    return peripheral == other.peripheral;
}

@end
