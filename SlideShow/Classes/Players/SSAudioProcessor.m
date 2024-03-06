//
//  SSAudioProcessor.m
//  SlideShow
//
//  Created by Arda Ozupek on 12.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSAudioProcessor.h"
#import "SSCore.h"

NSString* const SSAudioProcessorCompositionKey = @"composition";
NSString* const SSAudioProcessorAudioMixKey = @"audioMix";
NSString* const SSAudioProcessorFadeOutDurationKey = @"fadeOutDuration";

@implementation SSAudioProcessor

#pragma mark - Life Cycle
+(SSAudioProcessor *)sharedInstance {
    static SSAudioProcessor* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SSAudioProcessor alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


#pragma mark - Composition
-(AVComposition*)createCompositionWithMusics:(NSArray<SSMusic*>*)musics length:(NSTimeInterval)length {
    if (!musics.count) {
        return nil;
    }
    AVMutableComposition* composition = [AVMutableComposition composition];
    AVMutableCompositionTrack* audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime currentTime = kCMTimeZero;
    bool stop = false;
    while(!stop) {
        for (SSMusic* music in musics) {
            NSURL *url = [[NSURL alloc] initWithString:music.url.absoluteString];
            AVAsset* asset = [AVAsset assetWithURL:url];
            NSArray<AVAssetTrack*>* tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            NSAssert(tracks.count, @"Given asset does not contain an audio track! Skipping...");
            NSError* error = nil;
            
            // MINHTH - fake audio ratio by change 1 -> 30
            CMTime assetDuration = CMTimeMultiplyByRatio(asset.duration, 1, 1);
            BOOL shouldBreak = NO;
            if (length > 0.0) {
                NSTimeInterval totalTime = CMTimeGetSeconds(CMTimeAdd(assetDuration, currentTime));
                if (totalTime > length) {
                    assetDuration = CMTimeSubtract(assetDuration, CMTimeMakeWithSeconds(totalTime - length, 100000));
                    shouldBreak = YES;
                    stop = true;
                }
            }
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, assetDuration)
                                ofTrack:tracks.firstObject
                                 atTime:currentTime
                                  error:&error];
            NSAssert(!error, @"Error while inserting music to the composition!");
            currentTime = CMTimeAdd(currentTime, assetDuration);
            if (shouldBreak) {
                break;
            }
        }
    }
    
    
    NSTimeInterval currentDuration = CMTimeGetSeconds(currentTime);
    if (length > 0.0 && currentDuration < length) {
        NSTimeInterval remainingDuration = length - currentDuration;
        DLog(@"Adding %f secs of silence to the audio composition to fill the lenght.", remainingDuration);
        NSString* path = [[NSBundle mainBundle] pathForResource:@"silence" ofType:@"mp3"];
        AVAsset* silence = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
        AVAssetTrack* silenceTrack = [silence tracksWithMediaType:AVMediaTypeAudio].firstObject;
        NSAssert(silenceTrack, @"Error while creating silence tail!");
        NSTimeInterval silenceAssetDuration = CMTimeGetSeconds(silence.duration);
        NSError* error = nil;
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, silence.duration)
                            ofTrack:silenceTrack
                             atTime:CMTimeAdd(currentTime, CMTimeMakeWithSeconds(remainingDuration - silenceAssetDuration, 100000))
                              error:&error];
        NSAssert(!error, @"Error while adding silence tail!");
    }
    return [composition copy];
}

-(AVAudioMix*)createFadeOut:(NSTimeInterval)fadeOutDuration forAsset:(AVAsset*)asset {
    NSArray<AVAssetTrack*>* tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    NSAssert(tracks.count > 0, @"Given asset does not contain any audio tracks!");
    AVAssetTrack* track = tracks.firstObject;
    AVMutableAudioMix* audioMix = [AVMutableAudioMix audioMix];
    AVMutableAudioMixInputParameters* fadeOutParam = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    CMTime fadeOut = CMTimeMakeWithSeconds(MIN(fadeOutDuration, CMTimeGetSeconds(asset.duration)), 100000);
    CMTime startTime = CMTimeSubtract(asset.duration, fadeOut);
    [fadeOutParam setVolumeRampFromStartVolume:1.0f toEndVolume:0.0f timeRange:CMTimeRangeMake(startTime, fadeOut)];
    audioMix.inputParameters = @[fadeOutParam];
    return audioMix;
}

@end
