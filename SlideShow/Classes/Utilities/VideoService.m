//
// Created by user on 1/20/14.
// Copyright (c) 2014 Prophonix. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "VideoService.h"
#import "TVTextView.h"
#import "TVImageView.h"
#import "SVProgressHUD.h"
#import "TVTimeLine.h"
#import "VFVideoLine.h"
#import "UIImage+Resize.h"
#import "SlideShow-Swift.h"
#import <Photos/Photos.h>

@interface VideoService()

@property (nonatomic, retain) NSArray* textViews;
@property (nonatomic, retain) NSArray* graphicsViews;
@property (nonatomic, retain) AVAsset *audioAsset;
@property (nonatomic, retain) NSMutableArray* audioMixParams;
@property (nonatomic, assign) CMTime audioTime;

@end

static int trimIndex = 0;
static int cropIndex = 0;

@implementation VideoService

+ (id)shared
{
    static dispatch_once_t oncePredicate;
    static VideoService *sharedInstance = nil;
    
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[VideoService alloc] init];
        [sharedInstance reset];
    });
    return sharedInstance;
}

+ (void)loadVideo:(NSURL *)videoURL completion:(void(^)(NSURL *outputURL))outputHandler
{
    AVAsset *inputAsset = [AVAsset assetWithURL:videoURL];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = assetTrack.naturalSize;
    // duration
    if (inputAsset != nil)
    {
        // VIDEO TRACK
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSArray *videoDataSourceArray = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                            ofTrack:videoDataSourceArray[0]
                             atTime:kCMTimeZero
                              error:&error];
        if (error)
        {
            NSLog(@"Insertion error: %@", error);
            outputHandler(nil);
            return;
        }
        
        // AUDIO TRACK
        NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeAudio]];
        if (arrayAudioDataSources.count > 0)
        {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                                ofTrack:arrayAudioDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                outputHandler(nil);
                return;
            }
        }
        
        layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    }
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, inputAsset.duration);
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = [[VideoService shared] naturalSize:assetTrack];
    
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LoadVideo.m4v"];
    unlink([videoPath UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:videoPath];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, inputAsset.duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         BOOL success = YES;
         switch ([exporter status]) {
             case AVAssetExportSessionStatusCompleted:
                 success = YES;
                 break;
             case AVAssetExportSessionStatusFailed:
                 success = NO;
                 NSLog(@"input videos - failed: %@", [[exporter error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 success = NO;
                 NSLog(@"input videos - canceled");
                 break;
             default:
                 success = NO;
                 break;
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (outputHandler == nil)
                 return;
             if (success == YES)
                 outputHandler(videoOutputURL);
             else
                 outputHandler(nil);
         });
     }];
}

+ (AVAssetExportSession *)trimVideo:(AVAsset *)videoAsset isOutSide:(BOOL)isOutSide startTime:(CMTime)startTime endTime:(CMTime)endTime completion:(void(^)(NSURL *outputURL))completionHandler
{
    if (videoAsset == nil)
    {
        if (completionHandler)
            completionHandler(nil);
        return nil;
    }
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    NSMutableArray *layerInstructions = [NSMutableArray array];
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = [[VideoService shared] naturalSize:assetTrack];
    // duration
    CMTime trimDuration = kCMTimeZero;
    if(videoAsset != nil)
    {
        // VIDEO TRACK
        if (isOutSide == YES)
        {
            trimDuration = CMTimeSubtract(endTime, startTime);
            videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeVideo]];
            NSError *error = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(startTime, trimDuration)
                                ofTrack:arrayVideoDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                completionHandler(nil);
                return nil;
            }
            
            // AUDIO TRACK
            NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeAudio]];
            if (arrayAudioDataSources.count > 0)
            {
                AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                error = nil;
                [audioTrack insertTimeRange:CMTimeRangeMake(startTime, trimDuration)
                                    ofTrack:arrayAudioDataSources[0]
                                     atTime:kCMTimeZero
                                      error:&error];
                if (error)
                {
                    NSLog(@"Insertion error: %@", error);
                    completionHandler(nil);
                    return nil;
                }
            }
            
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            CGAffineTransform transform = CGAffineTransformIdentity;
            [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
            [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
            
            [layerInstructions addObject:layerInstruction];
        }
        else
        {
            trimDuration = CMTimeSubtract(endTime, startTime);
            trimDuration = CMTimeSubtract(videoAsset.duration, trimDuration);
            videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeVideo]];
            NSError *error = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, startTime)
                                ofTrack:arrayVideoDataSources[0]
                                 atTime:kCMTimeZero
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                completionHandler(nil);
                return nil;
            }
            
            // AUDIO TRACK
            NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[videoAsset tracksWithMediaType:AVMediaTypeAudio]];
            if (arrayAudioDataSources.count > 0)
            {
                AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                error = nil;
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, startTime)
                                    ofTrack:arrayAudioDataSources[0]
                                     atTime:kCMTimeZero
                                      error:&error];
                if (error)
                {
                    NSLog(@"Insertion error: %@", error);
                    completionHandler(nil);
                    return nil;
                }
            }
            
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            CGAffineTransform transform = CGAffineTransformIdentity;
            [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
            [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
            [layerInstruction setOpacity:0.0 atTime:startTime];
            
            [layerInstructions addObject:layerInstruction];
            
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(endTime, CMTimeSubtract(videoAsset.duration, endTime))
                                ofTrack:arrayVideoDataSources[0]
                                 atTime:startTime
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                completionHandler(nil);
                return nil;
            }
            
            // AUDIO TRACK
            if (arrayAudioDataSources.count > 0)
            {
                AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                error = nil;
                [audioTrack insertTimeRange:CMTimeRangeMake(endTime, CMTimeSubtract(videoAsset.duration, endTime))
                                    ofTrack:arrayAudioDataSources[0]
                                     atTime:startTime
                                      error:&error];
                if (error)
                {
                    NSLog(@"Insertion error: %@", error);
                    completionHandler(nil);
                    return nil;
                }
            }
            
            layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            
            transform = CGAffineTransformIdentity;
            [layerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
            [layerInstruction setOpacity:1.0 atTime:startTime];
            
            [layerInstructions addObject:layerInstruction];
        }
    }
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    mainInstruction.layerInstructions = layerInstructions;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"videotrim_%d.m4v", trimIndex]];
    trimIndex += 1;
    unlink([path UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:path];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, trimDuration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         BOOL success = YES;
         switch ([exporter status]) {
             case AVAssetExportSessionStatusCompleted:
                 success = YES;
                 break;
             case AVAssetExportSessionStatusFailed:
                 success = NO;
                 NSLog(@"input videos - failed: %@", [[exporter error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 success = NO;
                 NSLog(@"input videos - canceled");
                 break;
             default:
                 success = NO;
                 break;
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler == nil)
                 return;
             if (success == YES)
                 completionHandler(videoOutputURL);
             else
                 completionHandler(nil);
         });
     }];
    
    return exporter;
}

+ (void)saveVideo:(NSURL *)videoURL completion:(void(^)(BOOL, NSURL *))completionHandler;
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {
        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(true, nil);
            });
        }];
    }
}

- (id)init {
    self = [super init];
    if (self != nil) {
        _videoAsset = nil;
        _audioAsset = nil;
        _audioURL = nil;
        _videoURL = nil;
    }
    return self;
}

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    self.videoAsset = [AVAsset assetWithURL:videoURL];
}

- (void)setAudioURL:(NSURL *)audioURL
{
    _audioURL = audioURL;
    self.audioAsset = [AVAsset assetWithURL:audioURL];
}

- (CMTime)maxDuration
{
    AVAsset *asset = [AVAsset assetWithURL:_audioURL];
    return asset.duration;
    return self.audioAsset.duration;
}

- (void)reset {
    self.textViews = nil;
    self.audioAsset = nil;
    self.audioURL = nil;
    self.cTime = CMTimeMakeWithSeconds(0, 1);
    self.scale = 1;
    self.volume = 1.0f;
    self.isFadeIn = NO;
    self.isFadeOut = NO;
    self.videoURL = nil;
    self.videoAsset = nil;
    self.audioURL = nil;
}

#pragma mark - video effects


- (void)applyTextViews:(NSArray *)textViews {
    self.textViews = textViews;
}

- (void)applyImageViews:(NSArray*)imageViews {
    self.graphicsViews = imageViews;
}

- (void)applyGraphicsViews:(NSArray *)graphicsViews {
    self.graphicsViews = graphicsViews;
}

- (void)saveVideo:(CGSize)renderSize save:(BOOL)needsToBeSaved colorVideoURL:(NSURL *)colorVideoURL {
    self.audioAsset = [AVAsset assetWithURL:_audioURL];
    if (self.audioURL != nil && CMTimeCompare(self.cTime, kCMTimeZero) != 0) {
        AVAsset *audioAsset = [AVAsset assetWithURL:self.audioURL];
        if (audioAsset != nil) {
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:audioAsset  presetName:AVAssetExportPresetAppleM4A];
            CMTime startTime = self.cTime;
            CMTime durationTime = self.videoAsset.duration;
            exporter.timeRange = CMTimeRangeMake(startTime, durationTime);
            NSString *myPathDocs =  [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"tempaudio-%d.m4a", arc4random() % 1000000]];
            NSURL *url = [NSURL fileURLWithPath:myPathDocs];
            exporter.outputURL = url;
            exporter.outputFileType = AVFileTypeAppleM4A;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.audioAsset = [AVAsset assetWithURL:exporter.outputURL];
                    [self videoOutput:renderSize save:needsToBeSaved colorVideoURL:colorVideoURL];
                });
            }];
        } else {
            [self videoOutput:renderSize save:needsToBeSaved colorVideoURL:colorVideoURL];
        }
    } else {
        [self videoOutput:renderSize save:needsToBeSaved colorVideoURL:colorVideoURL];
    }
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition watermark:(BOOL)isWatermark size:(CGSize)size
{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    
    for (VFVideoLine *videoLine in _arrayVideoLines)
    {
        NSMutableArray *layers = [NSMutableArray arrayWithArray:videoLine.arrayImageViews];
        [layers addObjectsFromArray:videoLine.arrayTextViews];
        
        NSArray *sortedLayers = [layers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            UIView *view1 = (UIView*)obj1;
            UIView *view2 = (UIView*)obj2;
            NSInteger index1 = [[view1.superview subviews] indexOfObject:view1];
            NSInteger index2 = [[view2.superview subviews] indexOfObject:view2];
            NSNumber *number1 = [NSNumber numberWithInteger:index1];
            NSNumber *number2 = [NSNumber numberWithInteger:index2];
            
            return [number1 compare:number2];
        }];
        
        if (videoLine.videoAsset == nil) {
            CALayer *imageLayer = [CALayer layer];
            UIImage *overlayImage = [videoLine.backgroundUIImage resizedImageToSize:CGSizeMake(size.width, size.height)];
            [imageLayer setContents:(id)[overlayImage CGImage]];
            imageLayer.frame = CGRectMake(0, 0, size.width, size.height);
            
            CGFloat animationDuration = 0.01f;
            if (videoLine.startTime == 0) {
                animationDuration = 0.0f;
            }
            CFTimeInterval startPosition = AVCoreAnimationBeginTimeAtZero + videoLine.startTime;
            CFTimeInterval endPosition = AVCoreAnimationBeginTimeAtZero + videoLine.endTime - animationDuration;
            //CAAnimation *startAnimation = [self startNoneAction:startPosition duration:animationDuration];
            //CAAnimation *endAnimation = endAnimation = [self endNoneAction:endPosition duration:animationDuration fromTransform:CATransform3DIdentity fromZoomValue:1.0f];
            
            CALayer *overlayLayer = [CALayer layer];
            overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
            
            [overlayLayer addSublayer:imageLayer];
            [overlayLayer setMasksToBounds:YES];
            
            //[overlayLayer addAnimation:startAnimation forKey:nil];
            //[overlayLayer addAnimation:endAnimation forKey:nil];
            [parentLayer addSublayer:overlayLayer];
        }
        
        UIImage *renderImage = videoLine.imageAsset;
        /*for (UIView *view in sortedLayers)
        {
            if ([view isKindOfClass:[TVTextView class]])
                renderImage = [(TVTextView *)view image:renderImage withImageRepresentationForSize:size scale:self.scale];
            else if ([view isKindOfClass:[TVImageView class]])
                renderImage = [(TVImageView *)view image:renderImage withImageRepresentationForSize:size scale:self.scale];
        }*/
        //CALayer *imageLayer = [self setImageAnimationWithVideoLine:videoLine videoSize:size withImage:renderImage];
        //[parentLayer addSublayer:imageLayer];
    }
    
    /*for (CALayer *overlayLayer in arrayOverlayLayers) {
        [parentLayer addSublayer:overlayLayer];
    }*/
    
    if (isWatermark)
    {
        UIImage *overlayImage = nil;
        UIImage *imageWatermark = [UIImage imageNamed:@"Watermark"];
        int width = size.width / 4;
        int height = width / imageWatermark.size.width * imageWatermark.size.height;
        CGRect frameWatermark = CGRectMake(size.width - width - 8, size.height - height - 16, width, height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 2.0f);
        [imageWatermark drawInRect:frameWatermark blendMode:kCGBlendModeNormal alpha:1.0f];
        overlayImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //video layer
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
        videoLayer.backgroundColor = [UIColor clearColor].CGColor;
        [parentLayer addSublayer:videoLayer];
        
        CALayer *overlayLayer = [CALayer layer];
        overlayImage = [overlayImage resizedImageToSize:CGSizeMake(size.width, size.height)];
        [overlayLayer setContents:(id)[overlayImage CGImage]];
        overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
        [parentLayer addSublayer:overlayLayer];
    }

    composition.animationTool = [AVVideoCompositionCoreAnimationTool
            videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (TVTimeLine*)getTimeLine:(NSInteger)timeLineId
{
    for (TVTimeLine *timeLine in self.arrayTimeLines)
    {
        if (timeLine.timeLineId == timeLineId)
            return timeLine;
    }
    
    return nil;
}

- (CGSize)naturalSize:(AVAssetTrack *)assetTrack {
    CGSize naturalSize = assetTrack.naturalSize;
    CGAffineTransform transform = assetTrack.preferredTransform;
    if ((transform.b == 1 && transform.c == -1) || (transform.b == -1 && transform.c == 1))
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    else if ((naturalSize.width == transform.tx && naturalSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        naturalSize = CGSizeMake(naturalSize.width, naturalSize.height);
    else
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    return naturalSize;
}

- (AVAssetExportSession *)videoOutput:(CGSize)renderSize save:(BOOL)isNeedToSave colorVideoURL:(NSURL *)colorVideoURL
{
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    NSMutableArray *arrayLayerInstructions = [NSMutableArray array];
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVMutableVideoCompositionLayerInstruction *borderLayerInstruction = nil;
    AVMutableCompositionTrack *bordeVideoTrack;
    AVAsset *borderVideoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"Background" withExtension:@"m4v"]];
    if (colorVideoURL != nil) {
        borderVideoAsset = [AVAsset assetWithURL:colorVideoURL];
    }
    if (borderVideoAsset != nil)
    {
        CMTime duration = borderVideoAsset.duration;
        
        bordeVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        self.backgroundTrackID = bordeVideoTrack.trackID;
        NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[borderVideoAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [bordeVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                                 ofTrack:arrayVideoDataSources[0]
                                  atTime:kCMTimeZero
                                   error:&error];
        if (error)
            NSLog(@"Insertion error: %@", error);
        
        borderLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:bordeVideoTrack];
        
        AVAssetTrack *assetTrack = [[borderVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, renderSize.width / bordeVideoTrack.naturalSize.width * 2.0f, renderSize.height / bordeVideoTrack.naturalSize.height * 2.0f);
        [borderLayerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [borderLayerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    }
    
    CMTime atTime = kCMTimeZero;
    for (VFVideoLine *videoLine in _arrayVideoLines)
    {
        // Normal asset
        AVAsset *inputAsset = videoLine.videoAsset;
        if (inputAsset == nil)
        {
            CMTime assetDuration = CMTimeMake(videoLine.imageDuration * 1000, 1000);
            atTime = CMTimeAdd(atTime, assetDuration);
            continue;
        }
        
        AVAssetTrack *assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        // VIDEO TRACK
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        videoLine.trackID = videoTrack.trackID;
        NSArray *videoDataSourceArray = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                            ofTrack:videoDataSourceArray[0]
                             atTime:atTime
                              error:&error];
        if (error)
        {
            NSLog(@"Insertion error: %@", error);
            self.handlerBlock(nil);
            return nil;
        }

        // AUDIO TRACK
        NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeAudio]];
        if (arrayAudioDataSources.count > 0)
        {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            error = nil;
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                                ofTrack:arrayAudioDataSources[0]
                                 atTime:atTime
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                self.handlerBlock(nil);
                return nil;
            }
        }

        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

        CGSize naturalSize = [self naturalSize:assetTrack];
        CGAffineTransform transform = CGAffineTransformIdentity;
        CGFloat scale = MIN(renderSize.width / naturalSize.width, renderSize.height / naturalSize.height);
        if (videoLine.isAspectFill) {
            scale = MAX(renderSize.width / naturalSize.width, renderSize.height / naturalSize.height);
        }
        
        scale *= videoLine.scale;
        transform = CGAffineTransformScale(transform, scale, scale);
        
        if (videoLine.degree != 0) {
            CGFloat angle = videoLine.degree * M_PI / 180;
            CGAffineTransform rotateTransform = CGAffineTransformIdentity;
            if (videoLine.degree == 90.0) {
                rotateTransform = CGAffineTransformMakeTranslation(naturalSize.height * scale, 0);
                rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                transform = CGAffineTransformConcat(transform, rotateTransform);
                if (naturalSize.width <= naturalSize.height) {
                    transform = CGAffineTransformTranslate(transform, (renderSize.height / scale - naturalSize.width) / 2.0f, (naturalSize.height * scale - renderSize.width) / 2.0f / scale);
                } else {
                    transform.tx = transform.tx + (renderSize.width - naturalSize.height * scale) / 2.0f;
                    transform.ty = transform.ty + (renderSize.height - naturalSize.width * scale) / 2.0f;
                }
            } else if (videoLine.degree == 180.0) {
                rotateTransform = CGAffineTransformMakeTranslation(naturalSize.width * scale, naturalSize.height * scale);
                rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                transform = CGAffineTransformConcat(transform, rotateTransform);
                if (naturalSize.width <= naturalSize.height) {
                    transform.tx = transform.tx + (renderSize.width - naturalSize.width * scale) / 2.0f;
                    transform.ty = transform.ty - (naturalSize.height * scale - renderSize.height) / 2.0f;
                } else {
                    transform.tx = transform.tx + (renderSize.width - naturalSize.width * scale) / 2.0f;
                    transform.ty = transform.ty + (renderSize.height - naturalSize.height * scale) / 2.0f;
                }
            }
            else if (videoLine.degree == 270.0) {
                rotateTransform = CGAffineTransformMakeTranslation(0, naturalSize.width * scale);
                rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                transform = CGAffineTransformConcat(transform, rotateTransform);
                if (naturalSize.width <= naturalSize.height) {
                    transform = CGAffineTransformTranslate(transform, -(renderSize.height / scale - naturalSize.width) / 2.0f, -(naturalSize.height * scale - renderSize.width) / 2.0f / scale);
                } else {
                    transform.tx = transform.tx + (renderSize.width - naturalSize.height * scale) / 2.0f;
                    transform.ty = transform.ty + (renderSize.height - naturalSize.width * scale) / 2.0f;
                }
            }
        } else {
            transform = CGAffineTransformTranslate(transform, (renderSize.width / scale - naturalSize.width) / 2.0f, (renderSize.height / scale - naturalSize.height) / 2.0f);
        }
        
        if (videoLine.isHorizontalFlip) {
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformTranslate(transform, -naturalSize.width, 0.0);
        }
        
        if (videoLine.isVerticalFlip) {
            if (videoLine.degree == 90 || videoLine.degree == 270) {
                transform = CGAffineTransformScale(transform, 1.0, -1.0);
                transform = CGAffineTransformTranslate(transform, 0.0, -naturalSize.height);
            } else {
                transform = CGAffineTransformScale(transform, -1.0, 1.0);
                transform = CGAffineTransformTranslate(transform, -naturalSize.width, 0.0);
            }
        }

        CGRect viewFrame = CGRectFromString(self.project.frame);
        CGFloat viewScale = 1.0;
        viewScale *= viewFrame.size.width / renderSize.width;

        CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(videoLine.transform.tx / viewScale, videoLine.transform.ty / viewScale);
        //CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(videoLine.transform.tx, videoLine.transform.ty);
        transform = CGAffineTransformConcat(transform, translateTransform);
        
        transform = CGAffineTransformConcat(assetTrack.preferredTransform, transform);

        //[layerInstruction setTransform:transform atTime:atTime];
        //[layerInstruction setOpacity:1.0 atTime:atTime];
        //atTime = CMTimeAdd(atTime, inputAsset.duration);
        //[layerInstruction setOpacity:0.0 atTime:atTime];

        //[self setVideoAnimation:layerInstruction transform:transform videoLine:videoLine videoSize:renderSize isBlur:NO];
        [arrayLayerInstructions addObject:layerInstruction];
        
        // Blur background asset
        if (videoLine.blurAsset != nil)
        {
            AVAsset *inputAsset = videoLine.blurAsset;
            AVAssetTrack *assetTrack = [[inputAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            CGSize naturalSize = [self naturalSize:assetTrack];

            // VIDEO TRACK
            videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            videoLine.blurTrackID = videoTrack.trackID;
            NSArray *videoDataSourceArray = [NSArray arrayWithArray:[inputAsset tracksWithMediaType:AVMediaTypeVideo]];
            NSError *error = nil;
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, inputAsset.duration)
                                ofTrack:videoDataSourceArray[0]
                                 atTime:atTime
                                  error:&error];
            if (error)
            {
                NSLog(@"Insertion error: %@", error);
                self.handlerBlock(nil);
                return nil;
            }
            
            AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
            
            CGAffineTransform transform = CGAffineTransformIdentity;
            CGFloat scale1 = MAX(renderSize.width / naturalSize.width, renderSize.height / naturalSize.height);
            CGFloat scale2 = MAX(renderSize.width / naturalSize.height, renderSize.height / naturalSize.width);
            CGFloat scale = MAX(scale1, scale2);
            if (videoLine.degree == 0 || videoLine.degree == 180) {
                scale = scale1;
            }
            
            transform = CGAffineTransformScale(transform, scale, scale);
            
            if (videoLine.degree != 0) {
                CGFloat angle = videoLine.degree * M_PI / 180;
                CGAffineTransform rotateTransform = CGAffineTransformIdentity;
                if (videoLine.degree == 90.0) {
                    rotateTransform = CGAffineTransformMakeTranslation(naturalSize.height * scale, 0);
                    rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                    transform = CGAffineTransformConcat(transform, rotateTransform);
                    if (naturalSize.width <= naturalSize.height) {
                        transform = CGAffineTransformTranslate(transform, (renderSize.height / scale - naturalSize.width) / 2.0f, -(renderSize.height - renderSize.width) / 2.0f / scale);
                    } else {
                        transform.tx = transform.tx - (renderSize.width - naturalSize.height * scale) / 2.0f;
                        transform.ty = transform.ty + (renderSize.height - naturalSize.width * scale) / 2.0f;
                    }
                } else if (videoLine.degree == 180.0) {
                    rotateTransform = CGAffineTransformMakeTranslation(naturalSize.width * scale, naturalSize.height * scale);
                    rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                    transform = CGAffineTransformConcat(transform, rotateTransform);
                    if (naturalSize.width <= naturalSize.height) {
                        transform.tx = transform.tx - (renderSize.width - naturalSize.width * scale) / 2.0f;
                    } else {
                        transform.ty = transform.ty - (renderSize.height - naturalSize.height * scale) / 2.0f;
                    }
                }
                else if (videoLine.degree == 270.0) {
                    rotateTransform = CGAffineTransformMakeTranslation(0, naturalSize.width * scale);
                    rotateTransform = CGAffineTransformRotate(rotateTransform, angle);
                    transform = CGAffineTransformConcat(transform, rotateTransform);
                    if (naturalSize.width <= naturalSize.height) {
                        transform = CGAffineTransformTranslate(transform, -(renderSize.height / scale - naturalSize.width) / 2.0f, (renderSize.height - renderSize.width) / 2.0f / scale);
                    } else {
                        transform.tx = transform.tx - (renderSize.width - naturalSize.height * scale) / 2.0f;
                        transform.ty = transform.ty + (renderSize.height - naturalSize.width * scale) / 2.0f;
                    }
                }
            } else {
                transform = CGAffineTransformTranslate(transform, (renderSize.width / scale - naturalSize.width) / 2.0f, (renderSize.height / scale - naturalSize.height) / 2.0f);
            }
            
            if (videoLine.isHorizontalFlip) {
                transform = CGAffineTransformScale(transform, -1.0, 1.0);
                transform = CGAffineTransformTranslate(transform, -naturalSize.width, 0.0);
            }
            
            if (videoLine.isVerticalFlip) {
                if (videoLine.degree == 90 || videoLine.degree == 270) {
                    transform = CGAffineTransformScale(transform, 1.0, -1.0);
                    transform = CGAffineTransformTranslate(transform, 0.0, -naturalSize.height);
                } else {
                    transform = CGAffineTransformScale(transform, -1.0, 1.0);
                    transform = CGAffineTransformTranslate(transform, -naturalSize.width, 0.0);
                }
            }

            transform = CGAffineTransformConcat(assetTrack.preferredTransform, transform);
            
            [layerInstruction setTransform:transform atTime:atTime];
            [layerInstruction setOpacity:1.0 atTime:atTime];
            atTime = CMTimeAdd(atTime, inputAsset.duration);
            [layerInstruction setOpacity:0.0 atTime:atTime];
            //[self setVideoAnimation:layerInstruction transform:transform videoLine:videoLine videoSize:renderSize isBlur:YES];
            [arrayLayerInstructions addObject:layerInstruction];
        }
    }
    
    [arrayLayerInstructions addObject:borderLayerInstruction];
    
    self.audioMixParams = [NSMutableArray array];
    for (TVTimeLine * timeLine in self.arrayTimeLines)
    {
        if (timeLine.musicURL == nil)
            continue;

        AVAsset *audioAsset = [AVURLAsset URLAssetWithURL:timeLine.musicURL options:nil];
        [self setUpAndAddAudio:audioAsset toComposition:mixComposition timeLine:timeLine];
    }
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:self.audioMixParams];
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, atTime);
    mainInstruction.layerInstructions = arrayLayerInstructions;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    self.scale = fmin(renderSize.width / 320.0f / [UIScreen mainScreen].scale, renderSize.height / 320.0f / [UIScreen mainScreen].scale);
    [self applyVideoEffectsToComposition:mainCompositionInst watermark:self.isWatermark size:renderSize];
    
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"resultvideo.m4v"];
    unlink([videoPath UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:videoPath];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    if (audioMix != nil)
        exporter.audioMix = audioMix;
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    CMTime duration = atTime;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                self.handlerBlock(exporter.outputURL);
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NOTIFICATION_PREVIEW" object:exporter.outputURL];
                if (isNeedToSave){
                    [self exportDidFinish:exporter];
                }
            } else {
                self.handlerBlock(nil);
                NSError *error = exporter.error;
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
            }
        });
    }];
    
    return exporter;
}

// saves video to photo album
- (void)exportDidFinish:(AVAssetExportSession*)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        self.handlerBlock(outputURL);
                    }
                    else {
                        NSString *title = @"Error";
                        NSString *message = @"Video Saving Failed";
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        self.handlerBlock(nil);
                    }
                });
            }];
        }
    }
}

- (void)setUpAndAddAudio:(AVAsset*)audioAsset toComposition:(AVMutableComposition*)composition volume:(CGFloat)volume startTime:(CMTime)startTime
{
    AVMutableCompositionTrack *mixTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack = nil;
    if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0)
        sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableAudioMixInputParameters *mixParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:mixTrack];
    CMTime trackStartTime = startTime, trackDuration = audioAsset.duration;
    float fadeIn = 2.0f, fadeOut = 2.0f;
    float duration = (audioAsset.duration.value * 1.0f) / (audioAsset.duration.timescale * 1.0f);
    if (self.isFadeIn == YES && self.isFadeOut == YES)
    {
        if (fadeIn + fadeOut > duration)
            fadeIn = fadeOut = duration / 2.0f;
    }
    else if (self.isFadeIn == YES)
    {
        if (fadeIn > duration)
            fadeIn = duration;
    }
    else
    {
        if (fadeOut > duration)
            fadeOut = duration;
    }
    if (self.isFadeIn == YES)
    {
        CMTime fadeInDuration = CMTimeMake((int)(fadeIn * 1000), 1000);
        CMTimeRange fadeInRange = CMTimeRangeMake(startTime, fadeInDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:0.0f toEndVolume:volume timeRange:fadeInRange];
        //[self.audioMixParams addObject:fadeInMix];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeInRange ofTrack:sourceAudioTrack atTime:startTime error:nil];
        
        trackStartTime = CMTimeAdd(startTime, fadeInDuration);
        float durvalue = (fadeInDuration.value * 1.0f) / (fadeInDuration.timescale * 1.0f);
        trackDuration = CMTimeMake(trackDuration.value - durvalue * trackDuration.timescale, trackDuration.timescale);
    }
    else if (self.isFadeOut == YES)
    {
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
        
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:trackRange];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:trackStartTime error:nil];
        
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * 1000), 1000);
        CMTime outTime = CMTimeMake(audioAsset.duration.value - fadeOut * audioAsset.duration.timescale, audioAsset.duration.timescale);
        CMTimeRange fadeOutRange = CMTimeRangeMake(outTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:fadeOutRange];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        [self.audioMixParams addObject:mixParams];
        
        return;
    }
    
    [self.audioMixParams addObject:mixParams];
    
    if (self.isFadeOut == YES)
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
    
    if (trackDuration.value >= 0)
    {
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:trackRange];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:trackStartTime error:nil];
    }
    
    if (self.isFadeOut == YES)
    {
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * 1000), 1000);
        CMTime outTime = CMTimeMake(audioAsset.duration.value - fadeOut * audioAsset.duration.timescale, audioAsset.duration.timescale);
        CMTimeRange fadeOutRange = CMTimeRangeMake(outTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:fadeOutRange];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
    }
}

- (void)setUpAndAddAudio:(AVAsset*)audioAsset toComposition:(AVMutableComposition*)composition volume:(CGFloat)volume startTime:(CMTime)startTime audioTime:(CMTime)audioTime
{
    AVMutableCompositionTrack *mixTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack = nil;
    if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0)
        sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableAudioMixInputParameters *mixParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:mixTrack];
    CMTime trackStartTime = audioTime, trackDuration = audioAsset.duration, outTime = startTime;
    float fadeIn = 2.0f, fadeOut = 2.0f, timescale = audioAsset.duration.timescale;
    float duration = (audioAsset.duration.value * 1.0f) / (audioAsset.duration.timescale * 1.0f);
    if (self.isFadeIn == YES && self.isFadeOut == YES)
        fadeIn = fadeOut = MIN(fadeIn, duration / 2.0f);
    else if (self.isFadeIn == YES)
        fadeIn = MIN(fadeIn, duration);
    else
        fadeOut = MIN(fadeOut, duration);
    if (self.isFadeIn == YES)
    {
        CMTime fadeInDuration = CMTimeMake((int)(fadeIn * timescale), timescale);
        CMTimeRange fadeInRange = CMTimeRangeMake(trackStartTime, fadeInDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:0.0f toEndVolume:volume timeRange:CMTimeRangeMake(outTime, fadeInDuration)];
        //[self.audioMixParams addObject:fadeInMix];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeInRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        trackStartTime = CMTimeAdd(trackStartTime, fadeInDuration);
        trackDuration = CMTimeSubtract(trackDuration, fadeInDuration);
        outTime = CMTimeAdd(outTime, fadeInDuration);
    }
    else if (self.isFadeOut == YES)
    {
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
        
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:CMTimeRangeMake(outTime, trackDuration)];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * timescale), timescale);
        trackStartTime = CMTimeAdd(trackStartTime, trackDuration);
        outTime = trackDuration;
        CMTimeRange fadeOutRange = CMTimeRangeMake(trackStartTime, fadeOutDuration);
        trackRange = CMTimeRangeMake(outTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:trackRange];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        [self.audioMixParams addObject:mixParams];
        
        return;
    }
    
    if (self.isFadeOut == YES)
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
    
    if (trackDuration.value >= 0)
    {
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:CMTimeRangeMake(outTime, trackDuration)];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        trackStartTime = CMTimeAdd(trackStartTime, trackDuration);
    }
    
    if (self.isFadeOut == YES)
    {
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * timescale), timescale);
        outTime = CMTimeSubtract(audioAsset.duration, fadeOutDuration);
        CMTimeRange fadeOutRange = CMTimeRangeMake(trackStartTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:CMTimeRangeMake(outTime, fadeOutDuration)];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
    }
    
    [self.audioMixParams addObject:mixParams];
}

- (void)setUpAndAddAudio:(AVAsset*)audioAsset toComposition:(AVMutableComposition*)composition timeLine:(TVTimeLine *)timeLine
{
    AVMutableCompositionTrack *mixTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *sourceAudioTrack = nil;
    if ([audioAsset tracksWithMediaType:AVMediaTypeAudio].count > 0)
        sourceAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableAudioMixInputParameters *mixParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:mixTrack];
    float fadeIn = 2.0f, fadeOut = 2.0f, timescale = audioAsset.duration.timescale;
    CMTime trackStartTime = CMTimeMake(timeLine.musicStartTime * timescale, timescale), trackDuration = CMTimeMake((timeLine.endTime - timeLine.startTime) * timescale, timescale);
    CMTime outTime = CMTimeMake(timeLine.startTime * timescale, timescale);
    float duration = timeLine.endTime - timeLine.startTime, volume = timeLine.musicVolume;
    if (timeLine.isFadeIn == YES && timeLine.isFadeOut == YES)
        fadeIn = fadeOut = MIN(fadeIn, duration / 2.0f);
    else if (timeLine.isFadeIn == YES)
        fadeIn = MIN(fadeIn, duration);
    else
        fadeOut = MIN(fadeOut, duration);
    if (timeLine.isFadeIn == YES)
    {
        CMTime fadeInDuration = CMTimeMake((int)(fadeIn * timescale), timescale);
        CMTimeRange fadeInRange = CMTimeRangeMake(trackStartTime, fadeInDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:0.0f toEndVolume:volume timeRange:CMTimeRangeMake(outTime, fadeInDuration)];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeInRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        trackStartTime = CMTimeAdd(trackStartTime, fadeInDuration);
        trackDuration = CMTimeSubtract(trackDuration, fadeInDuration);
        outTime = CMTimeAdd(outTime, fadeInDuration);
    }
    else if (timeLine.isFadeOut == YES)
    {
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
        
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:CMTimeRangeMake(outTime, trackDuration)];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * timescale), timescale);
        trackStartTime = CMTimeAdd(trackStartTime, trackDuration);
        outTime = trackDuration;
        CMTimeRange fadeOutRange = CMTimeRangeMake(trackStartTime, fadeOutDuration);
        trackRange = CMTimeRangeMake(outTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:trackRange];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        
        [self.audioMixParams addObject:mixParams];
        
        return;
    }
    
    if (timeLine.isFadeOut == YES)
        trackDuration = CMTimeMake(trackDuration.value - fadeOut * trackDuration.timescale, trackDuration.timescale);
    
    if (trackDuration.value > 0)
    {
        CMTimeRange trackRange = CMTimeRangeMake(trackStartTime, trackDuration);
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:volume timeRange:CMTimeRangeMake(outTime, trackDuration)];
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:trackRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
        trackStartTime = CMTimeAdd(trackStartTime, trackDuration);
    }
    
    if (timeLine.isFadeOut == YES)
    {
        CMTime fadeOutDuration = CMTimeMake((int)(fadeOut * timescale), timescale);
        outTime = CMTimeSubtract(CMTimeMake((timeLine.endTime - timeLine.startTime) * timescale, timescale), fadeOutDuration);
        CMTimeRange fadeOutRange = CMTimeRangeMake(trackStartTime, fadeOutDuration);
        
        //Set Volume
        [mixParams setVolumeRampFromStartVolume:volume toEndVolume:0.0f timeRange:CMTimeRangeMake(outTime, fadeOutDuration)];
        
        //Insert audio into track
        if (sourceAudioTrack)
            [mixTrack insertTimeRange:fadeOutRange ofTrack:sourceAudioTrack atTime:outTime error:nil];
    }
    
    [self.audioMixParams addObject:mixParams];
}

+ (void)colorVideo:(UIColor *)color completion:(void(^)(BOOL, NSURL *))completionHandler {
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    NSMutableArray *arrayLayerInstructions = [NSMutableArray array];
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVMutableVideoCompositionLayerInstruction *borderLayerInstruction = nil;
    AVMutableCompositionTrack *bordeVideoTrack;
    AVAsset* borderVideoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"Background" withExtension:@"m4v"]];
    CGSize renderSize = CGSizeZero;
    if (borderVideoAsset != nil)
    {
        CMTime duration = borderVideoAsset.duration;
        
        bordeVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        NSArray *arrayVideoDataSources = [NSArray arrayWithArray:[borderVideoAsset tracksWithMediaType:AVMediaTypeVideo]];
        NSError *error = nil;
        [bordeVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration)
                                 ofTrack:arrayVideoDataSources[0]
                                  atTime:kCMTimeZero
                                   error:&error];
        if (error)
            NSLog(@"Insertion error: %@", error);
        
        borderLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:bordeVideoTrack];
        
        AVAssetTrack *assetTrack = [[borderVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        renderSize = [[VideoService shared] naturalSize:assetTrack];
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        transform = CGAffineTransformScale(transform, 2.0f, 2.0f);
        [borderLayerInstruction setTransform:CGAffineTransformConcat(assetTrack.preferredTransform, transform) atTime:kCMTimeZero];
        [borderLayerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    }
    
    [arrayLayerInstructions addObject:borderLayerInstruction];
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, borderVideoAsset.duration);
    mainInstruction.layerInstructions = arrayLayerInstructions;
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    {
        CALayer *parentLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        
        UIImage *colorImage = [UIImage colorImage:color size:renderSize];
        //video layer
        CALayer *videoLayer = [CALayer layer];
        videoLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        videoLayer.backgroundColor = [UIColor clearColor].CGColor;
        [parentLayer addSublayer:videoLayer];
        
        CALayer *overlayLayer = [CALayer layer];
        [overlayLayer setContents:(id)colorImage.CGImage];
        overlayLayer.frame = CGRectMake(0, 0, renderSize.width, renderSize.height);
        [parentLayer addSublayer:overlayLayer];
        
        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"colorvideo.m4v"];
    unlink([videoPath UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:videoPath];
    
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoOutputURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.videoComposition = mainCompositionInst;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, borderVideoAsset.duration);
    exporter.shouldOptimizeForNetworkUse = YES;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                completionHandler(YES, exporter.outputURL);
            } else {
                NSError *error = exporter.error;
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                completionHandler(NO, exporter.outputURL);
            }
        });
    }];
}

+ (AVAssetExportSession *)saveVideo:(AVAsset *)asset path:(NSString *)path completion:(void(^)(BOOL, NSError *))completionHandler {
    if (asset == nil || path == nil) {
        if (completionHandler != nil) {
            completionHandler(NO, nil);
        }
        return nil;
    }
    
    //CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
//    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
//        CIImage *source = [request.sourceImage imageByClampingToExtent];
//        //[filter setValue:source forKey:kCIInputImageKey];
//        //[filter setValue:@(20.0) forKey:kCIInputRadiusKey];
//        //[request finishWithImage:filter.outputImage context:nil];
//        [request finishWithImage:source context:nil];
//    }];
    NSString *resetName = AVAssetExportPresetHighestQuality;
    int width = [UIScreen mainScreen].bounds.size.width * 2;
    if (width <= 640) {
        resetName = AVAssetExportPreset640x480;
    } else if (width <= 960) {
        resetName = AVAssetExportPreset960x540;
    } else if (width <= 1280) {
        resetName = AVAssetExportPreset1280x720;
    } else if (width <= 1920) {
        resetName = AVAssetExportPreset1920x1080;
    } else if (width <= 3840) {
        resetName = AVAssetExportPreset3840x2160;
    }
    
//    AVAssetExportPresetMediumQuality
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:resetName];
    unlink([path UTF8String]);
    NSURL *outputURL = [NSURL fileURLWithPath:path];
    
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = exportSession.error;
        if (completionHandler != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error == nil) {
                    completionHandler(YES, nil);
                } else {
                    completionHandler(NO, error);
                }
            });
        }
    }];
    
    /*AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize renderSize = [[VideoService shared] naturalSize:assetTrack];
    // VIDEO TRACK
    videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *videoDataSourceArray = [NSArray arrayWithArray:[asset tracksWithMediaType:AVMediaTypeVideo]];
    NSError *error = nil;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:videoDataSourceArray[0]
                         atTime:kCMTimeZero
                          error:&error];
    if (error)
    {
        NSLog(@"Insertion error: %@", error);
        completionHandler(false, nil);
        return nil;
    }
    
    // AUDIO TRACK
    NSArray *arrayAudioDataSources = [NSArray arrayWithArray:[asset tracksWithMediaType:AVMediaTypeAudio]];
    if (arrayAudioDataSources.count > 0)
    {
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        error = nil;
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                            ofTrack:arrayAudioDataSources[0]
                             atTime:kCMTimeZero
                              error:&error];
        if (error)
        {
            NSLog(@"Insertion error: %@", error);
            completionHandler(false, nil);
            return nil;
        }
    }
    
    layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInstruction setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:1.0 atTime:kCMTimeZero];
    
    AVMutableVideoCompositionInstruction * mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = renderSize;
    
    unlink([path UTF8String]);
    NSURL *videoOutputURL = [NSURL fileURLWithPath:path];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = videoOutputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.videoComposition = mainCompositionInst;
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    exportSession.shouldOptimizeForNetworkUse = YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = exportSession.error;
        if (completionHandler != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != nil) {
                    completionHandler(NO, error);
                } else {
                    completionHandler(YES, nil);
                }
            });
        }
    }];
    */
    return exportSession;
}

+ (CGSize)videoSizeWithAsset:(AVAsset *)videoAsset {
    AVAssetTrack *assetTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    CGAffineTransform transform = assetTrack.preferredTransform;
    CGSize renderSize = assetTrack.naturalSize;
    if ((transform.b == 1 && transform.c == -1) || (transform.b == -1 && transform.c == 1))
        renderSize = CGSizeMake(renderSize.height, renderSize.width);
    else if ((renderSize.width == transform.tx && renderSize.height == transform.ty) || (transform.tx == 0 && transform.ty == 0))
        renderSize = CGSizeMake(renderSize.width, renderSize.height);
    else
        renderSize = CGSizeMake(renderSize.height, renderSize.width);
    return renderSize;
}

- (AVAssetExportSession *)blurVideo:(AVAsset *)asset path:(NSString *)path completion:(void(^)(BOOL))completionHandler {
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        CIImage *source = [request.sourceImage imageByClampingToExtent];
        [filter setValue:source forKey:kCIInputImageKey];
        [filter setValue:@(20.0) forKey:kCIInputRadiusKey];
        [request finishWithImage:filter.outputImage context:nil];
    }];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    unlink([path UTF8String]);
    NSURL *outputURL = [NSURL fileURLWithPath:path];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.videoComposition = videoComposition;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = exportSession.error;
        if (completionHandler != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error == nil) {
                    completionHandler(YES);
                } else {
                    completionHandler(NO);
                }
            });
        }
    }];
    
    return exportSession;
}

- (UIImage*) getFrame:(AVAsset*)movieAsset {
    NSArray *movieTracks = [movieAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *movieTrack = [movieTracks objectAtIndex:0];
    
    //Make the image Generator
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];

    //Create a variables for the time estimation
    Float64 durationSeconds = CMTimeGetSeconds(movieAsset.duration);
    Float64 timePerFrame = 1.0 / (Float64)movieTrack.nominalFrameRate;
    Float64 totalFrames = durationSeconds * movieTrack.nominalFrameRate;

    //Step through the frames
    CMTime actualTime;
    Float64 secondsIn = ((float)0/totalFrames)*durationSeconds;
    CMTime imageTimeEstimate = CMTimeMakeWithSeconds(secondsIn, durationSeconds);
    NSError *error;
    CGImageRef imgRef = [imageGenerator copyCGImageAtTime:imageTimeEstimate actualTime:&actualTime error:&error];
    
    UIImage *img = [UIImage imageWithCGImage:imgRef];
    
    CGImageRelease(imgRef);

    return img;
}

- (NSMutableArray*) getFrames:(AVAsset*)movieAsset {
    NSMutableArray* frames = [[NSMutableArray alloc] init];
    NSArray *movieTracks = [movieAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *movieTrack = [movieTracks objectAtIndex:0];
    
    //Make the image Generator
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];

    //Create a variables for the time estimation
    Float64 durationSeconds = CMTimeGetSeconds(movieAsset.duration);
    Float64 timePerFrame = 1.0 / (Float64)movieTrack.nominalFrameRate;
    Float64 totalFrames = durationSeconds * movieTrack.nominalFrameRate;

    //Step through the frames
    for (int counter = 0; counter <= totalFrames; counter++){
        CMTime actualTime;
        Float64 secondsIn = ((float)counter/totalFrames)*durationSeconds;
        CMTime imageTimeEstimate = CMTimeMakeWithSeconds(secondsIn, 600);
        NSError *error;
        CGImageRef imgRef = [imageGenerator copyCGImageAtTime:imageTimeEstimate actualTime:&actualTime error:&error];
        
        UIImage *img = [UIImage imageWithCGImage:imgRef];
        
        CGImageRelease(imgRef);
        
        [frames addObject:img];
    }
    
    return frames;
}

@end
