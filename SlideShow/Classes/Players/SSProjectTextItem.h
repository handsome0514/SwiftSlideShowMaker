//
//  SSProjectTextItem.h
//  SlideShow
//
//  Created by Arda Ozupek on 4.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectItem.h"
#import <GPUImage/GPUImage.h>

extern const CGFloat SSProjectTextItemMaxStrokeWidth;

@class SSLabel;

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectTextItem : SSProjectItem <NSCopying, NSCoding>
+(SSProjectTextItem*)textWithTitle:(NSString*)title;
@property (nonatomic, strong, readonly) SSLabel* label;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) UIColor* titleColor;
@property (nonatomic, assign) BOOL stroke;
@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, assign) CGSize displaySize;
@property (nonatomic, assign) CGPoint displayCenter;
@property (nonatomic, assign) CGFloat displayRotation;

-(CGFloat)displayFontSize;
-(NSAttributedString*)attributedTextWithFontSize:(CGFloat)fontSize;
-(void)refreshLabel:(BOOL)changeSize;

-(SSLabel*)generateLabelToRenderAtSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
