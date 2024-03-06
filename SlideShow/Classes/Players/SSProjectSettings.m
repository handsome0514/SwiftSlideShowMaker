//
//  SSProjectSettings.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectSettings.h"

@implementation SSProjectSettings

#pragma mark - Life Cycle
-(instancetype)init {
    self = [super init];
    if (self) {
        _outputRatio = kSSOutputRatio1_1;
        _durationType = kSSDurationTypeFixedPhotoDuration;
        _fixedPhotoDuration = 4.0f;
        _fixedTransitionDuration = 0.0f;
        _fixedTotalDuration = 15.0f;
    }
    return self;
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.outputRatio forKey:@"outputRatio"];
    [aCoder encodeInteger:self.durationType forKey:@"durationType"];
    [aCoder encodeDouble:self.fixedPhotoDuration forKey:@"fixedPhotoDuration"];
    [aCoder encodeDouble:self.fixedTransitionDuration forKey:@"fixedTransitionDuration"];
    [aCoder encodeDouble:self.fixedTotalDuration forKey:@"fixedTotalDuration"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.outputRatio = [aDecoder decodeIntegerForKey:@"outputRatio"];
        self.durationType = [aDecoder decodeIntegerForKey:@"durationType"];
        self.fixedPhotoDuration = [aDecoder decodeDoubleForKey:@"fixedPhotoDuration"];
        self.fixedTransitionDuration = [aDecoder decodeDoubleForKey:@"fixedTransitionDuration"];
        self.fixedTotalDuration = [aDecoder decodeDoubleForKey:@"fixedTotalDuration"];
    }
    return self;
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectSettings* settings = [[SSProjectSettings alloc] init];
    settings->_outputRatio = self.outputRatio;
    settings->_durationType = self.durationType;
    settings->_fixedPhotoDuration = self.fixedPhotoDuration;
    settings->_fixedTransitionDuration = self.fixedTransitionDuration;
    settings->_fixedTotalDuration = self.fixedTotalDuration;
    return settings;
}


#pragma mark - Getters
-(CGSize)outputSize {
    return SSPreviewOutputSize(self.outputRatio);
}

@end
