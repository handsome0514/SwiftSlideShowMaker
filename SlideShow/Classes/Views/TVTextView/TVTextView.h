//
//  TextView.h
//  PanorameVideo
//
//  Created by Serg Shulga on 8/29/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "CustomTextView.h"

#define MIN_TEXTVIEW_SIZE   CGSizeMake(110, 90)
#define TEXT_OFFSET         20

@protocol TVTextViewDelegate;

@interface TVTextView: UIView

//thesun
@property (nonatomic, assign) CGFloat rotation;
@property (nonatomic, assign) CGFloat hSpacing;
@property (nonatomic, assign) CGFloat vSpacing;
@property (nonatomic, assign) CGFloat skew1;
@property (nonatomic, assign) CGFloat skew2;
@property (nonatomic, assign) CGRect rectImageColor;

@property (nonatomic, retain) UIImageView *foregroundMask;

- (void)updateAllTextAttribute;
- (CGFloat)getHSpacing;
- (CGFloat)getVSpacing;


@property (nonatomic, retain) CustomTextView *textView;

//! Text view delegate value
@property (nonatomic, assign) id<TVTextViewDelegate> delegate;

//! Text view active flag
@property (nonatomic, getter = isActive, setter = setActive:) BOOL active;

//! Text view proportional resize flag
@property (nonatomic, assign) BOOL proportionalResize;

// Render text properties
//

//! Text reflection
@property (nonatomic, assign) CGFloat reflection;

//! Typed text color
@property (nonatomic, strong) UIColor *textColor;

//! Typed text opacity
@property (nonatomic, assign) CGFloat textOpacity;

//! Typed text scale
@property (nonatomic, assign) CGPoint textScale;

//! Typed text size
@property (nonatomic, assign) CGSize textSize;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, assign) BOOL showBorder;

@property (nonatomic, assign) NSInteger timeLineId;
@property (nonatomic, assign) NSInteger fontIndex;
@property (nonatomic, assign) NSInteger colorIndex;

@property (nonatomic, assign) CGRect parentFrame;

@property (nonatomic, strong) NSString *uuid;

- (void)resizePinch:(UIPinchGestureRecognizer *)pinch;

- (void)setTextFontWithName:(NSString *)fontName;
- (UIFont *)textFont;

- (NSLineBreakMode)textLineBreakMode;

- (NSString *)getText;

- (void)showKeyboard;
- (void)dismissKeyboard;

- (UIEdgeInsets)textEdgesInsets;

// Drawning optimization methods
//
- (void)prepareForPrint;
- (void)prepareForDrawning;

- (CALayer *)layerWithImageRepresentationForSize:(CGSize)videoSize scale:(CGFloat)scale;

@property (nonatomic, assign) CGSize preservedSize;

//! Image color for text
@property (nonatomic, retain) UIImage *imageColorForText;

- (void)changeImageColorForText:(UIImage *)image;

@end


@protocol TVTextViewDelegate <NSObject>

- (BOOL)isEditMode1;

- (void)textViewWillBecomeEdit:(TVTextView *)textView;

- (BOOL)textViewWillBecomeActive:(TVTextView *)textView;

- (void)textViewDidChange:(TVTextView *)textView;

- (void)textViewRemovePressed:(TVTextView *)textView;

- (BOOL)textView:(TVTextView *)textView shouldChangeFrame:(CGRect)newFrame;

- (BOOL)textView:(TVTextView *)textView shouldChangeText:(NSString *)newText;

- (void)setRotate:(UIView*)focusView;
@end


