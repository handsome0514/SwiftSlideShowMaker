//
//  TVTimeLine.h
//  Slideshow
//
//  Created by Hua Wan on 7/25/14.
//  Copyright (c) 2014 Panorama. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    TIMELINE_TYPE_TEXT = 0,
    TIMELINE_TYPE_MUSIC = 1,
} TIMELINE_TYPE;

@interface TVTimeLine : NSObject

@property (nonatomic, assign) TIMELINE_TYPE timeLineType;
@property (nonatomic, assign) NSInteger timeLineId;
@property (nonatomic, retain) NSString *timeLineText;
@property (nonatomic, retain) NSURL *musicURL;
@property (nonatomic, assign) NSInteger timeLineLength;
@property (nonatomic, assign) CGFloat musicVolume;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;
@property (nonatomic, assign) CGFloat currentTime;

@property (nonatomic, assign) BOOL isFadeIn;
@property (nonatomic, assign) BOOL isFadeOut;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGFloat musicStartTime;
@property (nonatomic, assign) CGFloat musicEndTime;

@end
