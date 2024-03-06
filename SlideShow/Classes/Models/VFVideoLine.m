//
//  VFVideoLine.m
//  VideoFusionProject
//
//  Created by Hua Wan on 4/5/2016.
//  Copyright © 2016 Hua Wan. All rights reserved.
//

#import "VFVideoLine.h"

@implementation VFVideoLine

- (id)init
{
    self = [super init];
    if (self) {
        self.uuidString = @"";
        self.videoAsset = nil;
        self.blurAsset = nil;
        self.videoLineId = 0;
        self.videoVolume = 1.0;
        self.startTime = 0.0;
        self.endTime = 0.0;
        self.degree = 0.0;
        self.backgroundImage = nil;
        self.backgroundUIImage = nil;
        self.transform = CGAffineTransformIdentity;
        self.isHorizontalFlip = NO;
        self.isVerticalFlip = NO;
        self.isTrimmed = YES;
        self.isAspectFill = NO;
        self.scale = 1.0;
        self.offset = CGPointZero;
        self.arrayTextViews = [NSMutableArray array];
        self.arrayImageViews = [NSMutableArray array];
        self.trackID = -1;
        self.blurTrackID = -1;
    }
    return self;
}

@end
