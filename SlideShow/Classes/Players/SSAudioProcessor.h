//
//  SSAudioProcessor.h
//  SlideShow
//
//  Created by Arda Ozupek on 12.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern NSString* const SSAudioProcessorCompositionKey;
extern NSString* const SSAudioProcessorAudioMixKey;
extern NSString* const SSAudioProcessorFadeOutDurationKey;

@class SSMusic;

NS_ASSUME_NONNULL_BEGIN

@interface SSAudioProcessor : NSObject
+(SSAudioProcessor*)sharedInstance;
-(AVComposition*)createCompositionWithMusics:(NSArray<SSMusic*>*)musics length:(NSTimeInterval)length;
-(AVAudioMix*)createFadeOut:(NSTimeInterval)fadeOutDuration forAsset:(AVAsset*)asset;
@end

NS_ASSUME_NONNULL_END
