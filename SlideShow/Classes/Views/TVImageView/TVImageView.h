//
//  GraphicsEditView.h
//  Slideshow
//
//  Created by Serg Shulga on 8/29/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TVImageViewDelegate;

#define MIN_GRAPHICSVIEW_SIZE   CGSizeMake(72, 48)
#define IMAGE_OFFSET    10

@interface TVImageView : UIView

//! Text view delegate value
@property (nonatomic, assign) id<TVImageViewDelegate> delegate;

//! Text view active flag
@property (nonatomic, getter = isActive, setter = setActive:) BOOL active;

//! Text view proportional resize flag
@property (nonatomic, assign) BOOL proportionalResize;

// Render text properties
//
@property (nonatomic, assign) CGFloat rotation;

//! Text reflection
@property (nonatomic, assign) CGFloat reflection;

//! Typed text lightness
@property (nonatomic, assign) CGFloat textColorLightness;

//! Typed text opacity
@property (nonatomic, assign) CGFloat textOpacity;

////! Typed text scale
@property (nonatomic, assign) CGPoint textScale;

//! Typed text size
@property (nonatomic, assign) CGSize imageSize;

// TimeLine index
@property (nonatomic, assign) NSInteger timeLineId;

@property (nonatomic, strong) NSString *uuid;

+ (CGSize)frameSizeWithImage:(UIImage *)image maxSize:(CGSize)maxSize;

- (void) resizePinch: (UIPinchGestureRecognizer*) pinch;

- (NSLineBreakMode) textLineBreakMode;

- (UIImage*) getImage;
- (UIImage*) getOriginImage;

- (void)setImage:(UIImage*)image;
- (void)setOriginImage:(UIImage*)image;

- (CALayer *)layerWithImageRepresentationForSize:(CGSize)videoSize scale:(CGFloat)scale;

@property (nonatomic, assign) CGSize preservedSize;

@end


@protocol TVImageViewDelegate <NSObject>

- (BOOL)isEditMode;

- (BOOL)graphicsViewWillBecomeActive:(TVImageView*)imageView;

- (void)graphicsViewRemovePressed:(TVImageView*)imageView;

- (BOOL)graphicsView:(TVImageView*)imageView shouldChangeFrame:(CGRect)newFrame;

- (void)setRotate:(UIView*)focusView;
@end


