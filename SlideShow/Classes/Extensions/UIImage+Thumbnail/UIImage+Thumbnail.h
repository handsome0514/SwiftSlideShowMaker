//
//  UIImage+Thumbnail.h
//  VintageFX
//
//  Created by Arda Ozupek on 28.02.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Thumbnail)
-(UIImage*)thumbnail;
-(UIImage*)imageForSize:(CGSize)size;
@end

NS_ASSUME_NONNULL_END
