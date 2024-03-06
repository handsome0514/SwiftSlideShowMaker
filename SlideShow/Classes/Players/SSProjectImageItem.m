//
//  SSProjectImageItem.m
//  SlideShow
//
//  Created by Arda Ozupek on 23.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectImageItem.h"
#import "SSCore.h"
#import "UIImage+Thumbnail.h"
#import "SSProjectTextItem.h"

@implementation SSProjectImageItem

@synthesize isVideo, imgGenerator;

#pragma mark - Life Cycle
+(SSProjectImageItem *)itemWithImage:(UIImage *)image {
    NSAssert(image, @"Invalid argument!");
    UIImage* thumbnail = [image thumbnail];
    SSPicture* picture = [[SSPicture alloc] initWithImage:image];
    SSPicture* thumbPicture = [[SSPicture alloc] initWithImage:thumbnail];
    NSAssert(thumbnail && picture && thumbPicture, @"Couldn't create texture from image!");
//    NSArray<UIImage*>* filteredThumbs = [SSEffectProcessor generateFilteredThumbnails:thumbPicture];
//    NSAssert(filteredThumbs, @"Couldn't create filtered thumbnails!");
    
    SSProjectImageItem* item = [[SSProjectImageItem alloc] init];
    item->_rawImage = image;
    item->_rawThumbnail = thumbnail;
    item->_rawImagePicture = picture;
    item->_rawThumbnailPicture = thumbPicture;
//    item->_filteredThumbnails = filteredThumbs;
    return item;
}

+(SSProjectImageItem *)itemWithImage:(UIImage *)image size:(CGSize)size {
    NSAssert(image, @"Invalid argument!");
//    CGSize fitSize = CGSizeAspectFit(image.size, size);
//    UIImage* preview = [SSEffectProcessor generateScaledRawImage:image atSize:size];
//    UIImage* thumbnail = [image thumbnail];
    SSPicture* picture = [[SSPicture alloc] initWithImage: image]; //preview
//    SSPicture* thumbPicture = [[SSPicture alloc] initWithImage:thumbnail];
//    NSAssert(thumbnail && picture && thumbPicture, @"Couldn't create texture from image!");
//    NSArray<UIImage*>* filteredThumbs = [SSEffectProcessor generateFilteredThumbnails:thumbPicture];
//    NSAssert(filteredThumbs, @"Couldn't create filtered thumbnails!");
    
    SSProjectImageItem* item = [[SSProjectImageItem alloc] init];
    item->_rawImage = image;
    item->_rawThumbnail = image; //humbnail;
    item->_rawImagePicture = picture; //picture;
    item->_rawThumbnailPicture = picture; //thumbPicture;
//    item->_filteredThumbnails = filteredThumbs;
    return item;
}

-(instancetype)init {
    self = [super init];
    if (self) {
//        self->_randomizedLookupTableIndex = [[SSEffectManager sharedInstance] randomLookupTableIndex];
//        self->_shouldRandomizeLookupTable = NO;
        self->_texts = @[];
//        self->_scribble = [SSProjectScribbleItem scribble];
        self->_cropRegion = CGRectUnit;
    }
    return self;
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:UIImagePNGRepresentation(self.rawImage) forKey:@"rawImage"];
    [aCoder encodeObject:NSStringFromCGRect(self.cropRegion) forKey:@"cropRegion"];
    [aCoder encodeInteger:self.selectedLookupTableIndex forKey:@"selectedLookupTableIndex"];
    [aCoder encodeInteger:self.randomizedLookupTableIndex forKey:@"randomizedLookupTableIndex"];
    [aCoder encodeBool:self.shouldRandomizeLookupTable forKey:@"shouldRandomizeLookupTable"];
    [aCoder encodeObject:self.texts forKey:@"texts"];
    [aCoder encodeObject:self.scribble forKey:@"scribble"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self->_rawImage = [UIImage imageWithData:[aDecoder decodeObjectForKey:@"rawImage"]];
        self->_cropRegion = CGRectFromString([aDecoder decodeObjectForKey:@"cropRegion"]);
        self->_selectedLookupTableIndex = [aDecoder decodeIntegerForKey:@"selectedLookupTableIndex"];
        self->_randomizedLookupTableIndex = [aDecoder decodeIntegerForKey:@"randomizedLookupTableIndex"];
        self->_shouldRandomizeLookupTable = [aDecoder decodeBoolForKey:@"shouldRandomizeLookupTable"];
        self->_texts = [aDecoder decodeObjectForKey:@"texts"];
        self->_scribble = [aDecoder decodeObjectForKey:@"scribble"];
//        self->_rawImagePicture = [[SSPicture alloc] initWithImage:self.rawImage]; //SSProject will call applySettings after init
        self->_rawThumbnail = [self.rawImage thumbnail];
        self->_rawThumbnailPicture = [[SSPicture alloc] initWithImage:self.rawThumbnail];
//        self->_filteredThumbnails = [SSEffectProcessor generateFilteredThumbnails:self.rawThumbnailPicture];
    }
    return self;
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectImageItem* item = [super copyWithZone:zone];
    if (item) {
//        item->isVideo = self.isVideo;
//        item->_videoUrl = self.videoUrl;
//        item->_avAsset = self.avAsset;
//        item->_imgGenerator = self.imgGenerator;
        item->_rawImage = self.rawImage;
        item->_rawThumbnail = self.rawThumbnail;
        item->_rawImagePicture = self.rawImagePicture;
        item->_rawThumbnailPicture = self.rawThumbnailPicture;
        item->_cropRegion = self.cropRegion;
        item->_filteredThumbnails = self.filteredThumbnails;
        item->_selectedLookupTableIndex = self.selectedLookupTableIndex;
        item->_randomizedLookupTableIndex = self.randomizedLookupTableIndex;
        item->_shouldRandomizeLookupTable = self.shouldRandomizeLookupTable;
        NSMutableArray* texts = [[NSMutableArray alloc] init];
        for (SSProjectTextItem* text in self.texts) {
            [texts addObject:[text copy]];
        }
        item->_texts = [texts copy];
        item->_scribble = [self.scribble copy];
    }
    return item;
}


#pragma mark - Lookup Table Index
-(NSInteger)lookupTableIndex {
    return self.shouldRandomizeLookupTable ? self.randomizedLookupTableIndex : self.selectedLookupTableIndex;
}


#pragma mark - Size
-(void)recreateRawImagePictureForSize:(CGSize)size {
    UIImage* image = [SSEffectProcessor generateScaledRawImage:self.rawImage atSize:size];
    SSPicture* picture = [[SSPicture alloc] initWithImage:image];
    self->_rawImagePicture = picture;
}

-(void)scaleToFill {
    CGSize bounds = self.rawImagePicture.outputImageSize;
    CGSize imageSize = CGSizeAspectFit(self.rawImage.size, bounds);
    CGPoint scale = CGPointMake(bounds.width / imageSize.width, bounds.height / imageSize.height);
    CGFloat k = MAX(scale.x, scale.y);
    CGSize size = CGSizeMake(1.0f / k, 1.0f / k);
    // _Edited by Steven
    size = CGSizeMake(1.0f / scale.x, 1.0f / scale.y);
    CGPoint origin = CGPointMake((1.0f - size.width) * 0.5f, (1.0f - size.height) * 0.5f);
    CGRect cropRegion = (CGRect){origin, size};
    self.cropRegion = cropRegion;
}


#pragma mark - Text
-(SSProjectTextItem *)createText {
    NSMutableArray<SSProjectTextItem*>* currentTexts = [self.texts mutableCopy];
    SSProjectTextItem* text = [SSProjectTextItem textWithTitle:@"Title"];
    if (text) {
        [currentTexts addObject:text];
        self->_texts = [currentTexts copy];
    }
    return text;
}

-(void)removeText:(SSProjectTextItem *)text {
    NSAssert([self.texts containsObject:text], @"Given text is not added to current image item!");
    NSMutableArray* currentTexts = [self.texts mutableCopy];
    [currentTexts removeObject:text];
    self->_texts = [currentTexts copy];
}

-(void)setTextsFrom:(SSProjectImageItem *)clone {
    NSAssert([clone isEqual:self], @"Given image is not equal to self!");
    self->_texts = [clone.texts copy];
}

-(void)renderTexts {
    if (!self.texts.count) {
        self->_textPicture = nil;
        return;
    }
    
    CGSize outputSize = self.rawImagePicture.outputImageSize;
    CGRect bounds = (CGRect){CGPointZero, outputSize};
    UIView* view = [[UIView alloc] initWithFrame:bounds];
    for (SSProjectTextItem* text in self.texts) {
        SSLabel* label = [text generateLabelToRenderAtSize:outputSize];
        [view addSubview:label];
    }
    UIImage* image = [SSEffectProcessor imageFromView:view scale:1.0f opaque:NO];
    SSPicture* picture = [[SSPicture alloc] initWithImage:image];
    self->_textPicture = picture;
}

-(void)renderTextsWithImage:(UIImage *)image {
    if (image) {
        UIImage* scaledImage = [SSEffectProcessor generateScaledRawImage:image atSize:self.rawImagePicture.outputImageSize];
        SSPicture* picture = [[SSPicture alloc] initWithImage:scaledImage];
        self->_textPicture = picture;
    }
    else {
        self->_textPicture = nil;
    }
}


#pragma mark - Scribble
-(void)updateScribble:(SSProjectScribbleItem *)scribble {
    NSAssert([scribble isEqual:self.scribble], @"Invalid scribble!");
    self->_scribble = scribble;
}

-(void)renderScribble {
    if (!self.scribble.imageView.image) {
        self->_scribblePicture = nil;
        return;
    }
    
    CGSize imageViewSize = self.scribble.imageView.frame.size;
    CGRect region = AVMakeRectWithAspectRatioInsideRect(self.rawImagePicture.outputImageSize, (CGRect){CGPointZero, imageViewSize});
    region = CGRectNormalize(region, imageViewSize);
    UIImage* croppedImage = [SSEffectProcessor cropImage:self.scribble.imageView.image region:region];
    SSPicture* picture = [[SSPicture alloc] initWithImage:croppedImage];
    self->_scribblePicture = picture;
}

@end
