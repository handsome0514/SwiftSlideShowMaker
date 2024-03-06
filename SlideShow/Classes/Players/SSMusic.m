//
//  SSMusic.m
//  SlideShow
//
//  Created by Arda Ozupek on 29.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSMusic.h"

@implementation SSMusic

#pragma mark - Life Cycle
+(SSMusic*)remoteStockMusicWithURL:(NSURL*)url title:(NSString*)title locked:(BOOL)locked duration:(NSTimeInterval)duration {
    NSAssert(url, @"URL is nil!");
    NSAssert(!url.isFileURL, @"Given url is a local file url!");
    SSMusic* music = [[SSMusic alloc] init];
    music->_url = url;
    music->_title = title;
    music->_type = kSSMusicTypeStock;
    music->_locked = locked;
    music->_duration = duration;
    music->_isRemoteMusic = YES;
    return music;
}

+(SSMusic *)localStockMusicWithName:(NSString *)projectId name:(NSString*)fileName title:(NSString *)title locked:(BOOL)locked {
   
//    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
//    NSAssert(tracks.count, @"Invalid asset type!");
//    AVAssetTrack* track = tracks.firstObject;
//    CMTimeGetSeconds(track.timeRange.duration);
//    NSAssert(duration > 1.0f, @"Given stock music is too short!");
    SSMusic* music = [[SSMusic alloc] init];
    music->_title = title;
    music->_projectId = projectId;
    music->_fileName = fileName;
    music->_type = kSSMusicTypeStock;
    music->_locked = locked;
    music->_isRemoteMusic = NO;
    return music;
}
+(SSMusic *)localStockMusicWithURL:(NSURL *)url title:(NSString *)title locked:(BOOL)locked {
    NSAssert(url, @"URL is nil!");
    NSAssert(url.isFileURL, @"Given url is not a local file url!");
    AVAsset* asset = [AVAsset assetWithURL:url];
//    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
//    NSAssert(tracks.count, @"Invalid asset type!");
//    AVAssetTrack* track = tracks.firstObject;
    NSTimeInterval duration = asset.duration.value;
//    CMTimeGetSeconds(track.timeRange.duration);
//    NSAssert(duration > 1.0f, @"Given stock music is too short!");
    SSMusic* music = [[SSMusic alloc] init];
    music->_asset = asset;
    music->_duration = duration;
    music->_url = url;
    music->_title = title;
    music->_type = kSSMusicTypeStock;
    music->_locked = locked;
    music->_isRemoteMusic = NO;
    return music;
}

-(void)changeToLocal:(NSURL *)url {
    NSAssert(self.type == kSSMusicTypeStock, @"This is not a stock music!");
    NSAssert(self.isRemoteMusic, @"This is not a remote music!");
    NSAssert(url, @"URL is nil!");
    NSAssert(url.isFileURL, @"Given url is not a local file url!");
    AVAsset* asset = [AVAsset assetWithURL:url];
    NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    NSAssert(tracks.count, @"Invalid asset type!");
    AVAssetTrack* track = tracks.firstObject;
    NSTimeInterval duration = CMTimeGetSeconds(track.timeRange.duration);
    NSAssert(duration > 1.0f, @"Given stock music is too short!");
    self->_asset = asset;
    self->_duration = duration;
    self->_url = url;
    self->_isRemoteMusic = NO;
}

+(SSMusic *)libraryMusicWithMediaItem:(MPMediaItem *)mediaItem {
    if (!mediaItem) {
        return nil;
    }
    NSUInteger mediaType = [[mediaItem valueForProperty:MPMediaItemPropertyMediaType] unsignedIntegerValue];
    if (mediaType > MPMediaTypeAnyAudio) {
        return nil;
    }
    NSURL* url = [mediaItem valueForKey:MPMediaItemPropertyAssetURL];
    AVAsset* asset = [AVAsset assetWithURL:url];
    if (@available(iOS 9.2, *)) {
        if (mediaItem.protectedAsset) {
            return nil;
        }
    } else {
        if (asset.hasProtectedContent) {
            return nil;
        }
    }
    NSTimeInterval duration = [[mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    if (duration < 1.0f) {
        return nil;
    }
    NSString* artist = [mediaItem valueForProperty:MPMediaItemPropertyArtist];
    NSString* album = [mediaItem valueForProperty:MPMediaItemPropertyAlbumTitle];
    NSString* title = [mediaItem valueForProperty:MPMediaItemPropertyTitle];
    
    SSMusic* music = [[SSMusic alloc] init];
    music->_mediaItem = mediaItem;
    music->_asset = asset;
    music->_url = url;
    music->_title = title;
    music->_album = album;
    music->_artist = artist;
    music->_duration = duration;
    music->_type = kSSMusicTypeLibrary;
    music->_locked = NO;
    music->_isRemoteMusic = NO;
    return music;
}

@end
