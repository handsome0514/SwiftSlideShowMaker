//
//  SSPlayerController.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const SSPlayerControllerPlayingNotification;
extern NSString* const SSPlayerControllerStoppedNotification;

@class SSProject;
@class SSProjectImageItem;
@class SSPlayer;
@class SSLookupTable;
@class EditViewController;

NS_ASSUME_NONNULL_BEGIN

@interface SSPlayerController : NSObject
+(SSPlayerController*)controllerWithPlayer:(SSPlayer*)player andProject:(SSProject*)project;
@property (nonatomic, strong) EditViewController* editViewCtrl;
@property (nonatomic, strong, readonly) SSProject* project;
@property (nonatomic, strong, readonly) SSPlayer* player;

@property (nonatomic, assign, getter=isMuted) BOOL muted;
@property (nonatomic, assign, readonly, getter=isPlaying) BOOL playing;
-(void)play;
-(void)pause;
-(void)resume;
-(void)stop;
-(void)jump:(NSTimeInterval)duration;

-(void)displayBlank;
-(void)displayFirstImage;
-(void)displayImage:(SSProjectImageItem*)image;
-(void)displayImageForCropping:(SSProjectImageItem*)image cropRegion:(CGRect)cropRegion;
-(void)displayImageForEditing:(SSProjectImageItem*)image;
-(void)previewLookupTable:(NSInteger)lookupTableIndex withItem:(SSProjectImageItem*)item;

-(void)recreateFinalSlideRawImage;

@end

NS_ASSUME_NONNULL_END
