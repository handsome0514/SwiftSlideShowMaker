//
//  SSProjectScribbleItem.h
//  SlideShow
//
//  Created by Arda Ozupek on 10.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectItem.h"
#import <GPUImage/GPUImage.h>

@class SSBrush;

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectScribbleItem : SSProjectItem <NSCopying, NSCoding>
+(SSProjectScribbleItem*)scribble;
@property (nonatomic, strong, readonly) UIImageView* imageView;
@property (nonatomic, strong) SSBrush* brush;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign, getter=isErasing) BOOL erase;
@property (nonatomic, strong, readonly) NSArray<UIImage*>* undoStack;
@property (nonatomic, assign, readonly) NSInteger stackIndex;
-(void)undo;
-(void)redo;
-(void)clear;
-(void)handleTouchesBegan:(CGPoint)position;
-(void)handleTouchesMoved:(CGPoint)position;
-(void)handleTouchesEnded;
@end

NS_ASSUME_NONNULL_END
