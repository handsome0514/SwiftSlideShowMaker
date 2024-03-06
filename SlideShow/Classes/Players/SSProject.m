//
//  SSProject.m
//  SlideShow
//
//  Created by Arda Ozupek on 23.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProject.h"
#import "SSCore.h"
#import "UIImage+Thumbnail.h"
#import "ThemeManager.h"

@interface SSProject ()
@property (nonatomic, strong) AVComposition* musicComposition;
@end

@implementation SSProject

#pragma mark - Life Cycle
+(SSProject *)project {
    SSProject* project = [[SSProject alloc] init];
    project->_projectId = [NSUUID UUID].UUIDString;
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateStyle:kCFDateFormatterLongStyle];
    NSString *result = [formatter stringFromDate:date];
    
    project->_createdTime = result;
    [[NSUserDefaults standardUserDefaults] setObject:result forKey:[NSString stringWithFormat:@"create_time_%@", project->_projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return project;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self->_imageItems = @[];
        self->_transitionItems = @[];
        self->_musics = @[];
        self->_framesPerSecond = SSOutputFPS;
        self->_settings = [[SSProjectSettings alloc] init];
        self->_transitionAppliedToAll = YES;
    }
    return self;
}

-(void)dealloc {
    DLog(@"-[SSProject dealloc]");
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.projectId forKey:@"projectId"];
    [aCoder encodeObject:self.createdTime forKey:@"createdTime"];
    [aCoder encodeObject:self.settings forKey:@"settings"];
    [aCoder encodeObject:self.imageItems forKey:@"imageItems"];
    [aCoder encodeObject:self.transitionItems forKey:@"transitionItems"];
    NSMutableArray* musicData = [[NSMutableArray alloc] init];
    for (SSMusic* music in self.musics) {
        if (music.type == kSSMusicTypeStock) {
            [musicData addObject:music.title];
        }
        else if (music.type == kSSMusicTypeLibrary) {
            [musicData addObject:@(music.mediaItem.persistentID)];
        } else if (music.type == kSSMusicTypeItunesStore) {
            //
            NSLog(@"MINHTH - 2");
        }
    }
    [aCoder encodeObject:[musicData copy] forKey:@"musics"];
    [aCoder encodeDouble:self.totalDuration forKey:@"totalDuration"];
    [aCoder encodeInteger:self.framesPerSecond forKey:@"framesPerSecond"];
    [aCoder encodeInteger:self.totalFrameCount forKey:@"totalFrameCount"];
    [aCoder encodeBool:self.transitionAppliedToAll forKey:@"transitionAppliedToAll"];
    [aCoder encodeBool:self.lookupTableAppliedToAll forKey:@"lookUpTableAppliedToAll"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self->_projectId = [aDecoder decodeObjectForKey:@"projectId"];
        self->_createdTime = [aDecoder decodeObjectForKey:@"createdTime"];
        self->_settings = [aDecoder decodeObjectForKey:@"settings"];
        self->_imageItems = [aDecoder decodeObjectForKey:@"imageItems"];
        self->_transitionItems = [aDecoder decodeObjectForKey:@"transitionItems"];
        NSArray* musicsData = [aDecoder decodeObjectForKey:@"musics"];
        NSMutableArray<SSMusic*>* musics = [[NSMutableArray alloc] init];
        for (id data in musicsData) {
            SSMusic* music = nil;
            if ([data isKindOfClass:[NSNumber class]]) {
                MPMediaEntityPersistentID mediaId = ((NSNumber*)data).integerValue;
                music = [[SSMusicManager sharedInstance] findLibraryMusic:mediaId];
            }
            else if ([data isKindOfClass:[NSString class]]) {
                NSString* title = (NSString*)data;
                music = [[SSMusicManager sharedInstance] findStockMusic:title];
            }
            if (music) {
                [musics addObject:music];
            }
        }
        self->_musics = [musics copy];
        self->_totalDuration = [aDecoder decodeDoubleForKey:@"totalDuration"];
        self->_framesPerSecond = [aDecoder decodeIntegerForKey:@"framesPerSecond"];
        self->_totalFrameCount = [aDecoder decodeIntegerForKey:@"totalFrameCount"];
        self->_transitionAppliedToAll = [aDecoder decodeBoolForKey:@"transitionAppliedToAll"];
        self->_lookupTableAppliedToAll = [aDecoder decodeBoolForKey:@"lookUpTableAppliedToAll"];
        self.musicComposition = [[SSAudioProcessor sharedInstance] createCompositionWithMusics:self.musics length:self->_totalDuration];
        [self applySettings:self.settings force:YES];
    }
    return self;
}


#pragma mark - Compare
-(BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object isMemberOfClass:[self class]]) {
        SSProject* project = object;
        if ([project.projectId isEqualToString:self.projectId]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Musics
-(void)updateMusics:(NSArray<SSMusic *> *)musics {
    NSAssert(musics, @"Musics is nil!");
    [self calculateDurations];
    self->_musics = [musics copy];
    self.musicComposition = [[SSAudioProcessor sharedInstance] createCompositionWithMusics:musics length:self->_totalDuration];
}

-(AVPlayerItem *)createPlayerItemForCurrentMusics {
    NSAssert(self.musicComposition, @"There is no music composition!");
    AVPlayerItem* item = [AVPlayerItem playerItemWithAsset:self.musicComposition];
    NSAssert(item && !item.error, @"Failed to create player item!");
    return item;
}

-(NSTimeInterval)musicFadeOutDuration {
    return MIN(3.0f, CMTimeGetSeconds(self.musicComposition.duration));
}


#pragma mark - Settings
-(void)applySettings:(SSProjectSettings *)settings {
    [self applySettings:settings force:NO];
}

-(void)applySettings:(SSProjectSettings *)settings force:(BOOL)force {
    NSAssert(settings, @"Settings is nil!");
    CGSize currentOutputSize = self.settings.outputSize;
    CGSize newOutputSize = settings.outputSize;
    self->_settings = settings;
    if (!CGSizeEqualToSize(currentOutputSize, newOutputSize) || force) {
        for (SSProjectImageItem* image in self.imageItems) {
            [image recreateRawImagePictureForSize:newOutputSize];
            if (image.texts.count) {
                [image renderTexts];
            }
            if (image.scribble.imageView.image) {
                [image renderScribble];
            }
        }
    }
    [self calculateDurations];
}


#pragma mark - Items
-(SSProjectImageItem*)insertImage:(UIImage *)image insertNum:(int)index {
    NSAssert(image, @"Image is nil!");
    
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
//    NSMutableArray<SSProjectTransitionItem*>* transitions = [self.transitionItems mutableCopy];
    
//    if (images.count) {
//        SSProjectTransitionItem* transition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeBurn];
//        transition.duration = 0;
//        [transitions addObject:transition];
//    }
    SSProjectImageItem* imageItem = [SSProjectImageItem itemWithImage:image size:self.settings.outputSize];
    if (self.settings.outputRatio == kSSOutputRatio1_1) {
        [imageItem scaleToFill];
    }
    [images insertObject:imageItem atIndex:index];
//    [images addObject:imageItem];
    self->_imageItems = [images copy];
//    self->_transitionItems = [transitions copy];
    [self calculateDurations];
    
    [[NSUserDefaults standardUserDefaults] setInteger:images.count forKey:[NSString stringWithFormat:@"number_image_%@", self.projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self updateTransitionAndImageFilter];
    return imageItem;
}

-(SSProjectImageItem*)addImage:(UIImage *)image {
    NSAssert(image, @"Image is nil!");
    
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
//    NSMutableArray<SSProjectTransitionItem*>* transitions = [self.transitionItems mutableCopy];
    
//    if (images.count) {
//        SSProjectTransitionItem* transition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeBurn];
//        transition.duration = 0;
//        [transitions addObject:transition];
//    }
    SSProjectImageItem* imageItem = [SSProjectImageItem itemWithImage:image size:self.settings.outputSize];
    if (self.settings.outputRatio == kSSOutputRatio1_1) {
        [imageItem scaleToFill];
    }
    [images addObject:imageItem];
    self->_imageItems = [images copy];
//    self->_transitionItems = [transitions copy];
    [self calculateDurations];
    
    [[NSUserDefaults standardUserDefaults] setInteger:images.count forKey:[NSString stringWithFormat:@"number_image_%@", self.projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self updateTransitionAndImageFilter];
    return imageItem;
}

- (SSProjectImageItem *)addVideo:(UIImage *)image url:(NSURL *)videoURL duration:(CMTime)duration generator:(AVAssetImageGenerator*)generator lastImg:(UIImage*)lastImage {
    NSAssert(image, @"Image is nil!");
    
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
//    NSMutableArray<SSProjectTransitionItem*>* transitions = [self.transitionItems mutableCopy];
    
//    if (images.count) {
//        SSProjectTransitionItem* transition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeDirectional];
//        transition.duration = 0;
//        [transitions addObject:transition];
//    }
    SSProjectImageItem* imageItem = [SSProjectImageItem itemWithImage:image size:self.settings.outputSize];
    imageItem.isVideo = true;
    imageItem.duration = CMTimeGetSeconds(duration);
    imageItem.lastImage = lastImage;
    imageItem.videoUrl = videoURL;
    imageItem.imgGenerator = generator;
    
    if (self.settings.outputRatio == kSSOutputRatio1_1) {
        [imageItem scaleToFill];
    }
    [images addObject:imageItem];
    self->_imageItems = [images copy];
//    self->_transitionItems = [transitions copy];
    [self calculateDurations];
    
    [[NSUserDefaults standardUserDefaults] setInteger:images.count forKey:[NSString stringWithFormat:@"number_image_%@", self.projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self updateTransitionAndImageFilter];
    return imageItem;
}

- (SSProjectImageItem *)insertVideo:(UIImage *)image insertNum:(int)index url:(NSURL *)videoURL duration:(CMTime)duration generator:(AVAssetImageGenerator*)generator lastImg:(UIImage*)lastImage {
    NSAssert(image, @"Image is nil!");
    
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
//    NSMutableArray<SSProjectTransitionItem*>* transitions = [self.transitionItems mutableCopy];
    
//    if (images.count) {
//        SSProjectTransitionItem* transition = [SSProjectTransitionItem itemWithTransitionType:kSSTransitionTypeDirectional];
//        transition.duration = 0;
//        [transitions addObject:transition];
//    }
    SSProjectImageItem* imageItem = [SSProjectImageItem itemWithImage:image size:self.settings.outputSize];
    imageItem.isVideo = true;
    imageItem.duration = CMTimeGetSeconds(duration);
    imageItem.lastImage = lastImage;
    imageItem.videoUrl = videoURL;
    imageItem.imgGenerator = generator;
    
    if (self.settings.outputRatio == kSSOutputRatio1_1) {
        [imageItem scaleToFill];
    }
    [images insertObject:imageItem atIndex:index];
//    [images addObject:imageItem];
    self->_imageItems = [images copy];
//    self->_transitionItems = [transitions copy];
    [self calculateDurations];
    
    [[NSUserDefaults standardUserDefaults] setInteger:images.count forKey:[NSString stringWithFormat:@"number_image_%@", self.projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self updateTransitionAndImageFilter];
    return imageItem;
}


-(void)removeImage:(SSProjectImageItem *)image {
    NSAssert(image, @"Item is nil!");
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
    NSMutableArray<SSProjectTransitionItem*>* transitions = [self.transitionItems mutableCopy];
    NSUInteger index = [images indexOfObject:image];
    NSAssert(index != NSNotFound, @"Couldn't find given item!");
    if (index == images.count - 1) {
        [images removeLastObject];
        [transitions removeLastObject];
    } else {
        [images removeObjectAtIndex:index];
        [transitions removeObjectAtIndex:index];
    }
    self->_imageItems = [images copy];
    self->_transitionItems = [transitions copy];
    [self calculateDurations];
    
    [[NSUserDefaults standardUserDefaults] setInteger:images.count forKey:[NSString stringWithFormat:@"number_image_%@", self.projectId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateTransitionAndImageFilter];
}

-(void)saveImage:(SSProjectImageItem *)image {
    NSAssert([self.imageItems containsObject:image], @"Invalid item!");
    NSMutableArray* images = [self.imageItems mutableCopy];
    NSUInteger index = [images indexOfObject:image];
    NSAssert(index != NSNotFound, @"Given item is not in the item array!");
    [images replaceObjectAtIndex:index withObject:image];
    self->_imageItems = [images copy];
}

-(void)replaceImageAtIndex:(NSInteger)fromIndex withImageAtIndex:(NSInteger)toIndex {
    NSAssert(fromIndex < self.imageItems.count || toIndex < self.imageItems.count, @"Invalid index!");
    SSProjectImageItem* fromImage = self.imageItems[fromIndex];
    SSProjectImageItem* toImage = self.imageItems[toIndex];
    NSMutableArray<SSProjectImageItem*>* images = [self.imageItems mutableCopy];
    images[fromIndex] = toImage;
    images[toIndex] = fromImage;
    self->_imageItems = [images copy];
}

-(void)updateLookupTables:(SSProjectImageItem *)image {
    if (!image) {
        self->_lookupTableAppliedToAll = NO;
        return;
    }
    
    for (SSProjectImageItem* currentImage in self.imageItems) {
        currentImage.shouldRandomizeLookupTable = image.shouldRandomizeLookupTable;
        currentImage.selectedLookupTableIndex = image.selectedLookupTableIndex;
    }
    self->_lookupTableAppliedToAll = YES;
}

-(void)updateTransition:(SSProjectTransitionItem*)transition applyToAll:(BOOL)applyToAll {
    NSAssert([self.transitionItems containsObject:transition], @"Invalid transition!");
    for (SSProjectTransitionItem* currentTransition in self.transitionItems) {
        if (applyToAll || [currentTransition isEqual:transition]) {
            currentTransition.shouldRandomizeTransition = transition.shouldRandomizeTransition;
            currentTransition.shouldUseAllTransitions = transition.shouldUseAllTransitions;
            if (!transition.shouldRandomizeTransition) {
                currentTransition.selectedTransitionType = transition.selectedTransitionType;
            }
            if (!applyToAll) {
                break;
            }
        }
    }
    self->_transitionAppliedToAll = applyToAll;
    self->_selectedTheme = -1; // reset theme
}

-(void)updateTheme:(int)theme {
    self->_selectedTheme = theme;
    self.settings.fixedPhotoDuration = 4;
    self.settings.fixedTransitionDuration = 2;
    if (self.imageItems.count == 0) {
        return;
    }
    // change music
    if (theme > 0) {
        // update music
        if (self.selectedTheme == 1 || self.selectedTheme == 5 || self.selectedTheme == 6 || self.selectedTheme == 7 || self.selectedTheme == 10 ) {
            self.settings.fixedPhotoDuration = 4;
            self.settings.fixedTransitionDuration = 3;
        } else {
            self.settings.fixedPhotoDuration = 4;
            self.settings.fixedTransitionDuration = 2;
        }
        NSString *musicTitle = [ThemeManager sharedInstance].themes[theme][@"music"];
        NSString* path = [[NSBundle mainBundle] pathForResource:musicTitle ofType:@"mp3"];
        NSURL* url = [NSURL fileURLWithPath:path];
        SSMusic *music = [SSMusic localStockMusicWithURL:url title:musicTitle locked:NO];
        [self updateMusics:@[music]];
        
    } else if (theme == 0) {
        [self updateMusics:@[]];
    }
    
    [self updateTransitionAndImageFilter];
}

- (void)updateTransitionAndImageFilter {
    // update item transition
    // MINHTH
    if (self.selectedTheme >= 0) {
        NSDictionary* selectedTheme = [ThemeManager sharedInstance].themes[self.selectedTheme];
        
        for (SSProjectTransitionItem *transition in self.transitionItems) {
            NSInteger currentIdx = [self.transitionItems indexOfObject:transition];
            NSLog(@"selectedTheme: %@", selectedTheme );
            NSArray *arrTransition = selectedTheme[@"theme"];
            NSInteger count = arrTransition.count;
            NSNumber *selectedTransition = arrTransition[currentIdx % count];
            transition.transitionType = [selectedTransition intValue];
            transition.selectedTransitionType = [selectedTransition intValue];
        }
        
        // update item image
        for (SSProjectImageItem *image in self.imageItems) {
            NSInteger currentIdx = [self.imageItems indexOfObject:image];
            NSArray *arrFilters = selectedTheme[@"filter"];
            NSInteger count = arrFilters.count;
            NSNumber *selectedFilter = arrFilters[currentIdx % count];
            image.selectedLookupTableIndex = [selectedFilter intValue];
        }
    }
//    if (self.selectedTheme >= 0) {
//        for (SSProjectTransitionItem* currentTransition in self.transitionItems) {
//            currentTransition.shouldRandomizeTransition = NO;
//        }
//    }
    
}

-(NSArray*)isVideo:(NSInteger)frame {
    
    NSMutableArray* objects = [[NSMutableArray alloc] init];
    
    NSTimeInterval frameTime = frame / self.framesPerSecond;
    NSTimeInterval currentTime = 0.0f;
    NSInteger sameFrameDuration = 0.0f;
    
    SSProjectItem* item;
    NSArray* between;
    for (NSInteger i=0; i<self.imageItems.count; i++) {
        SSProjectImageItem* image = self.imageItems[i];
        currentTime += [self getDuration:image]; //image.duration;
        if (currentTime >= frameTime) {
            item = image;
            if (image.isVideo) {
                [objects addObject:image.avAsset];
                
            }
        }
    }
    return objects;
}

//private func getFrame(fromTime:Float64) {
//    let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:20)
//    let image:CGImage
//    do {
//        try image = self.generator!.copyCGImage(at:time, actualTime:nil)
//    } catch {
//       return
//    }
//    self.frames.append(UIImage(cgImage:image))
//}

-(NSTimeInterval)getDuration:(SSProjectImageItem*)image {
    if (image.isVideo) {
        return image.duration;
    }
    return self.imageDuration;
//    self.settings.fixedPhotoDuration;
}

-(NSArray*)objectDataOfFrame:(NSInteger)frame {
//    let duration:Float64 = CMTimeGetSeconds(asset.duration)
    NSInteger currentIndex = -1;
    NSTimeInterval frameTime1 = (frame + 0) / self.framesPerSecond;
    NSTimeInterval currentTime1 = 0.0f;
    for (NSInteger i=0; i<self.imageItems.count; i++) {
        SSProjectImageItem* image = self.imageItems[i];
        currentTime1 += [self getDuration:image]; //image.duration;
        if (currentTime1 >= frameTime1) {
            currentIndex = i;
            break;
        }
    }
    if (currentIndex == -1) {
        currentIndex = self.imageItems.count - 1;
    }
//    Float64( duration / 120.0 * (Float64(index)))
    NSTimeInterval frameTime = frame / self.framesPerSecond;
    NSTimeInterval currentTime = 0.0f;
    NSInteger sameFrameDuration = 0.0f;
    
    SSProjectItem* item;
    NSArray* between;
    for (NSInteger i=0; i<self.imageItems.count; i++) {
        SSProjectImageItem* image = self.imageItems[i];
        currentTime += [self getDuration:image]; //image.duration;
        if (currentTime >= frameTime) {
            item = image;
            sameFrameDuration = currentTime - frameTime;
//            currentIndex = i;
            break;
        }
//        SSProjectTransitionItem* transition = self.transitionItems[i];
//
//        currentTime += transition.duration;
//        if (currentTime >= frameTime) {
//            item = transition;
//            between = @[self.imageItems[i], self.imageItems[i+1]];
//
//            break;
//        }
    }
    CGFloat progress = (frameTime - (currentTime - item.duration)) / item.duration;
    
    NSMutableArray* objects = [[NSMutableArray alloc] init];
    [objects addObject:item];
    [objects addObject:@(progress)];
    if (between) {
        [objects addObject:between];
    }
    [objects addObject:@(sameFrameDuration)];
    [objects addObject:@(currentIndex)];
    return objects;
}

-(NSInteger)indexTransition:(NSInteger)frame {
    NSTimeInterval frameTime = frame / self.framesPerSecond;
    NSTimeInterval currentTime = 0.0f;
    NSInteger sameFrameDuration = 0.0f;
    
    SSProjectItem* item;
    for (NSInteger i=0; i<self.imageItems.count; i++) {
        SSProjectImageItem* image = self.imageItems[i];
        currentTime += [self getDuration:image]; //image.duration;
        if (currentTime >= frameTime) {
            item = image;
            sameFrameDuration = currentTime - frameTime;
            return -1;
            break;
        }
//        SSProjectTransitionItem* transition = self.transitionItems[i];
//        currentTime += transition.duration;
//        if (currentTime >= frameTime) {
//            item = transition;
//            return i;
//        }
    }
    return -1;
}

#pragma mark - Duration
-(void)calculateDurations {
    NSTimeInterval imageDuration = self.settings.fixedPhotoDuration;
    NSTimeInterval transitionDuration = self.settings.fixedTransitionDuration;
    NSTimeInterval totalDuration = self.settings.fixedTotalDuration;
    
    if (self.settings.durationType != kSSDurationTypeFixedPhotoDuration) {
        if (self.settings.durationType == kSSDurationTypeFixedTotalDuration || self.musics.count == 0) {
            totalDuration = self.settings.fixedTotalDuration;
        } else if (self.settings.durationType == kSSDurationTypeSynchWithMusic) {
            CMTime currentTime = kCMTimeZero;
            for (SSMusic* music in self.musics) {
                NSURL *url = [[NSURL alloc] initWithString:music.url.absoluteString];
                AVAsset* asset = [AVAsset assetWithURL:url];
                // MINHTH - fake audio ratio by change 1 -> 30
                CMTime assetDuration = CMTimeMultiplyByRatio(asset.duration, 1, 1);
                currentTime = CMTimeAdd(currentTime, assetDuration);
            }
            totalDuration = CMTimeGetSeconds(currentTime);
        }
        NSTimeInterval idealTransitionDuration = 1.0f;
        NSTimeInterval idealTotalTransitionDuration = idealTransitionDuration * self.transitionItems.count;
        NSTimeInterval idealImageDuration = 2.0f;
        NSTimeInterval idealTotalImageDuration = idealImageDuration * self.imageItems.count;
        NSTimeInterval idealTotalDuration = idealTotalTransitionDuration + idealTotalImageDuration;
        CGFloat k = totalDuration / idealTotalDuration;
        if (k < 1.0f) {
            idealTransitionDuration *= k;
            idealImageDuration *= k;
        } else {
            NSTimeInterval maxTransitionDuration = 2.0f;
            idealTransitionDuration = MIN(maxTransitionDuration, idealTotalDuration * k);
            NSTimeInterval remainingDuration = totalDuration - (idealTransitionDuration * self.transitionItems.count);
            idealImageDuration = remainingDuration / self.imageItems.count;
        }
        imageDuration = idealImageDuration;
        transitionDuration = idealTransitionDuration;
    } else if (self.settings.durationType == kSSDurationTypeFixedPhotoDuration) {
        
    }
    totalDuration = 0;
    for (int i = 0; i < self.imageItems.count; i ++) {
        if (self.imageItems[i].isVideo) {
            totalDuration = totalDuration + self.imageItems[i].duration;
        } else {
            self.imageItems[i].duration = imageDuration;
            totalDuration = totalDuration + self.imageItems[i].duration;
        }
    }
    for (NSInteger i=0; i<self.imageItems.count; i++) {
        if (i < self.transitionItems.count) {
            self.transitionItems[i].duration = transitionDuration;
        }
    }
    self->_imageDuration = imageDuration;
    self->_transitionDuration = transitionDuration;
    self->_totalDuration = totalDuration;
    self->_totalFrameCount = self.totalDuration * self.framesPerSecond;
}

#pragma mark - Path
-(NSString *)exportedVideoPath {
    NSString* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* fileName = [NSString stringWithFormat:@"%@.mp4", self.projectId];
    NSString* filePath = [documentsPath stringByAppendingPathComponent:fileName];
    return filePath;
}
@end
