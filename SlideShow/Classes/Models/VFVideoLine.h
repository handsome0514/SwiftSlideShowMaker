//
//  VFVideoLine.h
//  VideoFusionProject
//
//  Created by Hua Wan on 4/5/2016.
//  Copyright © 2016 Hua Wan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VFVideoLine : NSObject

@property (nonatomic, strong) NSString *uuidString;
@property (nonatomic, assign) NSInteger videoLineId;
@property (nonatomic, retain) AVAsset *videoAsset;
@property (nonatomic, retain) UIImage *imageAsset;
@property (nonatomic, retain) AVAsset *blurAsset;
@property (nonatomic, assign) CGFloat imageDuration;
@property (nonatomic, assign) CGFloat videoVolume;
@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat endTime;
@property (nonatomic, assign) CGFloat degree;
@property (nonatomic, strong) CIImage *backgroundImage;
@property (nonatomic, strong) UIImage *backgroundUIImage;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) BOOL isHorizontalFlip;
@property (nonatomic, assign) BOOL isVerticalFlip;
@property (nonatomic, assign) BOOL isTrimmed;
@property (nonatomic, assign) BOOL isAspectFill;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, strong) NSMutableArray *arrayTextViews;
@property (nonatomic, strong) NSMutableArray *arrayImageViews;
@property (nonatomic, assign) NSInteger trackID;
@property (nonatomic, assign) NSInteger blurTrackID;

@end
