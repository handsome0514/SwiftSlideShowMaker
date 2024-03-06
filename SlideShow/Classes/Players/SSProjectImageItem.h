//
//  SSProjectImageItem.h
//  SlideShow
//
//  Created by Arda Ozupek on 23.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectItem.h"
#import <GPUImage.h>

@class SSPicture;
@class SSProjectTextItem;
@class SSProjectScribbleItem;

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectImageItem : SSProjectItem <NSCopying, NSCoding>
+(SSProjectImageItem *)itemWithImage:(UIImage *)image;
+(SSProjectImageItem *)itemWithImage:(UIImage *)image size:(CGSize)size;

@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) BOOL isVideoPlayed;
@property (nonatomic, strong) NSURL* videoUrl;
@property (nonatomic, strong) AVAsset* avAsset;
@property (nonatomic, strong) UIImage* lastImage;
@property (nonatomic, strong) AVAssetImageGenerator* imgGenerator;
@property (nonatomic, assign) CMTime videoDuration;

@property (nonatomic, strong, readonly) UIImage* rawImage;
@property (nonatomic, strong, readonly) SSPicture* rawImagePicture;
@property (nonatomic, assign) CGRect cropRegion;
-(void)recreateRawImagePictureForSize:(CGSize)size;
-(void)scaleToFill;

@property (nonatomic, strong, readonly) UIImage* rawThumbnail;
@property (nonatomic, strong, readonly) SSPicture* rawThumbnailPicture;
@property (nonatomic, strong, readonly) NSArray<UIImage*>* filteredThumbnails;

@property (nonatomic, assign) NSInteger selectedLookupTableIndex;               //  User-selected LUT index.
@property (nonatomic, assign, readonly) NSInteger randomizedLookupTableIndex;   //  Randomized LUT index which created in constructor.
@property (nonatomic, assign) BOOL shouldRandomizeLookupTable;
@property (nonatomic, assign, readonly) NSInteger lookupTableIndex;

@property (nonatomic, strong, readonly) NSArray<SSProjectTextItem*>* texts;
@property (nonatomic, strong, readonly) SSPicture* textPicture;
-(SSProjectTextItem*)createText;
-(void)removeText:(SSProjectTextItem*)text;
-(void)setTextsFrom:(SSProjectImageItem*)clone;
-(void)renderTexts;
-(void)renderTextsWithImage:(UIImage*)image;

@property (nonatomic, strong, readonly) SSProjectScribbleItem* scribble;
@property (nonatomic, strong, readonly) SSPicture* scribblePicture;
-(void)updateScribble:(SSProjectScribbleItem*)scribble;
-(void)renderScribble;
@end

NS_ASSUME_NONNULL_END
