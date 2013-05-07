//
//  BPDUKPTIDTechParser.m
//  Bindo POS
//
//  Created by hao on 10/11/12.
//  Copyright (c) 2012 BindoLabs. All rights reserved.
//

#import "BPDUKPTIDTechParser.h"
#import "EmptyParsingResult.h"
#import "NSString+Hex.h"

@implementation BPDUKPTIDTechParser {
    BOOL _track1Present;
    BOOL _track2Present;
    BOOL _track3Present;
    int _decryptedLength;
    int _track1Length;
    int _track2Length;
    int _track3Length;
    NSString *_hidString;
    NSArray *_hidArray;
    NSArray *_ksnArray;
    NSMutableArray *_track1Data;
    NSMutableArray *_track2Data;
    NSMutableArray *_track3Data;
    BPDUKPTParsingResult *_result;
}

const int TRACK_1_CLEAR_MASK              = 1;
const int TRACK_2_CLEAR_MASK              = 2;
const int TRACK_3_CLEAR_MASK              = 4;
const int INDEX_LOW_BYTE_OF_TOTAL_LENGTH  = 1;
const int INDEX_HIGH_BYTE_OF_TOTAL_LENGTH = 2;
const int NUMBER_OF_BYTES_IN_HEADER       = 3;
const int NUMBER_OF_BYTES_IN_FOOTER       = 3;
const int INDEX_TRACK_1_DATA_LENGTH       = 5;
const int INDEX_TRACK_2_DATA_LENGTH       = 6;
const int INDEX_TRACK_3_DATA_LENGTH       = 7;
const int INDEX_CLEAR_MASK_DATA_STATUS    = 8;
const int LENGTH_OF_KSN                   = 10;
const int INDEX_KSN_START                 = -13;

- (BPDUKPTIDTechParser *)initWithHID:(NSString *)hid {
    self = [super init];
    
    if (self) {
        _hidString = hid;
        _decryptedLength = 0;
        _track1Length = 0;
        _track2Length = 0;
        _track3Length = 0;
        _hidArray = [NSArray array];
        _ksnArray = [NSArray array];
        _track1Data = [NSMutableArray array];
        _track2Data = [NSMutableArray array];
        _track3Data = [NSMutableArray array];
        _result = [[BPDUKPTParsingResult alloc] init];
    }

    return self;
}

- (BPDUKPTParsingResult *)parse {
    @try {
        [self normalizeInput];
        [self extractEncrytpedData];

        _result.ksn = [_ksnArray componentsJoinedByString:@","];
        _result.track1 = [_track1Data componentsJoinedByString:@","];
        _result.track2 = [_track2Data componentsJoinedByString:@","];
        _result.track3 = [_track3Data componentsJoinedByString:@","];

        return _result;
    }
    @catch (NSException *exception) {
        return [[EmptyParsingResult alloc] init];
    }
}

- (void)normalizeInput {
    [self normalizeHID];
    [self normalizeTrack1Length];
    [self normalizeTrack2Length];
    [self normalizeTrack3Length];
}

- (void)normalizeHID {
    [self ensurePresenceOfHID];
    [self convertHIDFromHEXToDecimal];
    [self ensureIntegrityOfHID];
}

- (void)ensurePresenceOfHID {
    if ([_hidString isEqual:[NSNull null]])
        @throw([NSException exceptionWithName:@"HID not present" reason:@"You have to provide HID" userInfo:nil]);
    
    NSCharacterSet *charsToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    _hidString = [[_hidString componentsSeparatedByCharactersInSet:charsToRemove] componentsJoinedByString:@""];

    if ([_hidString length] == 0)
        @throw([NSException exceptionWithName:@"HID not present" reason:@"You have to provide HID" userInfo:nil]);
}

- (void)convertHIDFromHEXToDecimal {
    _hidArray = [_hidString hexToDecimalArray];
}

- (void)ensureIntegrityOfHID {
    if ([self HIDLengthCompromised])
        @throw([NSException exceptionWithName:@"Invalid HID" reason:@"HID length compromised" userInfo:nil]);
    
    if ([self HIDLRCComporised])
        @throw([NSException exceptionWithName:@"Invalid HID" reason:@"HID LRC compromised" userInfo:nil]);
    
    if ([self HIDChecksumCompromised])
        @throw([NSException exceptionWithName:@"Invalid HID" reason:@"HID checksum compromised" userInfo:nil]);
}

- (BOOL)HIDLengthCompromised {
    int expectedLength = [_hidArray[INDEX_HIGH_BYTE_OF_TOTAL_LENGTH] intValue]*256 + [_hidArray[INDEX_LOW_BYTE_OF_TOTAL_LENGTH] intValue];
    int actualLength = _hidArray.count - NUMBER_OF_BYTES_IN_HEADER - NUMBER_OF_BYTES_IN_FOOTER;

    return expectedLength != actualLength;
}

- (BOOL)HIDLRCComporised {
    int expectedLRC = 0;
    for (int i=3; i<_hidArray.count-3;i++) {
        expectedLRC ^= [_hidArray[i] intValue];
    }

    int actualLRC = [_hidArray[_hidArray.count-3] intValue];
    
    return expectedLRC != actualLRC;
}

- (BOOL)HIDChecksumCompromised {
    int expectedChecksum = 0;
    for (int i=3; i<_hidArray.count-3; i++) {
        expectedChecksum += [_hidArray[i] intValue];
    }
    
    expectedChecksum %= 256;

    int actualChecksum = [_hidArray[_hidArray.count-2] intValue];
    
    return expectedChecksum != actualChecksum;
}

- (void)normalizeTrack1Length {
    int rawTrack1Length = [_hidArray[INDEX_TRACK_1_DATA_LENGTH] intValue];
    int clearMaskDataStatus = [_hidArray[INDEX_CLEAR_MASK_DATA_STATUS] intValue];
    
    if (rawTrack1Length > 0) {
        _track1Present = YES;
        
        if ((clearMaskDataStatus & TRACK_1_CLEAR_MASK) != 0)
            _decryptedLength += rawTrack1Length;

        if ((rawTrack1Length % 8) == 0)
            _track1Length = rawTrack1Length;
        else
            _track1Length = (rawTrack1Length / 8 + 1) * 8;
    }
}

- (void)normalizeTrack2Length {
    int rawTrack2Length = [_hidArray[INDEX_TRACK_2_DATA_LENGTH] intValue];
    int clearMaskDataStatus = [_hidArray[INDEX_CLEAR_MASK_DATA_STATUS] intValue];
    
    if (rawTrack2Length > 0) {
        _track2Present = YES;
        
        if ((clearMaskDataStatus & TRACK_2_CLEAR_MASK) != 0)
            _decryptedLength += rawTrack2Length;
        
        if ((rawTrack2Length % 8) == 0)
            _track2Length = rawTrack2Length;
        else
            _track2Length = (rawTrack2Length / 8 + 1) * 8;
    }
}

- (void)normalizeTrack3Length {
    int rawTrack3Length = [_hidArray[INDEX_TRACK_3_DATA_LENGTH] intValue];
    int clearMaskDataStatus = [_hidArray[INDEX_CLEAR_MASK_DATA_STATUS] intValue];
    
    if (rawTrack3Length > 0) {
        _track3Present = YES;
        
        if ((clearMaskDataStatus & TRACK_3_CLEAR_MASK) != 0)
            _decryptedLength += rawTrack3Length;
        
        if ((rawTrack3Length % 8) == 0)
            _track3Length = rawTrack3Length;
        else
            _track3Length = (rawTrack3Length / 8 + 1) * 8;
    }
}

- (void)extractEncrytpedData {
    [self extractTrack1];
    [self extractTrack2];
    [self extractTrack3];
    [self extractKSN];
}

- (void)extractTrack1 {
    if (_track1Present) {
        for (int i=0; i<_track1Length; i++) {
            [_track1Data addObject:_hidArray[_decryptedLength+i+LENGTH_OF_KSN]];
        }
    }
}

- (void)extractTrack2 {
    if (_track2Present) {
        for (int i=0; i<_track2Length; i++) {
            [_track2Data addObject:_hidArray[_decryptedLength+_track1Length+i+LENGTH_OF_KSN]];
        }
    }
}

- (void)extractTrack3 {
    if (_track3Present) {
        for (int i=0; i<_track3Length; i++) {
            [_track3Data addObject:_hidArray[_decryptedLength+_track1Length+_track2Length+i+LENGTH_OF_KSN]];
        }
    }
}

- (void)extractKSN {
    NSRange range = NSMakeRange(_hidArray.count+INDEX_KSN_START, LENGTH_OF_KSN);
    _ksnArray = [_hidArray subarrayWithRange:range];
}

@end
