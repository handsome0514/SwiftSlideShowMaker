//
//  SSMusic.h
//  SlideShow
//
//  Created by Arda Ozupek on 29.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SSMusicType) {
    kSSMusicTypeStock = 0,
    kSSMusicTypeLibrary = 1,
    kSSMusicTypeItunesStore = 2
};

@interface SSMusic : NSObject

+(SSMusic *)localStockMusicWithName:(NSString *)projectId name:(NSString*)fileName title:(NSString *)title locked:(BOOL)locked;
+(SSMusic *)localStockMusicWithURL:(NSURL *)url title:(NSString *)title locked:(BOOL)locked;
+(SSMusic*)remoteStockMusicWithURL:(NSURL*)url title:(NSString*)title locked:(BOOL)locked duration:(NSTimeInterval)duration;
+(SSMusic *)libraryMusicWithMediaItem:(MPMediaItem *)mediaItem;
@property (nonatomic, strong, readonly) AVAsset* asset;
@property (nonatomic, strong, readonly) MPMediaItem* mediaItem;
@property (nonatomic, strong, readonly) NSURL* url;
@property (nonatomic, copy, readonly) NSString* title;
@property (nonatomic, copy, readonly) NSString* projectId;
@property (nonatomic, copy, readonly) NSString* fileName;
@property (nonatomic, assign, readonly) NSTimeInterval duration;
@property (nonatomic, assign, readonly) SSMusicType type;
@property (nonatomic, copy, readonly, nullable) NSString* artist;
@property (nonatomic, copy, readonly, nullable) NSString* album;
@property (nonatomic, assign, readonly, getter=isLocked) BOOL locked;
@property (nonatomic, assign, readonly) BOOL isRemoteMusic;
-(void)changeToLocal:(NSURL*)url;

@end

NS_ASSUME_NONNULL_END
