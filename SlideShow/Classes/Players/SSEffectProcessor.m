//
//  SSEffectProcessor.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSEffectProcessor.h"
#import "SSCore.h"

NSString* const kSSOverrideCropRegionKey = @"OverrideCropRegion";
NSString* const kSSOverrideLookupTableKey = @"OverrideLookupTable";
NSString* const kSSDisableTextRenderingKey = @"DisableTextRendering";
NSString* const kSSDisableScribbleRenderingKey = @"DisableScribbleRendering";
NSString* const kSSWatermarkPictureKey = @"WatermarkPicture";
NSString* const kSSFrameDurationKey = @"FrameDuration";

@interface SSEffectProcessor ()
@property (nonatomic, strong) GPUImageSolidColorGenerator* colorGenerator;
@property (nonatomic, strong) GPUImageCropFilter* cropFilter;
@property (nonatomic, strong) GPUImageCropFilter* cropFilter2;
@property (nonatomic, strong) SSLookupFilter* lookupFilter;
@property (nonatomic, strong) SSLookupFilter* lookupFilter2;
@property (nonatomic, strong) SSOverlayFilter* textFilter;
@property (nonatomic, strong) SSOverlayFilter* textFilter2;
@property (nonatomic, strong) SSOverlayFilter* lineFilter;
@property (nonatomic, strong) SSOverlayFilter* lineFilter2;
@property (nonatomic, strong) SSTransitionFilter* transitionFilter;
@property (nonatomic, strong) SSOverlayFilter* watermarkFilter;
@end

@implementation SSEffectProcessor

static GPUImageCropFilter* cropFilter = nil;
static GPUImageTransformFilter* transformFilter = nil;
static SSLookupFilter* lookupFilter = nil;

#pragma mark - Life Cycle
+(void)initialize {
    if (self == [SSEffectProcessor self]) {
        cropFilter = [[GPUImageCropFilter alloc] init];
        transformFilter = [[GPUImageTransformFilter alloc] init];
        lookupFilter = [[SSLookupFilter alloc] init];
    }
}

+(SSEffectProcessor *)sharedInstance {
    static SSEffectProcessor* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SSEffectProcessor alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.colorGenerator = [[GPUImageSolidColorGenerator alloc] init];
        self.cropFilter = [[GPUImageCropFilter alloc] init];
        self.cropFilter2 = [[GPUImageCropFilter alloc] init];
        self.lookupFilter = [[SSLookupFilter alloc] init];
        self.lookupFilter2 = [[SSLookupFilter alloc] init];
        self.textFilter = [[SSOverlayFilter alloc] init];
        self.textFilter2 = [[SSOverlayFilter alloc] init];
        self.lineFilter = [[SSOverlayFilter alloc] init];
        self.lineFilter2 = [[SSOverlayFilter alloc] init];
        self.transitionFilter = [[SSTransitionFilter alloc] init];
        self.watermarkFilter = [[SSOverlayFilter alloc] init];
    }
    return self;
}


#pragma mark - Frames
-(void)generateBlankFrameToPlayer:(id<GPUImageInput>)player {
    [self.colorGenerator addTarget:player];
    [self.colorGenerator forceProcessingAtSize:CGSizeMake(1, 1)];
    [self.colorGenerator setColorRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
    [self.colorGenerator removeTarget:player];
}

-(void)generateFrameForImage:(SSProjectImageItem*)image toPlayer:(id<GPUImageInput>)player options:(NSDictionary*)options {
    CGRect cropRegion = image.cropRegion;
    //NSLog(@"crop region  %@", cropRegion);
    //CGRect cropRegion = CGRectMake(0.5, 0.5, 0.5, 0.5);
    
    NSValue* overrideCropRegion = options[kSSOverrideCropRegionKey];
    if (overrideCropRegion) {
        cropRegion = overrideCropRegion.CGRectValue;
    }
    BOOL shouldCrop = !CGRectEqualToRect(cropRegion, CGRectUnit);
    if (shouldCrop) {
        self.cropFilter.cropRegion = cropRegion;
        [image.rawImagePicture addTarget:self.cropFilter];
        [self.cropFilter addTarget:self.lookupFilter atTextureLocation:0];
    } else {
        [image.rawImagePicture addTarget:self.lookupFilter atTextureLocation:0];
    }
    
    NSInteger lookupTableIndex = image.lookupTableIndex;
    NSNumber* overrideLookupTableIndex = options[kSSOverrideLookupTableKey];
    if (overrideLookupTableIndex) {
        lookupTableIndex = overrideLookupTableIndex.integerValue;
    }
    SSLookupTable* lookupTable = [SSEffectManager sharedInstance].lookupTables[lookupTableIndex];
    [lookupTable.picture addTarget:self.lookupFilter atTextureLocation:1];
    
    BOOL shouldRenderLines = ![options[kSSDisableScribbleRenderingKey] boolValue] && image.scribblePicture;
    BOOL shouldRenderText = ![options[kSSDisableTextRenderingKey] boolValue] && image.textPicture;
    
    SSPicture* watermarkPicture = options[kSSWatermarkPictureKey];
    BOOL shouldRenderWatermark = watermarkPicture != nil;
    if (shouldRenderWatermark) {
        [watermarkPicture addTarget:self.watermarkFilter atTextureLocation:1];
        [self.watermarkFilter addTarget:player];
    }
    
    if (shouldRenderLines) {
        [self.lookupFilter addTarget:self.lineFilter atTextureLocation:0];
        [image.scribblePicture addTarget:self.lineFilter atTextureLocation:1];
        if (shouldRenderText) {
            [self.lineFilter addTarget:self.textFilter atTextureLocation:0];
            [image.textPicture addTarget:self.textFilter atTextureLocation:1];
            if (shouldRenderWatermark) {
                [self.textFilter addTarget:self.watermarkFilter atTextureLocation:0];
            } else {
                [self.textFilter addTarget:player];
            }
        } else {
            if (shouldRenderWatermark) {
                [self.lineFilter addTarget:self.watermarkFilter atTextureLocation:0];
            } else {
                [self.lineFilter addTarget:player];
            }
        }
    } else if (shouldRenderText) {
        [self.lookupFilter addTarget:self.textFilter atTextureLocation:0];
        [image.textPicture addTarget:self.textFilter atTextureLocation:1];
        if (shouldRenderWatermark) {
            [self.textFilter addTarget:self.watermarkFilter atTextureLocation:0];
        } else {
            [self.textFilter addTarget:player];
        }
    } else {
        if (shouldRenderWatermark) {
            [self.lookupFilter addTarget:self.watermarkFilter atTextureLocation:0];
        } else {
            [self.lookupFilter addTarget:player];
        }
    }
    
    // Transition Routing
    /*if (shouldRenderWatermark) {
        [self.transitionFilter addTarget:self.watermarkFilter atTextureLocation:0];
    } else {
        [self.transitionFilter addTarget:player];
    }
    self.transitionFilter.target
    self.transitionFilter.type = kSSTransitionTypeSimpleZoom;
    self.transitionFilter.progress = 0.5;
    self.transitionFilter.ratio = 2.0;*/
    
    NSLog(@"MINHTH ");
    
    CMTime frameTime = kCMTimeInvalid;
    NSValue* frameTimeValue = options[kSSFrameDurationKey];
    if (frameTimeValue) {
        frameTime = frameTimeValue.CMTimeValue;
    }
    
    [image.rawImagePicture processImageForTime:frameTime];
    [lookupTable.picture processImageForTime:frameTime];
    if (shouldRenderText) {
        [image.textPicture processImageForTime:frameTime];
    }
    if (shouldRenderLines) {
        [image.scribblePicture processImageForTime:frameTime];
    }
    if (shouldRenderWatermark) {
        [watermarkPicture processImageForTime:frameTime];
    }
    
    [self.watermarkFilter removeAllTargets];
    [watermarkPicture removeAllTargets];
    [self.textFilter removeAllTargets];
    [image.textPicture removeAllTargets];
    [self.lineFilter removeAllTargets];
    [image.scribblePicture removeAllTargets];
    [self.lookupFilter removeAllTargets];
    [lookupTable.picture removeAllTargets];
    [self.cropFilter removeAllTargets];
    [image.rawImagePicture removeAllTargets];
}

-(void)generateFrameForTransition:(SSProjectTransitionItem*)transition from:(SSProjectImageItem*)from to:(SSProjectImageItem*)to progress:(CGFloat)progress player:(id<GPUImageInput>)player fromOptions:(NSDictionary *)fromOptions toOption:(NSDictionary*)toOptions {
    
    // From Image Routing
    CGRect fromCropRegion = from.cropRegion;
    NSValue* overrideFromCropRegion = fromOptions[kSSOverrideCropRegionKey];
    if (overrideFromCropRegion) {
        fromCropRegion = overrideFromCropRegion.CGRectValue;
    }
    BOOL fromShouldCrop = !CGRectEqualToRect(fromCropRegion, CGRectUnit);
    if (fromShouldCrop) {
        self.cropFilter.cropRegion = fromCropRegion;
        [from.rawImagePicture addTarget:self.cropFilter];
        [self.cropFilter addTarget:self.lookupFilter atTextureLocation:0];
    } else {
        [from.rawImagePicture addTarget:self.lookupFilter atTextureLocation:0];
    }
    
    NSInteger fromLookupTableIndex = from.lookupTableIndex;
    NSNumber* overrideFromLookupTableIndex = fromOptions[kSSOverrideLookupTableKey];
    if (overrideFromLookupTableIndex) {
        fromLookupTableIndex = overrideFromLookupTableIndex.integerValue;
    }
    SSLookupTable* fromLookupTable = [SSEffectManager sharedInstance].lookupTables[fromLookupTableIndex];
    [fromLookupTable.picture addTarget:self.lookupFilter atTextureLocation:1];
    
    BOOL fromShouldRenderLines = ![fromOptions[kSSDisableScribbleRenderingKey] boolValue] && from.scribblePicture;
    BOOL fromShouldRenderText = ![fromOptions[kSSDisableTextRenderingKey] boolValue] && from.textPicture;
    
    if (fromShouldRenderLines) {
        [self.lookupFilter addTarget:self.lineFilter atTextureLocation:0];
        [from.scribblePicture addTarget:self.lineFilter atTextureLocation:1];
        if (fromShouldRenderText) {
            [self.lineFilter addTarget:self.textFilter atTextureLocation:0];
            [from.textPicture addTarget:self.textFilter atTextureLocation:1];
            [self.textFilter addTarget:self.transitionFilter atTextureLocation:0];
        } else {
            [self.lineFilter addTarget:self.transitionFilter atTextureLocation:0];
        }
    } else if (fromShouldRenderText) {
        [self.lookupFilter addTarget:self.textFilter atTextureLocation:0];
        [from.textPicture addTarget:self.textFilter atTextureLocation:1];
        [self.textFilter addTarget:self.transitionFilter atTextureLocation:0];
    } else {
        [self.lookupFilter addTarget:self.transitionFilter atTextureLocation:0];
    }
    
    // To Image Routing
    CGRect toCropRegion = to.cropRegion;
    NSValue* overrideToCropRegion = toOptions[kSSOverrideCropRegionKey];
    if (overrideToCropRegion) {
        toCropRegion = overrideToCropRegion.CGRectValue;
    }
    BOOL toShouldCrop = !CGRectEqualToRect(toCropRegion, CGRectUnit);
    if (toShouldCrop) {
        self.cropFilter2.cropRegion = toCropRegion;
        [to.rawImagePicture addTarget:self.cropFilter2];
        [self.cropFilter2 addTarget:self.lookupFilter2 atTextureLocation:0];
    } else {
        [to.rawImagePicture addTarget:self.lookupFilter2 atTextureLocation:0];
    }
    
    NSInteger toLookupTableIndex = to.lookupTableIndex;
    NSNumber* overrideToLookupTableIndex = toOptions[kSSOverrideLookupTableKey];
    if (overrideToLookupTableIndex) {
        toLookupTableIndex = overrideToLookupTableIndex.integerValue;
    }
    SSLookupTable* toLookupTable = [SSEffectManager sharedInstance].lookupTables[toLookupTableIndex];
    [toLookupTable.picture addTarget:self.lookupFilter2 atTextureLocation:1];
    
    BOOL toShouldRenderLines = ![toOptions[kSSDisableScribbleRenderingKey] boolValue] && to.scribblePicture;
    BOOL toShouldRenderText = ![toOptions[kSSDisableTextRenderingKey] boolValue] && to.textPicture;
    
    if (toShouldRenderLines) {
        [self.lookupFilter2 addTarget:self.lineFilter2 atTextureLocation:0];
        [to.scribblePicture addTarget:self.lineFilter2 atTextureLocation:1];
        if (toShouldRenderText) {
            [self.lineFilter2 addTarget:self.textFilter2 atTextureLocation:0];
            [to.textPicture addTarget:self.textFilter2 atTextureLocation:1];
            [self.textFilter2 addTarget:self.transitionFilter atTextureLocation:1];
        } else {
            [self.lineFilter2 addTarget:self.transitionFilter atTextureLocation:1];
        }
    } else if (toShouldRenderText) {
        [self.lookupFilter2 addTarget:self.textFilter2 atTextureLocation:0];
        [to.textPicture addTarget:self.textFilter2 atTextureLocation:1];
        [self.textFilter2 addTarget:self.transitionFilter atTextureLocation:1];
    } else {
        [self.lookupFilter2 addTarget:self.transitionFilter atTextureLocation:1];
    }
    
    
    // Watermark
    SSPicture* watermarkPicture = fromOptions[kSSWatermarkPictureKey];
    if (!watermarkPicture) {
        watermarkPicture = toOptions[kSSWatermarkPictureKey];
    }
    BOOL shouldRenderWatermark = watermarkPicture != nil;
    if (shouldRenderWatermark) {
        [watermarkPicture addTarget:self.watermarkFilter atTextureLocation:1];
        [self.watermarkFilter addTarget:player];
    }
    
    
    // Transition Routing
    if (shouldRenderWatermark) {
        [self.transitionFilter addTarget:self.watermarkFilter atTextureLocation:0];
    } else {
        [self.transitionFilter addTarget:player];
    }
    self.transitionFilter.type = transition.transitionType;
    self.transitionFilter.progress = progress;
    self.transitionFilter.ratio = from.rawImagePicture.outputImageSize.width / from.rawImagePicture.outputImageSize.height;
    
    
    // Frame Duration
    CMTime frameTime = kCMTimeInvalid;
    NSValue* frameTimeValue = fromOptions[kSSFrameDurationKey];
    if (!frameTimeValue) {
        frameTimeValue = toOptions[kSSFrameDurationKey];
    }
    if (frameTimeValue) {
        frameTime = frameTimeValue.CMTimeValue;
    }
    
    // Process From Image
    [from.rawImagePicture processImageForTime:frameTime];
    [fromLookupTable.picture processImageForTime:frameTime];
    if (fromShouldRenderText) {
        [from.textPicture processImageForTime:frameTime];
    }
    if (fromShouldRenderLines) {
        [from.scribblePicture processImageForTime:frameTime];
    }
    
    // Process To Image
    [to.rawImagePicture processImageForTime:frameTime];
    [toLookupTable.picture processImageForTime:frameTime];
    if (toShouldRenderText) {
        [to.textPicture processImageForTime:frameTime];
    }
    if (toShouldRenderLines) {
        [to.scribblePicture processImageForTime:frameTime];
    }
    
    // Process Watermark
    if (shouldRenderWatermark) {
        [watermarkPicture processImageForTime:frameTime];
    }
    
    [self.cropFilter removeAllTargets];
    [self.lookupFilter removeAllTargets];
    [self.lineFilter removeAllTargets];
    [self.textFilter removeAllTargets];
    
    [self.cropFilter2 removeAllTargets];
    [self.lookupFilter2 removeAllTargets];
    [self.lineFilter2 removeAllTargets];
    [self.textFilter2 removeAllTargets];
    
    [self.transitionFilter removeAllTargets];
    [self.watermarkFilter removeAllTargets];
    
    [from.rawImagePicture removeAllTargets];
    [from.scribblePicture removeAllTargets];
    [from.textPicture removeAllTargets];
    [fromLookupTable.picture removeAllTargets];
    
    [to.rawImagePicture removeAllTargets];
    [to.scribblePicture removeAllTargets];
    [to.textPicture removeAllTargets];
    [toLookupTable.picture removeAllTargets];
    
    [watermarkPicture removeAllTargets];
}

-(void)generateLowResTransition:(SSTransition*)transition from:(SSProjectImageItem*)from to:(SSProjectImageItem*)to progress:(CGFloat)progress player:(id<GPUImageInput>)player {
    [from.rawThumbnailPicture addTarget:self.transitionFilter atTextureLocation:0];
    [to.rawThumbnailPicture addTarget:self.transitionFilter atTextureLocation:1];
    [self.transitionFilter addTarget:player];
    
    self.transitionFilter.type = transition.type;
    self.transitionFilter.progress = progress;
    self.transitionFilter.ratio = from.rawThumbnailPicture.outputImageSize.width / from.rawThumbnailPicture.outputImageSize.height;
    
    [from.rawThumbnailPicture processImage];
    [to.rawThumbnailPicture processImage];
    
    [self.transitionFilter removeAllTargets];
    [from.rawThumbnailPicture removeAllTargets];
    [to.rawThumbnailPicture removeAllTargets];
    
//    [self.transitionFilter removeTarget:player];
//    [from.rawThumbnailPicture removeTarget:self.transitionFilter];
//    [to.rawThumbnailPicture removeTarget:self.transitionFilter];
}


#pragma mark - Filters
+(void)generateThumbnailFromImage:(SSProjectImageItem*)image lookupTable:(SSLookupTable*)lookupTable toPlayer:(id<GPUImageInput>)player {
    [image.rawThumbnailPicture addTarget:lookupFilter atTextureLocation:0];
    [lookupTable.picture addTarget:lookupFilter atTextureLocation:1];
    [lookupFilter addTarget:player];
    [image.rawThumbnailPicture processImage];
    [lookupTable.picture processImage];
    [lookupFilter removeTarget:player];
    [lookupTable.picture removeTarget:lookupFilter];
    [image.rawThumbnailPicture removeTarget:lookupFilter];
}

+(NSArray<UIImage*>*)generateFilteredThumbnails:(SSPicture*)source {
    NSMutableArray<UIImage*>* filteredImages = [[NSMutableArray alloc] init];
    [source addTarget:lookupFilter atTextureLocation:0];
    for (SSLookupTable* lookupTable in [SSEffectManager sharedInstance].lookupTables) {
        [lookupTable.picture addTarget:lookupFilter atTextureLocation:1];
        [lookupFilter useNextFrameForImageCapture];
        [source processImage];
        [lookupTable.picture processImage];
        UIImage* filteredImage = [lookupFilter imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
        [filteredImages addObject:filteredImage];
        [lookupTable.picture removeTarget:lookupFilter];
    }
    [source removeTarget:lookupFilter];
    return [filteredImages copy];
}

+(UIImage*)generateScaledRawImage:(UIImage*)rawImage atSize:(CGSize)size {
    SSPicture* picture = [[SSPicture alloc] initWithImage:rawImage];
    [picture addTarget:transformFilter];
    CGSize scaledSize = CGSizeAspectFit(rawImage.size, size);
    CGPoint scale = CGPointMake(scaledSize.width / size.width, scaledSize.height / size.height);
    transformFilter.affineTransform = CGAffineTransformMakeScale(scale.x, scale.y);
    [transformFilter forceProcessingAtSize:size];
    [transformFilter useNextFrameForImageCapture];
    [picture processImage];
    UIImage* image = [transformFilter imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
    [picture removeTarget:transformFilter];
    return image;
}


#pragma mark - UIKit
+(UIImage*)imageFromView:(UIView*)view scale:(CGFloat)scale opaque:(BOOL)opaque {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, opaque, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark - UIImage
+(UIImage *)cropImage:(UIImage *)image region:(CGRect)region {
    SSPicture* picture = [[SSPicture alloc] initWithImage:image];
    [picture addTarget:cropFilter];
    cropFilter.cropRegion = region;
    [cropFilter useNextFrameForImageCapture];
    [picture processImage];
    UIImage* croppedImage = [cropFilter imageFromCurrentFramebufferWithOrientation:UIImageOrientationUp];
    [picture removeTarget:cropFilter];
    return croppedImage;
}

+(CGImageRef)rotateImage:(UIImage*)image angle:(CGFloat)angle {
    CGImageRef imgRef = image.CGImage;
    CGFloat angleInRadians = angle * (M_PI / 180);
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, rotatedRect.size.width, rotatedRect.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(bmContext, YES);
    CGContextSetShouldAntialias(bmContext, YES);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    CGColorSpaceRelease(colorSpace);
    CGContextTranslateCTM(bmContext, (rotatedRect.size.width/2), (rotatedRect.size.height/2));
    CGContextRotateCTM(bmContext, angleInRadians);
    CGContextTranslateCTM(bmContext, -(rotatedRect.size.width/2), -(rotatedRect.size.height/2));
    CGContextDrawImage(bmContext, CGRectMake(0, 0, rotatedRect.size.width, rotatedRect.size.height), imgRef);
    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    return rotatedImage;
}

+(UIImage*)tintImage:(UIImage*)image withColor:(UIColor*)color scale:(CGFloat)scale {
    UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    CGSize size = CGSizeMake(image.size.width * scale, image.size.height * scale);
    UIGraphicsBeginImageContextWithOptions(size, NO, newImage.scale);
    [color set];
    [newImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
