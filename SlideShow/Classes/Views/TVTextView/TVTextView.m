//
//  TextView.m
//  PanorameVideo
//
//  Created by Serg Shulga on 8/29/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#import "TVTextView.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CATransform3D.h>
#import "CustomTextView.h"
#import "UIImage+Resize.h"

#import <CoreText/CoreText.h>
#import "UIView+Extension.h"

#define MAX_SCALE 7.0
#define MIN_SCALE 0.1

#define IS_IOS_7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)

#define REFLECTION_HEIHGT 0.5
#define CONTENT_VIEWS_SIDE 30.0

#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)

#define ACTIVE_BORDER_COLOR     [[UIColor whiteColor] CGColor]
#define INACTIVE_BORDER_COLOR   [[UIColor clearColor] CGColor]

#define MAX_FONT_SIZE           500
#define MIN_FONT_SIZE           16

CG_INLINE CATransform3D
CATransform3DMake(CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14,
                  CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24,
                  CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34,
                  CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44)
{
    CATransform3D t;
    t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
    t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
    t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
    t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
    return t;
}

#define CATransform3DPerspective(t, x, y) (CATransform3DConcat(t, CATransform3DMake(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1)))
#define CATransform3DMakePerspective(x, y) (CATransform3DPerspective(CATransform3DIdentity, x, y))

@interface TVTextView () <UITextViewDelegate>
{
    BOOL isDeleting;
}

@property (nonatomic, retain) UIImageView *rotationImageView;
@property (nonatomic, retain) UIImageView *resizeImageView;
@property (nonatomic, retain) UIImageView *removeImageView;

@property (nonatomic, retain) UITapGestureRecognizer *removeRecognaizer;
@property (nonatomic, retain) UIPanGestureRecognizer *rotateRecognaizer;
@property (nonatomic, retain) UIPanGestureRecognizer *resizeRecognaizer;

@property (nonatomic, retain) UIView *contentResize;
@property (nonatomic, retain) UIView *contentRemove;
@property (nonatomic, retain) UIView *contentRotate;

@property (nonatomic, retain) UIView *recognaizerView;

@property (nonatomic, retain) UIView *borderView;


// For rotating
//
@property (nonatomic, assign) CGFloat lastRotation;
@property (nonatomic, assign) CGPoint lastPoint;


//For resize
//
@property (nonatomic, assign) CGPoint firstCenter;
@property (nonatomic, assign) CGPoint firstPoint;
@property (nonatomic, assign) CGRect  firstFrame;
@property (nonatomic, retain) UIFont *firstFont;

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL afterCreation;


// White dots
//
@property (nonatomic, retain) UIView *leftDotButton;
@property (nonatomic, retain) UIView *topDotButton;
@property (nonatomic, retain) UIView *rightDotButton;
@property (nonatomic, retain) UIView *bottomDotButton;

@property (nonatomic, retain) UIView *leftBottomCornerLargeDot;

@property (nonatomic, retain) UIPanGestureRecognizer *topResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer *bottomResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer *leftResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer *rightResizeGestureRecognizer;

@property (nonatomic, retain) UIPanGestureRecognizer *leftBottomCornerResizeGestureRecognizer;

@end

@implementation TVTextView

@synthesize active = _active;

#pragma mark -
#pragma mark Initialization methods

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.preservedSize = CGSizeZero;
        self.backgroundColor = [UIColor clearColor];

        self.layer.shouldRasterize    = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                    action: @selector(activeView:)];
        singleTap.numberOfTapsRequired    = 1;
        [self addGestureRecognizer: singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                    action: @selector(doubleTapHandler:)];
        doubleTap.numberOfTapsRequired    = 2;
        [self addGestureRecognizer: doubleTap];
        
        
        
        // Create text view
        //
        self.textView                   = [CustomTextView new];
        self.textView.delegate          = self;
        self.textView.text              = @"";
        self.textView.backgroundColor   = [UIColor clearColor];
        self.textView.userInteractionEnabled = NO;
        
        CGFloat fontSize = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 40.0f : 60.0f;
        if (SYSTEM_VERSION_GREATER_THAN(@"5.1.1"))
            self.textView.font          = [UIFont fontWithName: @"BebasNeue" size: fontSize];  //default
        else
            self.textView.font          = [UIFont systemFontOfSize: fontSize];  //default
        _fontSize = fontSize;
        
        self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textView.editable          = YES;
        self.textView.scrollEnabled     = NO;
        self.textView.autoresizingMask  = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        [self.textView setReturnKeyType:UIReturnKeyDone];
        
        // Create rotation view
        //
        self.contentRotate                  = [UIView new];
        self.contentRotate.autoresizingMask = UIViewAutoresizingNone;
        self.contentRotate.backgroundColor  = [UIColor clearColor];
        
        self.rotateRecognaizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(rotate:)];
        [self.contentRotate addGestureRecognizer: self.rotateRecognaizer];
        
        self.rotationImageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"TextBoxRotate.png"]];
//        self.rotationImageView = [[UIImageView alloc] init];
        self.rotationImageView.autoresizingMask = UIViewAutoresizingNone;
        
        
        
        // Create resize image view
        //
        self.contentResize                  = [UIView new];
        self.contentResize.autoresizingMask = UIViewAutoresizingNone;
        self.contentResize.backgroundColor  = [UIColor clearColor];
        
        self.resizeRecognaizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(resize:)];
        [self.contentResize addGestureRecognizer: self.resizeRecognaizer];
        
        self.resizeImageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"TextBoxScale.png"]];
        self.resizeImageView.autoresizingMask       = UIViewAutoresizingNone;
        
        
        
        // Create remove image view
        //
        self.contentRemove                  = [UIView new];
        self.contentRemove.autoresizingMask = UIViewAutoresizingNone;
        self.contentRemove.backgroundColor  = [UIColor clearColor];
        
        self.removeRecognaizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(remove:)];
        [self.contentRemove addGestureRecognizer: self.removeRecognaizer];
        
        self.removeImageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"TextBoxClose.png"]];
        self.removeImageView.autoresizingMask       = UIViewAutoresizingNone;
        
        
        
        // Create dots
        //
        
        UIImage* smallDotImage = [UIImage imageNamed: @"TextBoxSmallDot.png"];
        UIImage* largeDotImage = [UIImage imageNamed: @"TextBoxLargeDot.png"];
        
        self.topResizeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                  action: @selector(resize:)];
        self.rightResizeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                    action: @selector(resize:)];
        self.bottomResizeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                     action: @selector(resize:)];
        self.leftResizeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                   action: @selector(resize:)];
        self.leftBottomCornerResizeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget: self
                                                                                               action: @selector(resize:)];
        
        
        self.leftDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TEXT_OFFSET * 2, TEXT_OFFSET * 2)];
        UIImageView* leftDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                              smallDotImage.size.width,
                                                                                              smallDotImage.size.height)];
        leftDotButtonImageView.image = smallDotImage;
        leftDotButtonImageView.center = CGPointMake(self.leftDotButton.frame.size.width / 2, self.leftDotButton.frame.size.height / 2);
        [self.leftDotButton addSubview: leftDotButtonImageView];
        [self.leftDotButton addGestureRecognizer: self.leftResizeGestureRecognizer];
        
        
        
        
        self.rightDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TEXT_OFFSET * 2, TEXT_OFFSET * 2)];
        UIImageView* rightDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                               smallDotImage.size.width,
                                                                                               smallDotImage.size.height)];
        rightDotButtonImageView.image = smallDotImage;
        rightDotButtonImageView.center = CGPointMake(self.rightDotButton.frame.size.width / 2, self.rightDotButton.frame.size.height / 2);
        [self.rightDotButton addSubview: rightDotButtonImageView];
        [self.rightDotButton addGestureRecognizer: self.rightResizeGestureRecognizer];
        
        
        
        
        self.topDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TEXT_OFFSET * 2, TEXT_OFFSET * 2)];
        UIImageView* topDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                             smallDotImage.size.width,
                                                                                             smallDotImage.size.height)];
        topDotButtonImageView.image = smallDotImage;
        topDotButtonImageView.center = CGPointMake(self.topDotButton.frame.size.width / 2, self.topDotButton.frame.size.height / 2);
        [self.topDotButton addSubview: topDotButtonImageView];
        [self.topDotButton addGestureRecognizer: self.topResizeGestureRecognizer];
        
        
        
        
        self.bottomDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TEXT_OFFSET * 2, TEXT_OFFSET * 2)];
        UIImageView* bottomDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                                smallDotImage.size.width ,
                                                                                                smallDotImage.size.height)];
        bottomDotButtonImageView.image = smallDotImage;
        bottomDotButtonImageView.center = CGPointMake(self.bottomDotButton.frame.size.width / 2, self.bottomDotButton.frame.size.height / 2);
        [self.bottomDotButton addSubview: bottomDotButtonImageView];
        [self.bottomDotButton addGestureRecognizer: self.bottomResizeGestureRecognizer];
        
        self.contentMode = UIViewContentModeRedraw;
        
        
        self.leftBottomCornerLargeDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TEXT_OFFSET * 2, TEXT_OFFSET * 2)];
        UIImageView* leftBottomCornerLargeDotImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                                         largeDotImage.size.width,
                                                                                                         largeDotImage.size.height)];
        leftBottomCornerLargeDotImageView.image = largeDotImage;
        leftBottomCornerLargeDotImageView.center = CGPointMake(self.leftBottomCornerLargeDot.frame.size.width / 2, self.leftBottomCornerLargeDot.frame.size.height / 2);
        [self.leftBottomCornerLargeDot addSubview: leftBottomCornerLargeDotImageView];
        [self.leftBottomCornerLargeDot addGestureRecognizer: self.leftBottomCornerResizeGestureRecognizer];
        
        
        self.borderView                   = [[UIView alloc] init];
        self.borderView.layer.borderWidth = 1.0f;
        self.borderView.layer.borderColor = ACTIVE_BORDER_COLOR;
        
        
        self.textScale = CGPointMake(1.f, 1.f);
        
        self.textColor               = [UIColor whiteColor];
        self.textOpacity             = 1;
        
        [self addSubview: self.borderView];
        [self addSubview: self.textView];
        
        [self addSubview: self.contentResize];
        [self addSubview: self.contentRotate];
        [self addSubview: self.contentRemove];
        
        [self addSubview: self.leftDotButton];
        [self addSubview: self.rightDotButton];
        [self addSubview: self.topDotButton];
        [self addSubview: self.bottomDotButton];
        [self addSubview: self.leftBottomCornerLargeDot];
        
        
        [self addSubview: self.rotationImageView];
        [self addSubview: self.resizeImageView];
        [self addSubview: self.removeImageView];
        //
        
        self.resizeImageView.frame = CGRectMake(0, 0, self.resizeImageView.image.size.width, self.resizeImageView.image.size.height);
        self.rotationImageView.frame = CGRectMake(0, 0, self.rotationImageView.image.size.width, self.rotationImageView.image.size.height);
        self.removeImageView.frame = CGRectMake(0, 0, self.removeImageView.image.size.width, self.removeImageView.image.size.height);
        
        
        self.foregroundMask = [[UIImageView alloc] initWithFrame:self.bounds];
        self.foregroundMask.userInteractionEnabled = YES;
        [self addSubview:self.foregroundMask];
        self.foregroundMask.alpha = 0.1;
        self.foregroundMask.hidden = YES;
        
        UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(moveForegroundMask:)];
        [pan setMinimumNumberOfTouches:1];
        [pan setMaximumNumberOfTouches:2];
        [self.foregroundMask addGestureRecognizer:pan];
        
        self.colorIndex = 7;
    }
    
    return self;
}

- (void)moveForegroundMask:(UIPanGestureRecognizer*)pan {
    
    static CGPoint previousPoint;
    
    CGPoint translatedPoint = [pan locationInView: self];
    CGRect imageRect = self.bounds;
    
    if(pan.state == UIGestureRecognizerStateBegan)
        previousPoint = translatedPoint;
    
    if(CGRectContainsPoint(imageRect, translatedPoint)) {
        float dX = translatedPoint.x - previousPoint.x;
        float dY = translatedPoint.y - previousPoint.y;
        
        previousPoint = translatedPoint;
        
        CGPoint textViewCenter = pan.view.center;
        textViewCenter.x += dX;//MIN(imageRect.size.width - pan.view.frame.size.width / 2, translatedPoint.x);
        textViewCenter.y += dY;// MIN(imageRect.size.height - pan.view.frame.size.height / 2, translatedPoint.y);
        
        pan.view.center = textViewCenter;
        
        
//        NSLog(@"%f, %f, %f, %f", pan.view.left, pan.view.top, pan.view.right, self.right);
        
        if (pan.view.left > 0)
            pan.view.left = 0;
        if (pan.view.top > 0)
            pan.view.top = 0;
        if (pan.view.bottom < self.height)
            pan.view.bottom = self.height;
        if (pan.view.right < self.width )
            pan.view.right = self.width;

        self.rectImageColor = CGRectMake(fabs(pan.view.left), fabs(pan.view.top), self.width, self.height);
        
        [self changeImageColorForText];
        
//        self.rectImageColor.
    }
}

- (void)dealloc
{
    self.textView           = nil;
    self.rotationImageView  = nil;
    self.resizeImageView    = nil;
    self.removeImageView    = nil;
    self.firstFont          = nil;
    
    self.removeRecognaizer  = nil;
    self.rotateRecognaizer  = nil;
    self.resizeRecognaizer  = nil;
    
    self.contentRemove      = nil;
    self.contentResize      = nil;
    self.contentRotate      = nil;
}

- (void)layoutSubviews
{
#if 0
    //org
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
    [super layoutSubviews];
    
    self.textView.transform = CGAffineTransformIdentity;
    
    self.borderView.frame  = CGRectMake(TEXT_OFFSET, TEXT_OFFSET,
                                        ceilf(self.frame.size.width - TEXT_OFFSET * 2),
                                        ceilf(self.frame.size.height - TEXT_OFFSET * 2));
    
    if([self.textView.text isEqualToString:@""])
        self.textView.frame = self.borderView.frame;
    else
        self.textView.frame = CGRectMake(0, 0, self.textSize.width, self.textSize.height);
    
    self.textView.center = CGPointMake(self.frame.size.width / 2,
                                       self.frame.size.height / 2);
    
    self.textView.transform = CGAffineTransformMakeScale(self.textScale.x,
                                                         self.textScale.y);
    CGPoint origin = self.borderView.frame.origin;
    CGSize  size   = self.borderView.frame.size;
    
    self.resizeImageView.center = CGPointMake(CGRectGetMaxX(self.borderView.frame), CGRectGetMaxY(self.borderView.frame));
    self.rotationImageView.center = CGPointMake(CGRectGetMaxX(self.borderView.frame), origin.y);
    self.removeImageView.center = CGPointMake(origin.x, origin.y);
    
    float contentViewsSide = CONTENT_VIEWS_SIDE + 10;
    
    self.contentRemove.frame = CGRectMake(0, 0, contentViewsSide, contentViewsSide);
    self.contentResize.frame = CGRectMake(self.frame.size.width - contentViewsSide,
                                          self.frame.size.height - contentViewsSide, contentViewsSide, contentViewsSide);
    self.contentRotate.frame = CGRectMake(self.frame.size.width - contentViewsSide, 0, contentViewsSide, contentViewsSide);
    
    [self.textView update];
    
    self.transform = transform;
#else
    
#ifdef TRANSFORM_2D
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
#else
    CATransform3D transform3D = self.layer.transform;
    self.layer.transform = CATransform3DIdentity;
#endif
    
    [super layoutSubviews];
    
    self.textView.transform = CGAffineTransformIdentity;
    
    self.borderView.frame  = CGRectMake(TEXT_OFFSET, TEXT_OFFSET,
                                        ceilf(self.frame.size.width - TEXT_OFFSET * 2),
                                        ceilf(self.frame.size.height - TEXT_OFFSET * 2));
    
    //    if([self.textView.text isEqualToString:@""])
    self.textView.frame = self.borderView.frame;
    //    else
    //        self.textView.frame = CGRectMake(0, 0, self.textSize.width, self.textSize.height);
    
    self.textView.center = CGPointMake(self.frame.size.width / 2,
                                       self.frame.size.height / 2);
    
//    self.textView.transform = CGAffineTransformMakeScale(self.textScale.x,
//                                                         self.textScale.y);
    
    
    
    CGPoint origin = self.borderView.frame.origin;
    CGSize  size   = self.borderView.frame.size;
    
    self.leftDotButton.center   = CGPointMake(origin.x, origin.y + size.height / 2);
    self.rightDotButton.center  = CGPointMake(size.width + origin.x, origin.y + size.height / 2);
    self.topDotButton.center    = CGPointMake(origin.x + size.width / 2, origin.y);
    self.bottomDotButton.center = CGPointMake(origin.x + size.width / 2, origin.y + size.height);
    self.leftBottomCornerLargeDot.center = CGPointMake(origin.x, origin.y + size.height);
    
    
    self.resizeImageView.center = CGPointMake(CGRectGetMaxX(self.borderView.frame), CGRectGetMaxY(self.borderView.frame));
    self.rotationImageView.center = CGPointMake(CGRectGetMaxX(self.borderView.frame), origin.y);
    self.removeImageView.center = CGPointMake(origin.x, origin.y);
    
    float contentViewsSide = CONTENT_VIEWS_SIDE + 10;
    
    self.contentRemove.frame = CGRectMake(0, 0, contentViewsSide, contentViewsSide);
    self.contentResize.frame = CGRectMake(self.frame.size.width - contentViewsSide,
                                          self.frame.size.height - contentViewsSide, contentViewsSide, contentViewsSide);
    self.contentRotate.frame = CGRectMake(self.frame.size.width - contentViewsSide, 0, contentViewsSide, contentViewsSide);
    
    [self.textView update];
    
    
#ifdef TRANSFORM_2D
    self.transform = transform;
#else
    self.layer.transform = transform3D;
#endif
    
    
#ifndef TRANSFORM_2D
    
    
    
    self.layer.minificationFilter = kCAFilterNearest;
    
    CGFloat angle = atan2(transform3D.m12, transform3D.m11);
    transform3D = CATransform3DMakePerspective(self.skew1/100.0, self.skew2/100.0);
    transform3D = CATransform3DRotate (transform3D, angle, 0, 0 , 1);
    transform3D = CATransform3DScale(transform3D, self.textScale.x, self.textScale.y , 1);
    
    self.layer.transform = transform3D;
#endif
    
    
#endif

}

#pragma mark -
#pragma mark UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewWillBecomeEdit:)]) {
        [self.delegate textViewWillBecomeEdit:self];
    }
    
    self.isEditing = YES;
    
    [self setNeedsLayout];
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    textView.text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeText:)])
        [self.delegate textView:self shouldChangeText:textView.text];

    self.isEditing = NO;
  
    [self setNeedsLayout];
    
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    self.textView.transform = CGAffineTransformIdentity;

    isDeleting = (range.length >= 1 && text.length == 0);
    BOOL shouldChangeText = NO;
    NSString *newText = [self.textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeText:)])
        shouldChangeText = [self.delegate textView:self shouldChangeText:newText];
    
    return shouldChangeText;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (isDeleting)
    {
        [self performSelector:@selector(adjustTextViewFonts:) withObject:@YES];
    }
    else
    {
        [self performSelector:@selector(adjustTextViewFonts:) withObject:@NO];
    }
    
    [self.textView update];
    
    [self setNeedsDisplay];
}


#pragma mark -
#pragma mark Getters

- (BOOL) isActive
{
    return _active;
}

- (UIColor*)getTextColor
{
    return self.textView.textColor;
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    
    BOOL shouldChange = YES;
    UIFont* font = self.textView.font;
    
    self.textView.transform = CGAffineTransformIdentity;
    
    self.textView.font = [UIFont fontWithName: font.fontName
                                         size: fontSize];
    
    [self updateAllTextAttribute];
    
    if(self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeText:)])
    {
        shouldChange = [self.delegate textView: self shouldChangeText: self.textView.text];
    }
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

- (void)setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder;
    
    self.removeImageView.hidden = !showBorder;
    self.resizeImageView.hidden = !showBorder;
    self.rotationImageView.hidden = !showBorder;
    self.borderView.hidden = !showBorder;
}

#pragma mark -
#pragma mark Setters

- (void)setTextSize:(CGSize)textSize
{
    _textSize = textSize;
    
    CGRect frame = self.frame;
    
    frame.size.width = _textSize.width * self.textScale.x + TEXT_OFFSET * 2;
    frame.size.height = _textSize.height * self.textScale.y + TEXT_OFFSET * 2;
    
    self.frame = frame;
    
    [self setNeedsLayout];
}

- (void)setProportionalResize:(BOOL)proportionalResize
{
    _proportionalResize = proportionalResize;
    
    if(proportionalResize)
        self.textScale = CGPointMake(1.0, 1.0);
    
    [self updateResizing];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeText:)])
      [self.delegate textView: self
             shouldChangeText: self.textView.text];
}

- (void)setActive:(BOOL)active
{
    _active = active;
    
    if (active)
    {
        if (!self.textView.editable)
            [self.textView resignFirstResponder];
        
        self.textView.editable = YES;
        
        self.rotationImageView.hidden   = NO;
        self.removeImageView.hidden     = NO;
        
        self.rotateRecognaizer.enabled  = YES;
        self.removeRecognaizer.enabled  = YES;
        
        self.borderView.layer.borderColor = ACTIVE_BORDER_COLOR;
        
        if (self.delegate && [self.delegate respondsToSelector: @selector(textViewWillBecomeActive:)])
            [self.delegate textViewWillBecomeActive: self];
        
        self.textView.userInteractionEnabled = active;
    }
    else
    {
        self.textView.editable = NO;
        
        [self.textView resignFirstResponder];
        
        self.rotationImageView.hidden   = YES;
        self.removeImageView.hidden     = YES;
        
        self.rotateRecognaizer.enabled  = NO;
        self.removeRecognaizer.enabled  = NO;
        
        self.borderView.layer.borderColor = INACTIVE_BORDER_COLOR;
        
        self.foregroundMask.hidden = YES;
        
        self.textView.userInteractionEnabled = active;
    }
    
    [self updateResizing];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    
    self.textView.textColor = textColor;
}

- (void)setTextOpacity:(CGFloat) textOpacity
{
    _textOpacity = textOpacity;
    
    self.textView.alpha = _textOpacity;
}

- (void)setTextFontWithName:(NSString*)fontName
{
    self.textView.font = [UIFont fontWithName: fontName
                                         size: self.textView.font.pointSize];
    
    [self.textView update];

    
    [self updateAllTextAttribute];
    
    if(self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeText:)])
        [self.delegate textView: self
               shouldChangeText: self.textView.text];
    
    
}

- (UIFont*)textFont
{
    return self.textView.font;
}

- (NSLineBreakMode) textLineBreakMode
{
    return NSLineBreakByWordWrapping;
}

- (NSString*)getText
{
    return self.textView.text;
}

- (void)setReflection:(CGFloat) refl
{
    _reflection = refl;
    self.textView.reflectionScale = _reflection;
    [self.textView update];
    
    CGSize size = self.size;
    if (self.textView.reflectionScale > 0) {
        size.height = self.textView.reflectionView.y + self.textView.reflectionView.height;
        self.layer.anchorPoint = CGPointMake(0.5, MAX (0.5 + (size.height - self.height)/(self.height*2), 1.0) );
    }
    else
        self.layer.anchorPoint = CGPointMake(0.5, 0.5);
    
    
}

- (void)setTextScale:(CGPoint)textScale
{
    _textScale = textScale;
    [self.textView update];
}

#pragma mark -
#pragma mark Gesture Recognizers Handling

- (void)activeView:(UITapGestureRecognizer*)tap
{
    if (![self.delegate isEditMode1]) {
        return;
    }
    if (self.foregroundMask.hidden == NO)
        return;
    
    if (self.active == YES) {
        [self.textView becomeFirstResponder];
    } else {
        if (self.delegate && [self.delegate respondsToSelector: @selector(textViewWillBecomeActive:)]) {
            if ([self.delegate textViewWillBecomeActive: self]) {
                [self setActive: YES];
            }
        } else {
            [self setActive: YES];
        }
    }
}

- (void)editView:(UITapGestureRecognizer*)tap
{
    if (self.foregroundMask.hidden == NO)
        return;
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(textViewWillBecomeEdit:)])
        [self.delegate textViewWillBecomeEdit: self];
    
    [self setActive: YES];
}

- (void)rotate:(UIPanGestureRecognizer*)pan
{
    if (self.isEditing)
        return;
    
    [self.textView resignFirstResponder];
    
    if (pan.state == UIGestureRecognizerStateEnded)
    {
        self.lastRotation = 0.0;
        return;
    }
    
    if (pan.state == UIGestureRecognizerStateBegan)
        self.lastPoint = [pan locationInView: self.superview];
    
    CGFloat newRotation = [self getRotationTo: [pan locationInView: self.superview]];
    CGFloat rotation = (self.lastRotation - newRotation);
    
#ifdef TRANSFORM_2D
    CGAffineTransform currentTransform = self.transform;
    CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
    
    [self setTransform: newTransform];
#else
    CATransform3D transform3D = self.layer.transform;
    self.layer.transform = CATransform3DRotate (transform3D, rotation, 0, 0 , 1);
#endif
    
    self.rotation = self.rotation + rotation;
    
    [self.delegate setRotate:self];
    
    if(self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeFrame:)])
    {
        if(![self.delegate textView: self
                  shouldChangeFrame: self.frame])
        {
#ifdef TRANSFORM_2D
            [self setTransform: currentTransform];
#else
            self.layer.transform = transform3D;
#endif
            pan.enabled = NO;
            pan.enabled = YES;
            
            self.lastRotation = 0.0;
            return;
        }
        else
        {
            self.lastRotation = newRotation;
        }
    }
    
}

- (void)resize:(UIPanGestureRecognizer*)pan
{
    if (self.isEditing)
        return;
    
    [self.textView resignFirstResponder];
    [self.textView setNeedsDisplay];
    
    // static CGRect beginTextViewFrame;
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        self.firstPoint = [pan translationInView: nil];
#ifdef TRANSFORM_2D
        CGAffineTransform transform = self.transform;
        self.transform = CGAffineTransformIdentity;
        self.firstFrame = self.frame;
        self.transform = transform;
        self.firstFont  = self.textView.font;
#else
        CATransform3D transform3D = self.layer.transform;
        self.layer.transform = CATransform3DIdentity;
        self.firstFrame = self.frame;
        self.layer.transform = transform3D;
        self.firstFont  = self.textView.font;
#endif
    }
    
    CGFloat deltaX = ceilf([pan translationInView: self].x - self.firstPoint.x);
    CGFloat deltaY = ceilf([pan translationInView: self].y - self.firstPoint.y);
    
    CGFloat newWidth = 0;
    CGFloat newHeight = 0;
    CGFloat newX = 0;
    CGFloat newY = 0;
    
    if(pan == self.resizeRecognaizer) {
        newWidth = deltaX;
        newHeight = deltaY;
    }
    else
        if(pan == self.bottomResizeGestureRecognizer)
            newHeight = deltaY;
        else
            if(pan == self.leftResizeGestureRecognizer) {
                newX = deltaX;
                newWidth = -deltaX;
            }
            else
                if(pan == self.leftBottomCornerResizeGestureRecognizer) {
                    newX = deltaX;
                    newWidth = -deltaX;
                    newHeight = deltaY;
                }
                else
                    if(pan == self.topResizeGestureRecognizer) {
                        newY = deltaY;
                        newHeight = -deltaY;
                    }
                    else
                        if(pan == self.rightResizeGestureRecognizer)
                            newWidth = deltaX;
    
    if (MIN_TEXTVIEW_SIZE.height < ceilf(self.firstFrame.size.height + newHeight) && MIN_TEXTVIEW_SIZE.width < ceilf(self.firstFrame.size.width + newWidth))
    {
        CGRect newFrame = CGRectMake(ceilf(self.firstFrame.origin.x + newX),
                                     ceilf(self.firstFrame.origin.y + newY),
                                     ceilf(self.firstFrame.size.width + newWidth),
                                     ceilf(self.firstFrame.size.height + newHeight));
        
        CGFloat xScale = (newFrame.size.width - TEXT_OFFSET * 2) / self.textSize.width;
        CGFloat yScale = (newFrame.size.height - TEXT_OFFSET * 2) / self.textSize.height;
        
        if(xScale > MAX_SCALE || xScale < MIN_SCALE)
            return;
        
        if (yScale > MAX_SCALE || yScale < MIN_SCALE)
            return;
        
        if (self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeFrame:)]) {
            if ([self.delegate textView:self shouldChangeFrame:newFrame]) {
                self.frame = newFrame;
                
                if (deltaX > 0.f && deltaY > 0.f)
                {
                    [self performSelector:@selector(adjustTextViewFonts:) withObject:@YES];
                }
                else
                {
                    [self performSelector:@selector(adjustTextViewFonts:) withObject:@NO];
                }
            }
        }
    }
}

- (void)resizePinch:(UIPinchGestureRecognizer*)pinch
{
    if(self.proportionalResize)
        return;
    
#ifdef TRANSFORM_2D
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
#else
    CATransform3D transform3D = self.layer.transform;
    self.layer.transform = CATransform3DIdentity;
    
#endif
    
    
    if (pinch.state == UIGestureRecognizerStateBegan)
    {
        self.firstCenter = self.center;
        self.firstFrame  = self.frame;
        self.firstFont   = self.textView.font;
    }
    
    CGSize newSize = CGSizeMake(self.firstFrame.size.width * pinch.scale, self.firstFrame.size.height * pinch.scale);
    
    CGFloat deltaX = (NSInteger)newSize.width - (NSInteger)self.firstFrame.size.width;
    CGFloat deltaY = (NSInteger)newSize.height - (NSInteger)self.firstFrame.size.height;
    
    
    
    if (MIN_TEXTVIEW_SIZE.height < ceilf(self.firstFrame.size.height + deltaY) && MIN_TEXTVIEW_SIZE.width < ceilf(self.firstFrame.size.width + deltaX))
    {
        CGRect newFrame = CGRectMake(ceilf(self.firstFrame.origin.x - deltaX / 2),
                                     ceilf(self.firstFrame.origin.y - deltaY / 2),
                                     ceilf(self.firstFrame.size.width + deltaX),
                                     ceilf(self.firstFrame.size.height + deltaY));
        
        CGFloat xScale = (newFrame.size.width - TEXT_OFFSET * 2) / self.textSize.width;
        CGFloat yScale = (newFrame.size.height - TEXT_OFFSET * 2) / self.textSize.height;
        
        if(xScale > MAX_SCALE || xScale < MIN_SCALE)
            return;
        
        if (yScale > MAX_SCALE || yScale < MIN_SCALE)
            return;
        
        if(self.delegate && [self.delegate respondsToSelector: @selector(textView:shouldChangeFrame:)])
            if([self.delegate textView: self
                     shouldChangeFrame: newFrame])
            {
                
                self.frame = newFrame;
                
                
                self.textScale = CGPointMake(xScale, yScale);
            }
    }
    
#ifdef TRANSFORM_2D
    self.transform = transform;
#else
    self.layer.transform = transform3D;
#endif
}

- (void)remove:(UITapGestureRecognizer*)tap
{
    if (self.isEditing)
        return;
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(textViewRemovePressed:)])
        [self.delegate textViewRemovePressed: self];
}

- (void)doubleTapHandler:(UITapGestureRecognizer*)tap
{
    if (![self.delegate isEditMode1]) {
        return;
    }
    if (self.foregroundMask.hidden == NO)
        return;
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(textViewWillBecomeEdit:)])
        [self.delegate textViewWillBecomeEdit: self];
    
    [self setActive: YES];
}

- (void)updateResizing
{
    BOOL available = self.active && !self.proportionalResize;
    
    self.resizeImageView.hidden          = !available;
    self.leftDotButton.hidden            = !available;
    self.topDotButton.hidden             = !available;
    self.rightDotButton.hidden           = !available;
    self.bottomDotButton.hidden          = !available;
    self.leftBottomCornerLargeDot.hidden = !available;
    
    //available = NO;
    
    self.resizeRecognaizer.enabled                       = available;
    self.topResizeGestureRecognizer.enabled              = available;
    self.bottomResizeGestureRecognizer.enabled           = available;
    self.leftResizeGestureRecognizer.enabled             = available;
    self.rightResizeGestureRecognizer.enabled            = available;
    self.leftBottomCornerResizeGestureRecognizer.enabled = available;
}




#pragma mark -
#pragma mark Rotate calculations

- (CGFloat) pointPairToBearing:(CGPoint) startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    
    return bearingRadians;
}

- (CGFloat) getRotationTo:(CGPoint) toPoint
{
    CGFloat rotation = [self pointPairToBearing: self.center secondPoint: self.lastPoint] - [self pointPairToBearing: self.center secondPoint: toPoint];
    
    return rotation;
}

#pragma mark -
#pragma mark Public methods

- (void)showKeyboard
{
    [self.textView becomeFirstResponder];
}
- (void)dismissKeyboard
{
    [self.textView resignFirstResponder];
}

#pragma mark -
#pragma mark Private methods

- (UIEdgeInsets) textEdgesInsets {
    return UIEdgeInsetsMake(8, 8, 8, 8);
}

#pragma mark -
#pragma mark Drawning optimization methods

- (void)prepareForPrint
{
    self.textView.dynamic = NO;
}

- (void)prepareForDrawning
{
    self.textView.dynamic = NO;
}

- (void)prepareRenderView
{
    [self.rotationImageView removeFromSuperview];
    [self.removeImageView removeFromSuperview];
    
    [self.borderView removeFromSuperview];
}

- (void)endRenderView
{
    [self addSubview:self.borderView];
    
    [self addSubview:self.rotationImageView];
    [self addSubview:self.removeImageView];
}

- (CALayer *)layerWithImageRepresentationForSize:(CGSize)videoSize scale:(CGFloat)scale
{
    UIView* imageView = self.superview;
    for (UIView *view in imageView.subviews)
        view.hidden = YES;
    self.hidden = NO;
    
    BOOL isActive = self.active;
    self.active = NO;
    [self prepareRenderView];
    [imageView setNeedsDisplay];
    
    usleep(100000);
    
    UIImage *renderImage = nil;
    UIGraphicsBeginImageContextWithOptions(imageView.frame.size, NO, 0.0);
    //[imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    [imageView drawViewHierarchyInRect:imageView.bounds afterScreenUpdates:YES];
    renderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self endRenderView];
    self.active = isActive;
    for (UIView *view in imageView.subviews) {
        view.hidden = NO;
    }
    
    renderImage = [renderImage resizedImageToSize:videoSize];
    
    // paste to CALayer
    CALayer* aLayer = [CALayer layer];
    CGRect startFrame = CGRectMake(0.0, 0.0, videoSize.width, videoSize.height);
    aLayer.contents = (id)renderImage.CGImage;
    aLayer.frame = startFrame;
    
    return aLayer;
}

- (CGRect)rectForMainSize:(CGSize)mainSize video:(CGSize)videoSize
{
    CGRect imageViewFrame;
    
    CGFloat scrollViewWidth = mainSize.width;
    CGFloat scrollViewHeight = mainSize.height;
    
    CGFloat imageScale = fmaxf(videoSize.width / scrollViewWidth, videoSize.height / scrollViewHeight);
    
    CGSize scaledImageSize = CGSizeMake(videoSize.width/imageScale, videoSize.height/imageScale);
    imageViewFrame = CGRectMake((int)(0.5f * (scrollViewWidth - scaledImageSize.width)),
                                (int)(0.5f * (scrollViewHeight - scaledImageSize.height)),
                                (int)(scaledImageSize.width),
                                (int)(scaledImageSize.height));
    
    return imageViewFrame;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)rotateImage:(UIImage*)src byRadian:(CGFloat)radian
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, src.size.width, src.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radian);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    // Create the bitmap context

    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, [UIScreen mainScreen].scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    //   // Rotate the image context
    CGContextRotateCTM(bitmap, radian);

    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-src.size.width / 2, -src.size.height / 2, src.size.width, src.size.height), [src CGImage]);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGFloat) xscaleForTransform:(CGAffineTransform)t
{
    return sqrt(t.a * t.a + t.c * t.c);
}

- (CGFloat) yscaleForTransform:(CGAffineTransform)t
{
    return sqrt(t.b * t.b + t.d * t.d);
}

- (void)changeImageColorForText
{
    if (self.imageColorForText)
    {
        UIImage * cropedImage = [self.imageColorForText crop:self.rectImageColor];
        self.textView.textColor = [UIColor colorWithPatternImage:cropedImage];
        //    self.layer.contents = (id)cropedImage.CGImage;
    }
    [self.textView update];
    
}

- (void)changeImageColorForText:(UIImage *)image
{
    self.imageColorForText = image;
    [self changeImageColorForText];
}

- (void)updateAllTextAttribute
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = [self getVSpacing];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString : self.getText
                                    attributes : @{
                   NSParagraphStyleAttributeName : paragraphStyle,
                   NSKernAttributeName : [NSNumber numberWithFloat: [self getHSpacing]],
                   NSFontAttributeName : self.textFont,
                   NSForegroundColorAttributeName : [self getTextColor]
                   //NSShadowAttributeName : shadow
                   }];
    self.textView.attributedText = attributedString;
    
}

- (CGFloat) getRotation
{
    return self.rotation;
}
- (CGFloat) getHSpacing
{
    return self.hSpacing * self.textFont.pointSize/10;
}
- (CGFloat) getVSpacing
{
    return self.vSpacing * self.textFont.pointSize/10;
}

#pragma mark - Resize Functions

- (BOOL)isBeyondSize:(CGSize)size
{
    if (IS_IOS_7)
    {
        CGFloat ost = _textView.textContainerInset.top + _textView.textContainerInset.bottom;
        
        return size.height + ost > self.textView.frame.size.height;
    }
    else
    {
        return self.textView.contentSize.height > self.textView.frame.size.height;
    }
}

- (BOOL)isBeyondSize:(CGSize)size textView:(UITextView *)textView scale:(CGFloat)scale
{
    if (IS_IOS_7)
    {
        CGFloat ost = textView.textContainerInset.top + textView.textContainerInset.bottom;
        
        return size.height + ost > self.textView.frame.size.height * scale;
    }
    else
    {
        return textView.contentSize.height > textView.frame.size.height * scale;
    }
}

- (CGSize)textSizeWithFont:(CGFloat)font text:(NSString *)string
{
    NSString *text = string ? string : self.textView.text;
    
    CGFloat pO = self.textView.textContainer.lineFragmentPadding * 2;
    CGFloat cW = self.textView.frame.size.width - pO;
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(cW, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [self.textFont fontWithSize:font]} context:nil];
    CGSize tH = rect.size;
    return  tH;
}

- (CGSize)textSizeWithFont:(CGFloat)font text:(NSString *)string scale:(CGFloat)scale
{
    NSString *text = string ? string : self.textView.text;
    
    CGFloat pO = self.textView.textContainer.lineFragmentPadding * 2;
    CGFloat cW = (self.textView.frame.size.width - pO) * scale;
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake(cW, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [self.textFont fontWithSize:font]} context:nil];
    CGSize tH = rect.size;
    return  tH;
}

- (CGFloat)fontScaledSize:(CGFloat)scale WithTextView:(UITextView *)textView
{
    CGFloat cFont = textView.font.pointSize;
    CGSize  tSize = IS_IOS_7 ? [self textSizeWithFont:cFont text:nil scale:scale] : CGSizeZero;
    do
    {
        if (IS_IOS_7)
        {
            tSize = [self textSizeWithFont:++cFont text:nil scale:scale];
        }
        else
        {
            [self.textView setFont:[self.textFont fontWithSize:++cFont]];
        }
    }
    while (![self isBeyondSize:tSize textView:textView scale:scale] && cFont < MAX_FONT_SIZE);
    
    cFont = (cFont < MAX_FONT_SIZE) ? cFont : MIN_FONT_SIZE;
    return cFont - 1;
}

- (void)adjustTextViewFonts:(NSNumber *)isPlus
{
    CGFloat cFont = self.textView.font.pointSize;
    CGSize  tSize = IS_IOS_7 ? [self textSizeWithFont:cFont text:nil] : CGSizeZero;
    if ([isPlus boolValue])
    {
        do
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:++cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.textFont fontWithSize:++cFont]];
            }
        }
        while (![self isBeyondSize:tSize] && cFont < MAX_FONT_SIZE);
        
        cFont = (cFont < MAX_FONT_SIZE) ? cFont : MIN_FONT_SIZE;
        self.fontSize = --cFont;
        //[self.textView setFont:[self.textFont fontWithSize:--cFont]];
    }
    else
    {
        while ([self isBeyondSize:tSize] && cFont > 0)
        {
            if (IS_IOS_7)
            {
                tSize = [self textSizeWithFont:--cFont text:nil];
            }
            else
            {
                [self.textView setFont:[self.textFont fontWithSize:--cFont]];
            }
        }
        
        self.fontSize = cFont;
        //[self.textView setFont:[self.textFont fontWithSize:cFont]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:self];
    }
}

@end
