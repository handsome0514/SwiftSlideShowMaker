//
//  SSProject.h
//  SlideShow
//
//  Created by Arda Ozupek on 23.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SSProjectSettings;
@class SSProjectImageItem;
@class SSProjectTransitionItem;
@class SSMusic;
@class Project;

@interface SSProject : NSObject <NSCoding>

+(SSProject*)project;
@property (nonatomic, copy) NSString* projectId;
@property (nonatomic, copy) NSString* createdTime;
@property (nonatomic, assign) int themeIndex;

@property (nonatomic, strong) SSProjectSettings* settings;
-(void)applySettings:(SSProjectSettings*)settings;


@property (nonatomic, strong) NSArray<SSProjectImageItem*>* imageItems;
-(SSProjectImageItem*)insertImage:(UIImage *)image insertNum:(int)index;
-(SSProjectImageItem*)addImage:(UIImage*)image;
- (SSProjectImageItem *)addVideo:(UIImage *)image url:(NSURL *)videoURL duration:(CMTime)duration generator:(AVAssetImageGenerator*)generator lastImg:(UIImage*)lastImage;
- (SSProjectImageItem *)insertVideo:(UIImage *)image insertNum:(int)index url:(NSURL *)videoURL duration:(CMTime)duration generator:(AVAssetImageGenerator*)generator lastImg:(UIImage*)lastImage;
-(void)removeImage:(SSProjectImageItem*)image;
-(void)saveImage:(SSProjectImageItem*)image;
-(void)replaceImageAtIndex:(NSInteger)fromIndex withImageAtIndex:(NSInteger)toIndex;
-(void)updateLookupTables:(SSProjectImageItem* _Nullable)item;


@property (nonatomic, strong) NSArray<SSProjectTransitionItem*>* transitionItems;
-(void)updateTransition:(SSProjectTransitionItem*)transition applyToAll:(BOOL)applyToAll;
-(void)updateTheme:(int)theme;

@property (nonatomic, strong) NSArray<SSMusic*>* musics;
@property (nonatomic, assign) NSTimeInterval musicFadeOutDuration;
-(void)updateMusics:(NSArray<SSMusic*>*)musics;
-(AVPlayerItem*)createPlayerItemForCurrentMusics;
-(NSInteger)indexTransition:(NSInteger)frame;

@property (nonatomic, assign) NSTimeInterval imageDuration;
@property (nonatomic, assign) NSTimeInterval transitionDuration;
@property (nonatomic, assign) NSTimeInterval totalDuration;
@property (nonatomic, assign) CGFloat framesPerSecond;
@property (nonatomic, assign) NSInteger totalFrameCount;

@property (nonatomic, assign) BOOL transitionAppliedToAll;
@property (nonatomic, assign) BOOL lookupTableAppliedToAll;
@property (nonatomic, assign, readonly) int selectedTheme;

-(NSArray*)isVideo:(NSInteger)frame;
-(NSArray*)objectDataOfFrame:(NSInteger)frame;
-(void)calculateDurations;

@property (nonatomic, copy) NSString* exportedVideoPath;
@end

NS_ASSUME_NONNULL_END
