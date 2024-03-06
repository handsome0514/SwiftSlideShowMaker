//
//  SSEffectProcessor.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage.h>

extern NSString* const kSSOverrideCropRegionKey;
extern NSString* const kSSOverrideLookupTableKey;
extern NSString* const kSSDisableTextRenderingKey;
extern NSString* const kSSDisableScribbleRenderingKey;
extern NSString* const kSSWatermarkPictureKey;
extern NSString* const kSSFrameDurationKey;

@class SSProjectImageItem;
@class SSProjectTransitionItem;
@class SSTransition;
@class SSLookupTable;
@class SSPlayer;
@class SSPicture;

@interface SSEffectProcessor : NSObject
+(SSEffectProcessor*)sharedInstance;
+(void)generateThumbnailFromImage:(SSProjectImageItem*)image lookupTable:(SSLookupTable*)lookupTable toPlayer:(id<GPUImageInput>)player;
+(NSArray<UIImage*>*)generateFilteredThumbnails:(SSPicture*)source;
+(UIImage*)generateScaledRawImage:(UIImage*)rawImage atSize:(CGSize)size;
+(UIImage*)imageFromView:(UIView*)view scale:(CGFloat)scale opaque:(BOOL)opaque;
+(CGImageRef)rotateImage:(UIImage*)image angle:(CGFloat)angle;
+(UIImage*)tintImage:(UIImage*)image withColor:(UIColor*)color scale:(CGFloat)scale;
+(UIImage*)cropImage:(UIImage*)image region:(CGRect)region;

-(void)generateBlankFrameToPlayer:(id<GPUImageInput>)player;
-(void)generateFrameForImage:(SSProjectImageItem*)image toPlayer:(id<GPUImageInput>)player options:(NSDictionary*)options;
-(void)generateFrameForTransition:(SSProjectTransitionItem*)transition from:(SSProjectImageItem*)from to:(SSProjectImageItem*)to progress:(CGFloat)progress player:(id<GPUImageInput>)player fromOptions:(NSDictionary *)fromOptions toOption:(NSDictionary*)toOptions;
-(void)generateLowResTransition:(SSTransition*)transition from:(SSProjectImageItem*)from to:(SSProjectImageItem*)to progress:(CGFloat)progress player:(id<GPUImageInput>)player;

@end
