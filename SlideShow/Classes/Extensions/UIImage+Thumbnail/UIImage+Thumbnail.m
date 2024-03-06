//
//  UIImage+Thumbnail.m
//  VintageFX
//
//  Created by Arda Ozupek on 28.02.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "UIImage+Thumbnail.h"
#import "SSCommon.h"

@implementation UIImage (Thumbnail)

-(UIImage*)thumbnail {
    return [self imageForSize:CGSizeMake(200.0f, 200.0f)];
}

-(UIImage*)imageForSize:(CGSize)size {
    CGSize scaledSize = CGSizeAspectFill(self.size, size);
    scaledSize.width = floorf(scaledSize.width);
    scaledSize.height = floorf(scaledSize.height);
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 1);
    [self drawInRect:CGRectMake(0.0f, 0.0f, scaledSize.width, scaledSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

@end
