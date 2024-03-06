//
//  SSVideoExporter.m
//  SlideShow
//
//  Created by Arda Ozupek on 15.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSVideoExporter.h"
#import "SSCore.h"
#import <GPUImage/GPUImageMovieWriter.h>
#import <Photos/Photos.h>
#import "SDAVAssetExportSession.h"
#import <architecture/byte_order.h>
#import "ThemeManager.h"
#import "Slideshow-Swift.h"

@interface SSVideoExporter ()
{
    dispatch_semaphore_t renderSemaphore;
    CMTime currentTime;
}
@property (nonatomic, strong) SSMovieWriter* writer;
@property (nonatomic, strong) SSProjectTransitionItem* finalSlideTransition;
@property (nonatomic, strong) SSProjectImageItem* finalSlideImage;
@property (nonatomic, assign, readonly) CGFloat writerTimeScale;
@end


@implementation SSVideoExporter

#pragma mark - Life Cycle
+(SSVideoExporter *)exporterWithProject:(SSProject *)project {
    NSAssert(project, @"Project is nil!");
    SSVideoExporter* exporter = [[SSVideoExporter alloc] initWithProject:project];
    return exporter;
}

-(instancetype)initWithProject:(SSProject*)project {
    self = [super init];
    if (self) {
        self->_project = project;
        self.finalSlideTransition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeDirectional];
        self.finalSlideImage = [SSProjectImageItem itemWithImage:[UIImage imageNamed:@"finalslide.jpg"]];
    }
    return self;
}


#pragma mark - Processing
-(void)exportWithCompletion:(SSVideoExporterCompletionBlock)completion progress:(SSVideoExporterProgressBlock)progress {
    NSAssert(!self.isProcessing, @"Video is already decoding!");
    self->_processing = YES;
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self exportVideo:^(NSURL* videoURL) {
            if (videoURL) {
                [wself renameVideoFile:videoURL];
            }
            SSVideoExporter* sself = wself;
            sself->_processing = NO;
            if (completion) {
                completion(videoURL != nil);
            }
        } progress:^(CGFloat currentProgress) {
            if (progress) {
                progress(currentProgress);
            }
        }];
    });
}

-(void)exportVideo:(void(^)(NSURL* videoURL))completion progress:(void(^)(CGFloat progress))progress {
    __weak typeof(self) wself = self;
    
    NSString* fileName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSURL* url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    DLog(@"Saving to %@", url.absoluteString);
    CGSize previewSize = self.project.settings.outputSize;
    CGSize videoSize = SSVideoOutputSize(self.project.settings.outputRatio);
    
    NSInteger imageCount = self.project.imageItems.count;
    CGFloat exportSizeScale = imageCount <= 15 ? 1.0f :
                              imageCount > 15 && imageCount <= 30 ? 0.75f :
                              imageCount > 30 && imageCount <= 50 ? 0.6f : 0.5f;
    exportSizeScale = 1.0f;
    CGSize exportSize = SSExportOutputSize(self.project.settings.outputRatio);
    exportSize = CGSizeScale(exportSize, exportSizeScale);
    exportSize = CGSizeFixForVideo(exportSize);
    
    [self.finalSlideImage recreateRawImagePictureForSize:videoSize];
    self.writer = [[SSMovieWriter alloc] initWithMovieURL:url size:videoSize];
    self.writer.encodingLiveVideo = NO;
    
    BOOL shouldDisplayLogo = !([[PurchaseManager sharedManager] isPurchasedWithProductId:IAPManagerGetEverythingId] ||
                               [[PurchaseManager sharedManager] isPurchasedWithProductId:IAPManagerRemoveWatermarkId]);
    NSTimeInterval finalSlideTransitionDuration = 2.0f;
    NSTimeInterval finalSlideImageDuration = 3.0f;
    
    BOOL recordingStarted = NO;
    currentTime = kCMTimeInvalid;
    
    dispatch_group_t group = dispatch_group_create();
    BOOL shouldMergeAudio = self.project.musics.count > 0;
    if (shouldMergeAudio) {
        SSAudioProcessor* audioProcessor = [SSAudioProcessor sharedInstance];
        NSTimeInterval duration = self.project.totalDuration;
        if (shouldDisplayLogo) {
            duration += finalSlideTransitionDuration + finalSlideImageDuration;
        }
        AVMutableComposition* composition = [[audioProcessor
                                              createCompositionWithMusics:self.project.musics
                                              length:duration] mutableCopy];
        AVAudioMix* audioMix = [audioProcessor createFadeOut:self.project.musicFadeOutDuration forAsset:composition];
        SDAVAssetExportSession* session = [SDAVAssetExportSession exportSessionWithAsset:composition];
        session.audioSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                  AVLinearPCMBitDepthKey: @(16),
                                  AVLinearPCMIsBigEndianKey: @(NX_BigEndian == NXHostByteOrder()),
                                  AVLinearPCMIsFloatKey: @(NO),
                                  AVLinearPCMIsNonInterleaved: @(NO),
                                  AVNumberOfChannelsKey: @(1),
                                  AVSampleRateKey: @(12000)};
        session.audioMix = audioMix;
        NSString* tempAudioFilename = [NSString stringWithFormat:@"%@.wav", [NSUUID UUID].UUIDString];
        NSURL* tempAudioUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tempAudioFilename]];
        session.outputURL = tempAudioUrl;
        session.outputFileType = AVFileTypeCoreAudioFormat;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [session exportAsynchronouslyWithCompletionHandler:^{
            dispatch_semaphore_signal(semaphore);
        } progressHandler:nil];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (!session.error) {
            AVAsset* asset = [AVAsset assetWithURL:tempAudioUrl];
            AVAssetTrack* audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            if (audioTrack) {
                NSError* readerError = nil;
                AVAssetReader* reader = [AVAssetReader assetReaderWithAsset:asset error:&readerError];
                if (!readerError) {
                    NSDictionary * settings = @{AVFormatIDKey:[NSNumber numberWithInt:kAudioFormatLinearPCM]};
                    AVAssetReaderTrackOutput* output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack
                                                                                                  outputSettings:settings];
                    output.alwaysCopiesSampleData = NO;
                    [reader addOutput:output];
                    [reader startReading];
                    
                    self.writer.shouldPassthroughAudio = NO;
                    self.writer.hasAudioTrack = YES;
                    self.writer.shouldInvalidateAudioSampleWhenDone = YES;
                    [self.writer startRecording];
                    recordingStarted = YES;
                    
                    dispatch_group_enter(group);
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        while (reader.status == AVAssetReaderStatusReading) {
                            CMSampleBufferRef sample = [output copyNextSampleBuffer];
                            if (!sample) {
                                DLog(@"Audio completed");
                                dispatch_group_leave(group);
                                break;
                            }
                            
                            [wself.writer processAudioBuffer:sample];
                            CFRelease(sample);
                        }
                    });
                }
            }
        }
    }
    
    DLog(@"Video processing...");
    if (!recordingStarted) {
        [self.writer startRecording];
    }
    
    dispatch_group_enter(group);
    
    NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
    options[kSSFrameDurationKey] = [NSValue valueWithCMTime:kCMTimeInvalid];
    if (shouldDisplayLogo) {
        dispatch_semaphore_t watermarkSemaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            SSPicture* wateramarkPicture = [[SSEffectManager sharedInstance] createWatermark:exportSize];
            options[kSSWatermarkPictureKey] = wateramarkPicture;
            dispatch_semaphore_signal(watermarkSemaphore);
        });
        dispatch_semaphore_wait(watermarkSemaphore, DISPATCH_TIME_FOREVER);
    }
    
    CMTime imageDuration = CMTimeMakeWithSeconds(self.project.imageDuration, self.writerTimeScale);
    CMTime frameDuration = CMTimeMakeWithSeconds(1.0f / self.project.framesPerSecond, self.writerTimeScale);
    NSInteger transitionFrameCount = self.project.transitionDuration * self.project.framesPerSecond;
    
    NSInteger finalSlideTransitionFrameCount = finalSlideTransitionDuration * self.project.framesPerSecond;
    
    NSInteger totalRenderCount = transitionFrameCount * self.project.transitionItems.count;
    totalRenderCount += self.project.imageItems.count;
    if (shouldDisplayLogo) {
        totalRenderCount += finalSlideTransitionFrameCount + 1;
    }
    NSInteger currentRenderCount = 0;
    
    BOOL dynamicTextureSize = NO;
    
    for (NSInteger i=0; i<self.project.imageItems.count; i++) {
        SSProjectImageItem* image = self.project.imageItems[i];
        
        if (dynamicTextureSize) {
            if (!CGSizeEqualToSize(image.rawImagePicture.outputImageSize, exportSize)) {
                [image recreateRawImagePictureForSize:exportSize];
            }
        }
        
        options[kSSFrameDurationKey] = [NSValue valueWithCMTime:imageDuration];
        [self generateFrame:image options:options];
        if (progress) {
            progress(currentRenderCount / (CGFloat)totalRenderCount);
        }
        currentRenderCount++;
        
        SSProjectTransitionItem* transition = i == self.project.imageItems.count - 1 ? nil : self.project.transitionItems[i];
        
        if (transition) {
            SSProjectImageItem* nextImage = self.project.imageItems[i+1];
            
            if (dynamicTextureSize) {
                if (!CGSizeEqualToSize(nextImage.rawImagePicture.outputImageSize, exportSize)) {
                    [nextImage recreateRawImagePictureForSize:exportSize];
                }
            }
            
            for (NSInteger f=0; f<transitionFrameCount; f++) {
                CGFloat transitionProgress = f / (CGFloat)transitionFrameCount;
                options[kSSFrameDurationKey] = [NSValue valueWithCMTime:frameDuration];
                [self generateTransition:transition from:image to:nextImage progress:transitionProgress options:options];
                if (progress) {
                    progress(currentRenderCount / (CGFloat)totalRenderCount);
                }
                currentRenderCount++;
            }
        }
        else if (!shouldDisplayLogo) {
            options[kSSFrameDurationKey] = [NSValue valueWithCMTime:frameDuration];
            [self generateFrame:image options:options];
            DLog(@"Video completed!");
            dispatch_group_leave(group);
        }
        
        if (dynamicTextureSize) {
            if (!CGSizeEqualToSize(image.rawImagePicture.outputImageSize, CGSizeMake(8, 8))) {
                [image recreateRawImagePictureForSize:CGSizeMake(8,8)];
            }
        }
    }
    
    if (shouldDisplayLogo) {
        [options removeObjectForKey:kSSWatermarkPictureKey];
        for (NSInteger i=0; i<finalSlideTransitionFrameCount; i++) {
            CGFloat transitionProgress = i / (CGFloat)finalSlideTransitionFrameCount;
            options[kSSFrameDurationKey] = [NSValue valueWithCMTime:frameDuration];
            [self generateTransition:self.finalSlideTransition from:self.project.imageItems.lastObject to:self.finalSlideImage progress:transitionProgress options:options];
            if (progress) {
                progress(currentRenderCount / (CGFloat)totalRenderCount);
            }
            currentRenderCount++;
        }
        
        CMTime finalSlideDuration = CMTimeMakeWithSeconds(finalSlideImageDuration, self.writerTimeScale);
        
        options[kSSFrameDurationKey] = [NSValue valueWithCMTime:finalSlideDuration];
        [self generateFrame:self.finalSlideImage options:options];
        DLog(@"Video completed!");
        
        if (progress) {
            progress(currentRenderCount / (CGFloat)totalRenderCount);
        }
        currentRenderCount++;
        dispatch_group_leave(group);
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
        
        [wself.writer finishRecordingWithCompletionHandler:^{
            NSTimeInterval duration = CMTimeGetSeconds(wself.writer.duration);
            BOOL succeed = duration > 0.0f;
            if (!succeed) {
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
                DLog(@"Failed to save processed framebuffers!");
            } else {
                DLog(@"Wrote %f.02 secs of framebuffers", duration);
            }
            
            SSVideoExporter* exporter = wself;
            exporter->_writer = nil;
            
            if (dynamicTextureSize) {
                [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
                for (SSProjectImageItem* image in self.project.imageItems) {
                    [image recreateRawImagePictureForSize:previewSize];
                }
                [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
            } else {
                [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
            }
            
            if (completion) {
                completion(succeed ? url : nil);
            }
        }];
    });
}

-(BOOL)renameVideoFile:(NSURL*)url {
    NSString* filePath = self.project.exportedVideoPath;
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]) {
        NSError* error = nil;
        [manager removeItemAtPath:filePath error:&error];
        if (error) {
            DLog(@"Failed to remove previous project video! %@", error.localizedDescription);
            return NO;
        }
    }
    
    NSError* error = nil;
    [manager moveItemAtPath:url.path toPath:filePath error:&error];
    if (error) {
        DLog(@"Failed to move temp video to project video! %@", error.localizedDescription);
        return NO;
    }
    
    return YES;
}

-(void)clear {
    NSAssert(!self.isProcessing, @"Can not clear while processing!");
    self.writer = nil;
    currentTime = kCMTimeInvalid;
}


#pragma mark - Render Commands
-(void)generateFrame:(SSProjectImageItem*)image options:(NSDictionary*)options {
    __weak typeof(self) wself = self;
    runSynchronouslyOnContextQueue(self.writer.movieWriterContext, ^{
        SSVideoExporter* sself = wself;
        sself->renderSemaphore = dispatch_semaphore_create(0);
        [[SSEffectProcessor sharedInstance] generateFrameForImage:image toPlayer:self options:options];
    });
    dispatch_semaphore_wait(renderSemaphore, DISPATCH_TIME_FOREVER);
}

-(void)generateTransition:(SSProjectTransitionItem*)transition from:(SSProjectImageItem*)from to:(SSProjectImageItem*)to progress:(CGFloat)progress options:(NSDictionary*)options {
    __weak typeof(self) wself = self;
    runSynchronouslyOnContextQueue(self.writer.movieWriterContext, ^{
        SSVideoExporter* sself = wself;
        sself->renderSemaphore = dispatch_semaphore_create(0);
        [[SSEffectProcessor sharedInstance] generateFrameForTransition:transition from:from to:to progress:progress player:self fromOptions:options toOption:nil];
    });
    dispatch_semaphore_wait(renderSemaphore, DISPATCH_TIME_FOREVER);
}


#pragma mark - GPUImageInput
-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
#define RENDER_ALL_FRAMES
#ifdef RENDER_ALL_FRAMES
    NSTimeInterval duration = CMTimeGetSeconds(frameTime);
    NSInteger frameCount = duration * self.writerTimeScale;
    CMTime frameDuration = CMTimeMakeWithSeconds(1.0f / self.project.framesPerSecond, self.writerTimeScale);
    
    if (CMTIME_IS_INVALID(currentTime)) {
        currentTime = CMTimeMake(1, self.writerTimeScale);
    }
    
    NSMutableArray<NSValue*>* frameTimes = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<frameCount; i++) {
        NSValue* value = [NSValue valueWithCMTime:currentTime];
        [frameTimes addObject:value];
        currentTime = CMTimeAdd(currentTime, frameDuration);
    }
    if (frameTimes.count > 6) {
        [frameTimes removeObjectsInRange:NSMakeRange(3, frameTimes.count - 7)];
    }
    __weak typeof(self) wself = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
        [wself.writer newFramesReadyAtTimes:frameTimes atIndex:textureIndex];
    });
    dispatch_semaphore_signal(renderSemaphore);
#else
    if (CMTIME_IS_INVALID(currentTime)) {
        currentTime = CMTimeMake(1, self.writerTimeScale);
    }
    __weak typeof(self) wself = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
        [wself.writer newFrameReadyAtTime:currentTime atIndex:textureIndex];
    });
    dispatch_semaphore_signal(renderSemaphore);
    currentTime = CMTimeAdd(currentTime, frameTime);
#endif
}

-(NSInteger)nextAvailableTextureIndex {
    return 0;
}

-(void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    [self.writer setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
}

-(void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
    [self.writer setInputRotation:newInputRotation atIndex:textureIndex];
}

-(void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [self.writer setInputSize:newSize atIndex:textureIndex];
}

-(CGSize)maximumOutputSize {
    return [self.writer maximumOutputSize];
}

-(void)endProcessing {
    [self.writer endProcessing];
}

-(BOOL)shouldIgnoreUpdatesToThisTarget {
    return [self.writer shouldIgnoreUpdatesToThisTarget];
}

-(BOOL)wantsMonochromeInput {
    return [self.writer wantsMonochromeInput];
}

-(void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {
    [self.writer setCurrentlyReceivingMonochromeInput:newValue];
}

-(BOOL)enabled {
    return self.writer.enabled;
}


#pragma mark - Helper
-(CGFloat)writerTimeScale {
    return self.project.framesPerSecond;
}
@end
