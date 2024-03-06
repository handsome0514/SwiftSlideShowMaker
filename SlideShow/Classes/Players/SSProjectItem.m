//
//  SSProjectItem.m
//  SlideShow
//
//  Created by Arda Ozupek on 30.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectItem.h"

@implementation SSProjectItem

#pragma mark - Life Cycle
-(instancetype)init {
    self = [super init];
    if (self) {
        self->_itemId = [NSUUID UUID].UUIDString;
        self->_duration = 1.0f;
    }
    return self;
}

-(void)dealloc {
    DLog(@"-[%@ dealloc]", NSStringFromClass([self class]));
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectItem* item = [[[self class] allocWithZone:zone] init];
    if (item) {
        item->_itemId = self.itemId;
        item->_duration = self.duration;
    }
    return item;
}


#pragma mark - Compare
-(BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object isMemberOfClass:[self class]]) {
        SSProjectItem* item = object;
        if ([item.itemId isEqualToString:self.itemId]) {
            return YES;
        }
    }
    return NO;
}

@end
