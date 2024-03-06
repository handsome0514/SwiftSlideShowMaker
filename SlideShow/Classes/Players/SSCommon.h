//
//  SSCommon.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat SSOutputFPS;

extern const CGSize SSPhotoInputSize;

extern const CGRect CGRectUnit;

typedef NS_ENUM(NSInteger, SSOutputRatio) {
    kSSOutputRatio1_1 = 0,
    kSSOutputRatio16_9 = 1,
    kSSOutputRatio9_16 = 2
};

typedef NS_ENUM(NSInteger, SSDurationType) {
    kSSDurationTypeFixedPhotoDuration = 0,
    kSSDurationTypeSynchWithMusic = 1,
    kSSDurationTypeFixedTotalDuration = 2
};

CGSize SSPreviewOutputSize(const SSOutputRatio ratio);
CGSize SSExportOutputSize(const SSOutputRatio ratio);
CGSize SSVideoOutputSize(const SSOutputRatio ratio);
NSString* SSOutputSizeKey(const SSOutputRatio ratio);

CGSize CGSizeAspectFill(const CGSize aspectRatio, const CGSize minimumSize);
CGSize CGSizeAspectFit(const CGSize aspectRatio, const CGSize boundingSize);
CGSize CGSizeAspectCrop(const CGSize aspectRatio, const CGSize mainSize);
CGSize CGSizeScale(const CGSize size, float scale);
CGSize CGSizeFixForVideo(const CGSize mainSize);
CGFloat CGSizeAspectRatio(const CGSize aspectRatio);
CGRect CGRectNormalize(const CGRect rect, const CGSize bounds);
CGRect CGRectDenormalize(const CGRect rect, const CGSize bounds);
CGSize CGSizeNormalize(const CGSize size, const CGSize bounds);
CGSize CGSizeDenormalize(const CGSize size, const CGSize bounds);
CGPoint CGPointNormalize(const CGPoint point, const CGSize bounds);
CGPoint CGPointDenormalize(const CGPoint point, const CGSize bounds);
