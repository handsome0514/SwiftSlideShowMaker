//
//  SSBrush.h
//  SlideShow
//
//  Created by Arda Ozupek on 10.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SSBrushType) {
    kSSBrushTypeCircle = 0,
    kSSBrushTypeGlow = 1,
    kSSBrushTypeSparkles = 2,
    kSSBrushTypeBlur = 3,
    kSSBrushTypeScratch = 4,
    kSSBrushTypeAngled = 5
};

NS_ASSUME_NONNULL_BEGIN

@interface SSBrush : NSObject
+(SSBrush*)brushWithType:(SSBrushType)type;
@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, assign, readonly) SSBrushType type;
@property (nonatomic, strong, readonly) UIImage* image;
@end

NS_ASSUME_NONNULL_END
