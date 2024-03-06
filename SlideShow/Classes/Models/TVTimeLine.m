//
//  TVTimeLine.m
//  Slideshow
//
//  Created by Hua Wan on 5/20/15.
//  Copyright (c) 2015 Panorama. All rights reserved.
//

#import "TVTimeLine.h"

@implementation TVTimeLine

- (id)init
{
    self = [super init];
    if (self) {
        self.timeLineType = TIMELINE_TYPE_TEXT;
        self.timeLineId = 0;
        self.timeLineText = @"";
        self.musicURL = nil;
        self.timeLineLength = 0;
        self.musicVolume = 1.0;
        self.startTime = 0.0;
        self.endTime = 0.0;
        self.currentTime = 0.0;
    }
    return self;
}

@end
