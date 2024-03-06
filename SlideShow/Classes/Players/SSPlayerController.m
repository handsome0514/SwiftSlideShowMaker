//
//  SSPlayerController.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSPlayerController.h"
#import "SSCore.h"
#import <AVFoundation/AVFoundation.h>
#import "Slideshow-Swift.h"
#import "ThemeManager.h"

NSString* const SSPlayerControllerPlayingNotification = @"SSPlayerControllerPlaying";
NSString* const SSPlayerControllerStoppedNotification = @"SSPlayerControllerStopped";

@interface SSPlayerController () {
    Boolean isVideoFirst;
}
//@property (nonatomic, strong) AVAudioPlayer* audioPlayer;
@property (nonatomic, strong) CADisplayLink* displayLink;
@property (nonatomic, assign) NSInteger currentPlaybackFrame;
//@property (nonatomic, strong) SSProjectTransitionItem* finalSlideTransition;
//@property (nonatomic, strong) SSProjectImageItem* finalSlideImage;


@end

@implementation SSPlayerController

#pragma mark - Life Cycle
+(SSPlayerController *)controllerWithPlayer:(SSPlayer *)player andProject:(SSProject *)project {
    NSAssert(player && project, @"Invalid arguments!");
    SSPlayerController* controller = [[SSPlayerController alloc] initWithPlayer:player andProject:project];
    return controller;
}

-(instancetype)initWithPlayer:(SSPlayer *)player andProject:(SSProject *)project {
    self = [super init];
    if (self) {
        self->_player = player;
        self->_project = project;
        self.currentPlaybackFrame = 0;
//        self.finalSlideTransition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeDirectional];
//        self.finalSlideImage = [SSProjectImageItem itemWithImage:[UIImage imageNamed:@"finalslide.jpg"]];
        [self recreateFinalSlideRawImage];
    }
    return self;
}


#pragma mark - Final Slide
-(void)recreateFinalSlideRawImage {
//    [self.finalSlideImage recreateRawImagePictureForSize:self.project.settings.outputSize];
}


#pragma mark - Preview
-(void)displayBlank {
    [[SSEffectProcessor sharedInstance] generateBlankFrameToPlayer:self.player];
}

-(void)displayFirstImage {
    SSProjectImageItem* image = self.project.imageItems.firstObject;
    if (image) {
        [self displayImage:image];
    }
}

-(void)displayImage:(SSProjectImageItem *)image {
    NSDictionary* options =
  @{/*kSSWatermarkPictureKey:[[SSEffectManager sharedInstance] watermarkForOutputRatio:self.project.settings.outputRatio]*/};
    [[SSEffectProcessor sharedInstance] generateFrameForImage:image toPlayer:self.player options:options];
}

-(void)displayImageForCropping:(SSProjectImageItem *)image cropRegion:(CGRect)cropRegion {
    NSDictionary* options =
  @{/*kSSWatermarkPictureKey:[[SSEffectManager sharedInstance] watermarkForOutputRatio:self.project.settings.outputRatio],*/
    kSSOverrideCropRegionKey:[NSValue valueWithCGRect:cropRegion]};
    [[SSEffectProcessor sharedInstance] generateFrameForImage:image toPlayer:self.player options:options];
}

-(void)displayImageForEditing:(SSProjectImageItem *)image {
    NSDictionary* options =
  @{/*kSSWatermarkPictureKey:[[SSEffectManager sharedInstance] watermarkForOutputRatio:self.project.settings.outputRatio],*/
    kSSDisableTextRenderingKey:@(YES),
    kSSDisableScribbleRenderingKey:@(YES)};
    [[SSEffectProcessor sharedInstance] generateFrameForImage:image toPlayer:self.player options:options];
}

-(void)previewLookupTable:(NSInteger)lookupTableIndex withItem:(SSProjectImageItem *)item {
    NSDictionary* options =
  @{/*kSSWatermarkPictureKey:[[SSEffectManager sharedInstance] watermarkForOutputRatio:self.project.settings.outputRatio],*/
    kSSOverrideLookupTableKey:@(lookupTableIndex)};
    [[SSEffectProcessor sharedInstance] generateFrameForImage:item toPlayer:self.player options:options];
}

#pragma mark - Playback
-(void)play {
    NSAssert(!self.isPlaying, @"Already playing!");
    if (self.currentPlaybackFrame < 0) {
        self.currentPlaybackFrame = 0;
    }
//    if (self.project.musics.count) {
//        self.audioPlayer = [[AVAudioPlayer alloc] init];
//        for (int i = 0; i < self.project.musics.count; i ++) {
//            SSMusic* music = [self.project.musics objectAtIndex:i];
//////            AVPlayerItem* item = [[AVPlayerItem alloc] initWithURL:music.url];
//////            [self.audioPlayer insertItem:item afterItem:nil];
////            NSString* urlPath = [Utilities generateFilePathWithFilename:music.fileName projectId:music.projectId];
////            var path = Utilities.generateFilePath(filename: filename, projectId: project.id)
////            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[[NSURL alloc] initWithString:urlPath] error:nil];
//        }
//        
//////        self.audioPlayer = [[AVPlayer alloc] initWithPlayerItem:[self.project createPlayerItemForCurrentMusics]];
//////        self.audioPlayer.muted = self.muted;
////        self.audioPlayer.volume = 1.0f;
////        [self.audioPlayer play];
//    }
    [self startDisplayLink];
    self->_playing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:SSPlayerControllerPlayingNotification object:self];
}

#pragma mark - Playback
-(void)pause {
//    NSAssert(!self.isPlaying, @"Already playing!");
    [self pauseDisplayLink];
    
//    self->_playing = NO;
//    [[NSNotificationCenter defaultCenter] postNotificationName:SSPlayerControllerPlayingNotification object:self];
}

-(void)resume {
//    NSAssert(!self.isPlaying, @"Already playing!");
    [self resumeDisplayLink];
    
//    self->_playing = YES;
//    [[NSNotificationCenter defaultCenter] postNotificationName:SSPlayerControllerPlayingNotification object:self];
}

-(void)stop {
    NSAssert(self.playing, @"Already stopped!");
    [self stopDisplayLink];
//    [self.audioPlayer stop];
//    [self.audioPlayer replaceCurrentItemWithPlayerItem:nil];
//    self.audioPlayer = nil;
    self->_playing = NO;
    self.currentPlaybackFrame = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:SSPlayerControllerStoppedNotification object:self];
}

-(void)jump:(NSTimeInterval)duration {
//    NSAssert(self.isPlaying, @"Not playing!");
    NSInteger frameCount = duration * self.project.framesPerSecond;
    //NSInteger frameIndex = MAX(0, MIN(self.project.totalFrameCount, self.currentPlaybackFrame + frameCount));
    NSInteger frameIndex = frameCount;
    NSTimeInterval position = (CGFloat)frameIndex / self.project.framesPerSecond;
//    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(position, 1000000)];
    self.currentPlaybackFrame = frameIndex;
    
    [self.editViewCtrl seekTimeSlider:self.currentPlaybackFrame];
}

-(void)setMuted:(BOOL)muted {
    _muted = muted;
//    if (self.audioPlayer) {
////        self.audioPlayer.muted = self.muted;
//    }
}

-(void)startDisplayLink {
    NSAssert(!self.displayLink, @"CADisplayLink is already started!");
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    if (@available(iOS 10, *)) {
        self.displayLink.preferredFramesPerSecond = (NSInteger)SSOutputFPS;
    } else {
        self.displayLink.frameInterval = (NSInteger)SSOutputFPS;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)resumeDisplayLink {
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    if (@available(iOS 10, *)) {
        self.displayLink.preferredFramesPerSecond = (NSInteger)SSOutputFPS;
    } else {
        self.displayLink.frameInterval = (NSInteger)SSOutputFPS;
    }
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.editViewCtrl resumeCurrentView];
}

-(void)pauseDisplayLink {
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [self.editViewCtrl pauseCurrentView];
}

-(void)stopDisplayLink {
    NSAssert(self.displayLink, @"CADisplayLink is not started yet!");
    [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self.displayLink invalidate];
    self.displayLink = nil;
}

-(void)tick {
    if (self.currentPlaybackFrame < self.project.totalFrameCount) {
        
        NSArray* data = [self.project objectDataOfFrame:self.currentPlaybackFrame];
        
        [self.editViewCtrl showCurrentView:[data.lastObject intValue]];
//        [self.editViewCtrl seekTimeSlider:self.currentPlaybackFrame :self.project.framesPerSecond];
        
        double value = self.currentPlaybackFrame * self.project.totalDuration;
        value = value / self.project.totalFrameCount;
        [self.editViewCtrl updateTimeValue:value];
        
//        NSInteger currentIdx = [self.project indexTransition:self.currentPlaybackFrame];
//        NSLog(@"currentIdx: %d", currentIdx);
//        id object = data[0];
        [self.editViewCtrl viewPlayViewHide:false];
    }
    else {

        [self stop];
    }
    
    self.currentPlaybackFrame++;
}

@end
