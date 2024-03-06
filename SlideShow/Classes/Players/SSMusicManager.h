//
//  SSMusicManager.h
//  SlideShow
//
//  Created by Arda Ozupek on 29.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class SSMusic;

@interface SSMusicManager : NSObject
+(SSMusicManager*)sharedInstance;
@property (nonatomic, strong, readonly) NSArray<SSMusic*>* libraryMusics;
@property (nonatomic, strong, readonly) NSArray<SSMusic*>* stockMusics;
@property (nonatomic, assign, readonly) BOOL didMediaLibraryPermissionGranted;
-(void)handleMediaLibraryPermission:(UIViewController*)viewController completion:(void(^)(void))completion;
-(void)loadLibraryMusics:(void(^)(void))completion;
-(SSMusic*)findStockMusic:(NSString*)title;
-(SSMusic*)findLibraryMusic:(MPMediaEntityPersistentID)mediaEntityId;
-(void)downloadStockMusic:(SSMusic*)music progress:(void(^)(CGFloat))progress completion:(void(^)(BOOL))completion;
@end
