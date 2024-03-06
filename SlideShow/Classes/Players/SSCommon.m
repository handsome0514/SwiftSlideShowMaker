//
//  SSCommon.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSCore.h"

const CGFloat SSOutputFPS = 30.0f;

const CGSize SSPhotoInputSize = (CGSize){1080.0f, 1080.0f};

const CGRect CGRectUnit = (CGRect){0.0f, 0.0f, 1.0f, 1.0f};

CGSize SSPreviewOutputSize(const SSOutputRatio ratio) {
    CGFloat longSide = 1080.0f;
    CGFloat shortSide = 810.0f;
    CGSize size = CGSizeZero;
    if (ratio == kSSOutputRatio16_9) {
        size = CGSizeMake(longSide, shortSide);
    }
    else if (ratio == kSSOutputRatio9_16) {
        size = CGSizeMake(shortSide, longSide);
    }
    else if (ratio == kSSOutputRatio1_1) {
        size = CGSizeMake(longSide, longSide);
    }
    return size;
}

CGSize SSExportOutputSize(const SSOutputRatio ratio) {
    CGFloat longSide = 1080.0f;
    CGFloat shortSide = 810.0f;
    CGSize size = CGSizeZero;
    if (ratio == kSSOutputRatio16_9) {
        size = CGSizeMake(longSide, shortSide);
    }
    else if (ratio == kSSOutputRatio9_16) {
        size = CGSizeMake(shortSide, longSide);
    }
    else if (ratio == kSSOutputRatio1_1) {
        size = CGSizeMake(longSide, longSide);
    }
    return size;
}

CGSize SSVideoOutputSize(const SSOutputRatio ratio) {
    CGFloat longSide = 1080.0f;
    CGFloat shortSide = 810.0f;
    CGSize size = CGSizeZero;
    if (ratio == kSSOutputRatio16_9) {
        size = CGSizeMake(longSide, shortSide);
    }
    else if (ratio == kSSOutputRatio9_16) {
        size = CGSizeMake(shortSide, longSide);
    }
    else if (ratio == kSSOutputRatio1_1) {
        size = CGSizeMake(longSide, longSide);
    }
    return size;
}



NSString* SSOutputSizeKey(const SSOutputRatio ratio) {
    if (ratio == kSSOutputRatio16_9) {
        return @"16_9";
    }
    else if (ratio == kSSOutputRatio9_16) {
        return @"9_16";
    }
    else if (ratio == kSSOutputRatio1_1) {
        return @"1_1";
    }
    return @"";
}

CGSize CGSizeAspectFill(const CGSize aspectRatio, const CGSize minimumSize) {
    CGSize aspectFillSize = CGSizeMake(minimumSize.width, minimumSize.height);
    CGFloat width = minimumSize.width / aspectRatio.width;
    CGFloat height = minimumSize.height / aspectRatio.height;
    if (height > width) {
        aspectFillSize.width = height * aspectRatio.width;
    } else if (width > height) {
        aspectFillSize.height = width * aspectRatio.height;
    }
    return aspectFillSize;
}

CGSize CGSizeAspectFit(const CGSize aspectRatio, const CGSize boundingSize) {
    CGSize aspectFitSize = CGSizeMake(boundingSize.width, boundingSize.height);
    CGFloat width = boundingSize.width / aspectRatio.width;
    CGFloat height = boundingSize.height / aspectRatio.height;
    if (height < width) {
        aspectFitSize.width = height * aspectRatio.width;
    } else if (width < height) {
        aspectFitSize.height = width * aspectRatio.height;
    }
    return aspectFitSize;
}

CGSize CGSizeAspectCrop(const CGSize aspectRatio, const CGSize mainSize) {
    if (CGSizeEqualToSize(aspectRatio, CGSizeZero)) {
        return mainSize;
    }
    
    CGSize cropSize = CGSizeMake(mainSize.width, mainSize.height);
    if (aspectRatio.width == aspectRatio.height) {
        if (mainSize.width < mainSize.height) {
            cropSize.height = mainSize.width;
        } else {
            cropSize.width = mainSize.height;
        }
    } else {
        cropSize.width = mainSize.height * (aspectRatio.width / aspectRatio.height);
    }
    
    return cropSize;
}

CGSize CGSizeScale(const CGSize size, float scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

CGSize CGSizeFixForVideo(const CGSize mainSize) {
    CGSize videoSize = CGSizeMake(floor(mainSize.width / 16) * 16,
                                  floor(mainSize.height / 16) * 16);
    return videoSize;
}

CGFloat CGSizeAspectRatio(const CGSize aspectRatio) {
    return aspectRatio.width / aspectRatio.height;
}

CGRect CGRectNormalize(const CGRect rect, const CGSize bounds) {
    return CGRectMake(rect.origin.x / bounds.width,
                      rect.origin.y / bounds.height,
                      rect.size.width / bounds.width,
                      rect.size.height / bounds.height);
}

CGRect CGRectDenormalize(const CGRect rect, const CGSize bounds) {
    return CGRectMake(rect.origin.x * bounds.width,
                      rect.origin.y * bounds.height,
                      rect.size.width * bounds.width,
                      rect.size.height * bounds.height);
}

CGSize CGSizeNormalize(const CGSize size, const CGSize bounds) {
    return CGSizeMake(size.width / bounds.width, size.height / bounds.height);
}

CGSize CGSizeDenormalize(const CGSize size, const CGSize bounds) {
    return CGSizeMake(size.width * bounds.width, size.height * bounds.height);
}

CGPoint CGPointNormalize(const CGPoint point, const CGSize bounds) {
    return CGPointMake(point.x / bounds.width, point.y / bounds.height);
}

CGPoint CGPointDenormalize(const CGPoint point, const CGSize bounds) {
    return CGPointMake(point.x * bounds.width, point.y * bounds.height);
}
