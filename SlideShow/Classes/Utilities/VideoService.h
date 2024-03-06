//
// Created by user on 1/20/14.
// Copyright (c) 2014 Prophonix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define VIDEO_SIZE_WIDTH    720
#define VIDEO_SIZE_HEIGHT   1280

@class Project;

typedef void (^HandlerBlock)(NSURL* videoURL);

@interface VideoService : NSObject

@property (nonatomic, retain) NSURL *videoURL;
@property (nonatomic, retain) NSURL *audioURL;
@property (nonatomic, assign) CMTime cTime;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, copy)   HandlerBlock handlerBlock;
@property (nonatomic, assign) CGFloat volume;
@property (nonatomic, retain) AVAsset *videoAsset;
@property (nonatomic, retain) NSArray *arrayTimeLines;
@property (nonatomic, retain) NSArray *arrayVideoLines;
@property (nonatomic, assign) CGFloat length;
@property (nonatomic, assign) BOOL isWatermark;
@property (nonatomic, assign) BOOL isFadeIn;
@property (nonatomic, assign) BOOL isFadeOut;
@property (nonatomic, assign) NSInteger backgroundTrackID;
@property (nonatomic, strong) Project *project;

+ (VideoService *)shared;

+ (void)loadVideo:(NSURL *)videoURL completion:(void(^)(NSURL *outputURL))outputHandler;
+ (AVAssetExportSession *)trimVideo:(AVAsset *)videoAsset isOutSide:(BOOL)isOutSide startTime:(CMTime)startTime endTime:(CMTime)endTime completion:(void(^)(NSURL *outputURL))completionHandler;
+ (void)saveVideo:(NSURL *)videoURL completion:(void(^)(BOOL, NSURL *))completionHandler;
+ (void)colorVideo:(UIColor *)color completion:(void(^)(BOOL, NSURL *))completionHandler;
+ (AVAssetExportSession *)saveVideo:(AVAsset *)asset path:(NSString *)path completion:(void(^)(BOOL, NSError *))completionHandler;

- (void)applyTextViews:(NSArray*)textViews;
- (void)applyImageViews:(NSArray*)imageViews;
- (void)applyGraphicsViews:(NSArray *)graphicsViews;
- (void)saveVideo:(CGSize)renderSize save:(BOOL)needsToBeSaved colorVideoURL:(NSURL *)colorVideoURL;
- (CMTime)maxDuration;
- (void)reset;
- (AVAssetExportSession *)blurVideo:(AVAsset *)asset path:(NSString *)path completion:(void(^)(BOOL))completionHandler;
- (UIImage*) getFrame:(AVAsset*)movieAsset;
- (NSMutableArray*) getFrames:(AVAsset*)movieAsset;

@end
