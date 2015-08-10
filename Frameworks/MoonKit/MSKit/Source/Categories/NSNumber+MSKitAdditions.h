//
//  NSNumber+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/13/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;

#define BOOLValue(NUMBER)             [(NSNumber *)NUMBER boolValue]
#define CharValue(NUMBER)             [(NSNumber *)NUMBER charValue]
#define DecimalValue(NUMBER)          [(NSNumber *)NUMBER decimalValue]
#define DoubleValue(NUMBER)           [(NSNumber *)NUMBER doubleValue]
#define FloatValue(NUMBER)            [(NSNumber *)NUMBER floatValue]
#define IntValue(NUMBER)              [(NSNumber *)NUMBER intValue]
#define IntegerValue(NUMBER)          [(NSNumber *)NUMBER integerValue]
#define LongLongValue(NUMBER)         [(NSNumber *)NUMBER longLongValue]
#define LongValue(NUMBER)             [(NSNumber *)NUMBER longValue]
#define ShortValue(NUMBER)            [(NSNumber *)NUMBER shortValue]
#define UnsignedCharValue(NUMBER)     [(NSNumber *)NUMBER unsignedCharValue]
#define UnsignedIntegerValue(NUMBER)  [(NSNumber *)NUMBER unsignedIntegerValue]
#define UnsignedIntValue(NUMBER)      [(NSNumber *)NUMBER unsignedIntValue]
#define UnsignedLongLongValue(NUMBER) [(NSNumber *)NUMBER unsignedLongLongValue]
#define UnsignedLongValue(NUMBER)     [(NSNumber *)NUMBER unsignedLongValue]
#define UnsignedShortValue(NUMBER)    [(NSNumber *)NUMBER unsignedShortValue]
#define StringValue(NUMBER)           [(NSNumber *)NUMBER stringValue]

@interface NSNumber (MSKitAdditions)

@end
