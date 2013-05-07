//
//  NSString+Hex.m
//  Bindo POS
//
//  Created by Allen on 10/13/12.
//  Copyright (c) 2012 BindoLabs. All rights reserved.
//

#import "NSString+Hex.h"
@interface NSString (Private)
- (int)asciiToDecimal:(char)source;
@end

@implementation NSString (Hex)

-(NSArray *)hexToDecimalArray {

    NSMutableArray *result = [NSMutableArray array];
    NSString *tmpString = [self uppercaseString];
    
    NSData *data = [tmpString dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = [tmpString UTF8String];
    
    for (int i=0; i<data.length/2; i++) {
        char highBits = bytes[2*i];
        char lowBits = bytes[2*i+1];
        
        highBits = [self asciiToDecimal:highBits];
        lowBits = [self asciiToDecimal:lowBits];
        
        [result addObject:[NSNumber numberWithInt:highBits*16+lowBits]];
    }
    
    return [NSArray arrayWithArray:result];
}

- (int)asciiToDecimal:(char)source {
    int ascii = (int)source;
    
    if(ascii > 47 && ascii < 58)
        return ascii - 48;
    
    if (ascii > 64 && ascii < 91)
        return ascii - 55;
    
    return ascii - 87;
}
@end
