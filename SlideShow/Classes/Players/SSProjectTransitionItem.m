//
//  SSProjectTransitionItem.m
//  SlideShow
//
//  Created by Arda Ozupek on 30.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectTransitionItem.h"
#import "SSCore.h"

@implementation SSProjectTransitionItem

#pragma mark - Life Cycle
+(SSProjectTransitionItem *)itemWithTransitionType:(SSTransitionType)type {
    SSProjectTransitionItem* item = [[SSProjectTransitionItem alloc] init];
    item->_selectedTransitionType = type;
    return item;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self->_shouldRandomizeTransition = YES;
        self->_shouldUseAllTransitions = NO;
        [self updateRandomizedTransitiedType];
    }
    return self;
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.selectedTransitionType forKey:@"selectedTransitionType"];
    [aCoder encodeInteger:self.randomizedTransitionType forKey:@"randomizedTransitionType"];
    [aCoder encodeBool:self.shouldRandomizeTransition forKey:@"shouldRandomizeTransition"];
    [aCoder encodeBool:self.shouldUseAllTransitions forKey:@"shouldUseAllTransitions"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self->_selectedTransitionType = [aDecoder decodeIntegerForKey:@"selectedTransitionType"];
        self->_randomizedTransitionType = [aDecoder decodeIntegerForKey:@"randomizedTransitionType"];
        self->_shouldRandomizeTransition = [aDecoder decodeBoolForKey:@"shouldRandomizeTransition"];
        self->_shouldUseAllTransitions = [aDecoder decodeBoolForKey:@"shouldUseAllTransitions"];
    }
    return self;
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectTransitionItem* item = [super copyWithZone:zone];
    if (item) {
        item->_selectedTransitionType = self.selectedTransitionType;
        item->_randomizedTransitionType = self.randomizedTransitionType;
        item->_shouldRandomizeTransition = self.shouldRandomizeTransition;
        item->_shouldUseAllTransitions = self.shouldUseAllTransitions;
    }
    return item;
}


#pragma mark - Transition Type
-(void)setShouldUseAllTransitions:(BOOL)shouldUseAllTransitions {
    _shouldUseAllTransitions = shouldUseAllTransitions;
    [self updateRandomizedTransitiedType];
}

-(void)updateRandomizedTransitiedType {
    if (self.shouldUseAllTransitions) {
        self->_randomizedTransitionType = [[SSEffectManager sharedInstance] randomTransitionType];
    } else {
        self->_randomizedTransitionType = [[SSEffectManager sharedInstance] randomFreeTransitionType];
    }
}

-(SSTransitionType)transitionType {
    return self.shouldRandomizeTransition ? self.randomizedTransitionType : self.selectedTransitionType;
}

@end
