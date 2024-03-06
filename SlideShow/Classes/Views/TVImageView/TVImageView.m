//
//  TextView.m
//  PanorameVideo
//
//  Created by Serg Shulga on 8/29/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIImage+Resize.h"
#import "TVImageView.h"
#import <CoreText/CoreText.h>

#define MAX_SCALE 7.0
#define MIN_SCALE 0.1

#define REFLECTION_HEIHGT 0.5
#define CONTENT_VIEWS_SIDE 30.0
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)

#define ACTIVE_BORDER_COLOR     [[UIColor whiteColor] CGColor]
#define INACTIVE_BORDER_COLOR   [[UIColor clearColor] CGColor]

@interface TVImageView () <UITextViewDelegate>

@property (nonatomic, retain) UIImageView* rotationImageView;
@property (nonatomic, retain) UIImageView* resizeImageView;
@property (nonatomic, retain) UIImageView* removeImageView;
@property (nonatomic, retain) UIImageView *mainImageView;

@property (nonatomic, retain) UITapGestureRecognizer* removeRecognaizer;
@property (nonatomic, retain) UIPanGestureRecognizer* rotateRecognaizer;
@property (nonatomic, retain) UIPanGestureRecognizer* resizeRecognaizer;

@property (nonatomic, retain) UIView* contentResize;
@property (nonatomic, retain) UIView* contentRemove;
@property (nonatomic, retain) UIView* contentRotate;

@property (nonatomic, retain) UIView* recognaizerView;

@property (nonatomic, retain) UIView* borderView;


// For rotating
//
@property (nonatomic, assign) CGFloat lastRotation;
@property (nonatomic, assign) CGPoint lastPoint;


//For resize
//
@property (nonatomic, assign) CGPoint firstCenter;
@property (nonatomic, assign) CGPoint firstPoint;
@property (nonatomic, assign) CGRect  firstFrame;
@property (nonatomic, retain) UIFont* firstFont;

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL afterCreation;


// White dots
//
@property (nonatomic, retain) UIView* leftDotButton;
@property (nonatomic, retain) UIView* topDotButton;
@property (nonatomic, retain) UIView* rightDotButton;
@property (nonatomic, retain) UIView* bottomDotButton;

@property (nonatomic, retain) UIView* leftBottomCornerLargeDot;

@property (nonatomic, retain) UIPanGestureRecognizer* topResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer* bottomResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer* leftResizeGestureRecognizer;
@property (nonatomic, retain) UIPanGestureRecognizer* rightResizeGestureRecognizer;

@property (nonatomic, retain) UIPanGestureRecognizer* leftBottomCornerResizeGestureRecognizer;

@property (nonatomic, retain) UIImage *originImage;

@end

@implementation TVImageView

+ (CGSize)frameSizeWithImage:(UIImage *)image maxSize:(CGSize)maxSize
{
    CGSize imageSize = image.size;
    CGFloat imageScale = fmaxf(imageSize.width / maxSize.width, imageSize.height / maxSize.height);
    CGSize scaledImageSize = CGSizeMake(imageSize.width / imageScale, imageSize.height / imageScale);
    return scaledImageSize;
}

@synthesize active = _active;

#pragma mark -
#pragma mark Initialization methods

- (id) init
{
    self = [super init];
    
    if (self)
    {
        self.proportionalResize = NO;
        
        self.preservedSize = CGSizeZero;
        self.backgroundColor = [UIColor clearColor];

        self.layer.shouldRasterize    = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        
        UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(activeView:)];
        singleTap.numberOfTapsRequired    = 1;
        [self addGestureRecognizer: singleTap];
        
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                    action: @selector(doubleTapHandler:)];
        doubleTap.numberOfTapsRequired    = 2;
        [self addGestureRecognizer: doubleTap];
        
        // Create rotation view
        //
        self.contentRotate                  = [UIView new];
        self.contentRotate.autoresizingMask = UIViewAutoresizingNone;
        self.contentRotate.backgroundColor  = [UIColor clearColor];
        
        self.rotateRecognaizer = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(rotate:)];
        [self.contentRotate addGestureRecognizer: self.rotateRecognaizer];
        
        self.rotationImageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"TextBoxRotate.png"]];
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
        
        
        self.leftDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_OFFSET * 2, IMAGE_OFFSET * 2)];
        UIImageView* leftDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                              smallDotImage.size.width,
                                                                                              smallDotImage.size.height)];
        leftDotButtonImageView.image = smallDotImage;
        leftDotButtonImageView.center = CGPointMake(self.leftDotButton.frame.size.width / 2, self.leftDotButton.frame.size.height / 2);
        [self.leftDotButton addSubview: leftDotButtonImageView];
        [self.leftDotButton addGestureRecognizer: self.leftResizeGestureRecognizer];
        
        
        
        
        self.rightDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_OFFSET * 2, IMAGE_OFFSET * 2)];
        UIImageView* rightDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                               smallDotImage.size.width,
                                                                                               smallDotImage.size.height)];
        rightDotButtonImageView.image = smallDotImage;
        rightDotButtonImageView.center = CGPointMake(self.rightDotButton.frame.size.width / 2, self.rightDotButton.frame.size.height / 2);
        [self.rightDotButton addSubview: rightDotButtonImageView];
        [self.rightDotButton addGestureRecognizer: self.rightResizeGestureRecognizer];
        
        
        
        
        self.topDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_OFFSET * 2, IMAGE_OFFSET * 2)];
        UIImageView* topDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                             smallDotImage.size.width,
                                                                                             smallDotImage.size.height)];
        topDotButtonImageView.image = smallDotImage;
        topDotButtonImageView.center = CGPointMake(self.topDotButton.frame.size.width / 2, self.topDotButton.frame.size.height / 2);
        [self.topDotButton addSubview: topDotButtonImageView];
        [self.topDotButton addGestureRecognizer: self.topResizeGestureRecognizer];
        
        
        
        
        self.bottomDotButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_OFFSET * 2, IMAGE_OFFSET * 2)];
        UIImageView* bottomDotButtonImageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0,
                                                                                                smallDotImage.size.width ,
                                                                                                smallDotImage.size.height)];
        bottomDotButtonImageView.image = smallDotImage;
        bottomDotButtonImageView.center = CGPointMake(self.bottomDotButton.frame.size.width / 2, self.bottomDotButton.frame.size.height / 2);
        [self.bottomDotButton addSubview: bottomDotButtonImageView];
        self.bottomDotButton.backgroundColor = [UIColor clearColor];
        [self.bottomDotButton addGestureRecognizer: self.bottomResizeGestureRecognizer];
        
        self.contentMode = UIViewContentModeRedraw;
        
        self.leftBottomCornerLargeDot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, IMAGE_OFFSET * 2, IMAGE_OFFSET * 2)];
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
        
        
//        self.textScale = CGPointMake(1.f, 1.f);
        
        self.textOpacity             = 1;
        
        self.mainImageView = [[UIImageView alloc] init];
        self.mainImageView.frame = self.bounds;
        
        [self addSubview: self.mainImageView];
        [self addSubview: self.borderView];
        
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
    }
    
    return self;
}

- (void) dealloc
{
    self.mainImageView      = nil;
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

- (void) layoutSubviews
{
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
    [super layoutSubviews];

    self.mainImageView.transform = CGAffineTransformIdentity;

    self.borderView.frame  = CGRectMake(IMAGE_OFFSET, IMAGE_OFFSET,
            ceilf(self.frame.size.width - IMAGE_OFFSET * 2),
            ceilf(self.frame.size.height - IMAGE_OFFSET * 2));

    self.mainImageView.frame = CGRectMake(0, 0, self.bounds.size.width - 2 * IMAGE_OFFSET, self.bounds.size.height - 2 * IMAGE_OFFSET);
    self.mainImageView.center = CGPointMake(self.frame.size.width / 2,
            self.frame.size.height / 2);

    //self.mainImageView.transform = CGAffineTransformMakeScale(self.textScale.x, self.textScale.y);
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

    self.transform = transform;
}

#pragma mark -
#pragma mark Getters

- (BOOL) isActive
{
    return _active;
}

#pragma mark -
#pragma mark Setters

- (void) setImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    
    CGRect frame = self.frame;
    
//    frame.size.width = _imageSize.width * self.textScale.x + IMAGE_OFFSET * 2;
//    frame.size.height = _imageSize.height * self.textScale.y + IMAGE_OFFSET * 2;
    
    frame.size.width = _imageSize.width + IMAGE_OFFSET * 2;
    frame.size.height = _imageSize.height + IMAGE_OFFSET * 2;
    
    self.frame = frame;
    
    [self setNeedsLayout];
}

- (void) setImageSize:(CGSize)imageSize scale:(float)scale
{
    _imageSize = imageSize;
    
    CGRect frame = self.frame;
    
//    frame.size.width = _imageSize.width * self.textScale.x + IMAGE_OFFSET * 2;
//    frame.size.height = _imageSize.height * self.textScale.y + IMAGE_OFFSET * 2;
    
    //    frame.size.width = _imageSize.width + IMAGE_OFFSET * 2;
    //    frame.size.height = _imageSize.height + IMAGE_OFFSET * 2;
    
    self.frame = frame;
    
    [self setNeedsLayout];
}

- (void) setProportionalResize:(BOOL)proportionalResize
{
    _proportionalResize = proportionalResize;
    
//    if(proportionalResize)
//        self.textScale = CGPointMake(1.0, 1.0);
    
    [self updateResizing];
}

- (void) setActive: (BOOL) active
{
    _active = active;
    
    if (active)
    {
        self.rotationImageView.hidden   = NO;
        self.removeImageView.hidden     = NO;
        
        self.rotateRecognaizer.enabled  = YES;
        self.removeRecognaizer.enabled  = YES;
        
        self.borderView.layer.borderColor = ACTIVE_BORDER_COLOR;
    }
    else
    {
        self.rotationImageView.hidden   = YES;
        self.removeImageView.hidden     = YES;
        
        self.rotateRecognaizer.enabled  = NO;
        self.removeRecognaizer.enabled  = NO;
        
        self.borderView.layer.borderColor = INACTIVE_BORDER_COLOR;
    }
    
     [self updateResizing];
}

- (void) setTextOpacity: (CGFloat) textOpacity
{
    _textOpacity = textOpacity;
    
    self.mainImageView.alpha = _textOpacity;
}

- (NSLineBreakMode) textLineBreakMode
{
    return NSLineBreakByWordWrapping;
}

- (void)setImage:(UIImage*)image
{
    self.mainImageView.image = image;
}

- (void)setOriginImage:(UIImage *)image {
    _originImage = image;
}

- (CGFloat) getRotation
{
    return self.rotation;
}

- (UIImage*) getImage
{
    return self.mainImageView.image;
}

- (UIImage *) getOriginImage {
    return self.originImage;
}

- (void) setReflection: (CGFloat) refl
{
    _reflection = refl;
}

//- (void) setTextScale:(CGPoint)textScale
//{
//    _textScale = textScale;
//}

#pragma mark -
#pragma mark Gesture Recognizers Handling

- (void) activeView: (UITapGestureRecognizer*) tap
{
    if (![self.delegate isEditMode]) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector: @selector(graphicsViewWillBecomeActive:)])
        [self setActive:[self.delegate graphicsViewWillBecomeActive: self]];
    else
        [self setActive: YES];
}

- (void) rotate: (UIPanGestureRecognizer*) pan
{
    if (pan.state == UIGestureRecognizerStateEnded)
    {
        self.lastRotation = 0.0;
        return;
    }
    
    if (pan.state == UIGestureRecognizerStateBegan)
        self.lastPoint = [pan locationInView: self.superview];
    
    CGFloat newRotation = [self getRotationTo: [pan locationInView: self.superview]];
    CGFloat rotation = (self.lastRotation - newRotation);
    
    CGAffineTransform currentTransform = self.transform;
    CGAffineTransform newTransform = CGAffineTransformRotate(currentTransform,rotation);
    
    [self setTransform: newTransform];
    
    self.rotation = self.rotation + rotation;    
    [self.delegate setRotate:self];
    
    if(self.delegate && [self.delegate respondsToSelector: @selector(graphicsView:shouldChangeFrame:)])
    {
        if(![self.delegate graphicsView: self
                  shouldChangeFrame: self.frame])
        {
            [self setTransform: currentTransform];
            
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

- (void) resize: (UIPanGestureRecognizer*) pan
{
    if (self.isEditing)
        return;
    
    // static CGRect beginTextViewFrame;
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        self.firstPoint = [pan translationInView: nil];
        CGAffineTransform transform = self.transform;
        self.transform = CGAffineTransformIdentity;
        self.firstFrame = self.frame;
        self.transform = transform;
    }
    
    CGFloat deltaX = ceilf([pan translationInView: self].x - self.firstPoint.x);
    CGFloat deltaY = ceilf([pan translationInView: self].y - self.firstPoint.y);
    
    deltaX = deltaY;
    
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
    
    if (MIN_GRAPHICSVIEW_SIZE.height < ceilf(self.firstFrame.size.height + newHeight) && MIN_GRAPHICSVIEW_SIZE.width < ceilf(self.firstFrame.size.width + newWidth))
    {
        CGRect newFrame = CGRectMake(ceilf(self.firstFrame.origin.x + newX),
                                     ceilf(self.firstFrame.origin.y + newY),
                                     ceilf(self.firstFrame.size.width + newWidth),
                                     ceilf(self.firstFrame.size.height + newHeight));
        
        CGFloat xScale = (newFrame.size.width - IMAGE_OFFSET* 2) / self.mainImageView.image.size.width;
        CGFloat yScale = (newFrame.size.height - IMAGE_OFFSET * 2) / self.mainImageView.image.size.height;
        
        if(xScale > MAX_SCALE || xScale < MIN_SCALE)
            return;
        
        if (yScale > MAX_SCALE || yScale < MIN_SCALE)
            return;
        
        if(self.delegate && [self.delegate respondsToSelector: @selector(graphicsView:shouldChangeFrame:)])
            if([self.delegate graphicsView: self
                     shouldChangeFrame: newFrame])
            {
                CGAffineTransform transform = self.transform;
                self.transform = CGAffineTransformIdentity;
                
                self.frame = newFrame;
                
                self.transform = transform;
//                self.textScale = CGPointMake(xScale, yScale);
            }
    }
}

- (void) resizePinch: (UIPinchGestureRecognizer*) pinch
{
    if(self.proportionalResize)
        return;
    
    CGAffineTransform transform = self.transform;
    self.transform = CGAffineTransformIdentity;
    if (pinch.state == UIGestureRecognizerStateBegan)
    {
        self.firstCenter = self.center;
        self.firstFrame  = self.frame;
    }
    
    CGSize newSize = CGSizeMake(self.firstFrame.size.width * pinch.scale, self.firstFrame.size.height * pinch.scale);
    
    CGFloat deltaX = (NSInteger)newSize.width - (NSInteger)self.firstFrame.size.width;
    CGFloat deltaY = (NSInteger)newSize.height - (NSInteger)self.firstFrame.size.height;
    
    
    
    if (MIN_GRAPHICSVIEW_SIZE.height < ceilf(self.firstFrame.size.height + deltaY) && MIN_GRAPHICSVIEW_SIZE.width < ceilf(self.firstFrame.size.width + deltaX))
    {
        CGRect newFrame = CGRectMake(ceilf(self.firstFrame.origin.x - deltaX / 2),
                                     ceilf(self.firstFrame.origin.y - deltaY / 2),
                                     ceilf(self.firstFrame.size.width + deltaX),
                                     ceilf(self.firstFrame.size.height + deltaY));
        
        CGFloat xScale = (newFrame.size.width - IMAGE_OFFSET * 2) / self.mainImageView.image.size.width;
        CGFloat yScale = (newFrame.size.height - IMAGE_OFFSET * 2) / self.mainImageView.image.size.height;
        
        if(xScale > MAX_SCALE || xScale < MIN_SCALE)
            return;
        
        if (yScale > MAX_SCALE || yScale < MIN_SCALE)
            return;
        
        if(self.delegate && [self.delegate respondsToSelector: @selector(graphicsView:shouldChangeFrame:)])
            if([self.delegate graphicsView: self
                     shouldChangeFrame: newFrame])
            {
                
                self.frame = newFrame;
                
                
//                self.textScale = CGPointMake(xScale, yScale);
            }
    }
    
    self.transform = transform;
}

- (void) remove: (UITapGestureRecognizer*) tap
{
    if (self.isEditing)
        return;
    
    if (self.delegate && [self.delegate respondsToSelector: @selector(graphicsViewRemovePressed:)])
        [self.delegate graphicsViewRemovePressed: self];
}

- (void) doubleTapHandler: (UITapGestureRecognizer*) tap
{
    // do nothing (for catch double tap)
}

- (void) updateResizing
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

- (CGFloat) pointPairToBearing: (CGPoint) startingPoint secondPoint: (CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    
    return bearingRadians;
}

- (CGFloat) getRotationTo: (CGPoint) toPoint
{
    CGFloat rotation = [self pointPairToBearing: self.center secondPoint: self.lastPoint] - [self pointPairToBearing: self.center secondPoint: toPoint];
    
    return rotation;
}

#pragma mark -
#pragma mark Private methods

- (CALayer *)layerWithImageRepresentationForSize:(CGSize)videoSize scale:(CGFloat)scale
{
    UIView* imageView = self.superview;
    
    // preserve original metrics
    BOOL isActive = self.active;
    BOOL isHidden = self.hidden;
    self.active = NO;
    self.hidden = NO;
    
    NSData *tempArchiveView = [NSKeyedArchiver archivedDataWithRootObject:self];
    TVImageView *renderImageView = [NSKeyedUnarchiver unarchiveObjectWithData:tempArchiveView];
    renderImageView.center = CGPointMake(renderImageView.center.x - imageView.frame.origin.x, renderImageView.center.y - imageView.frame.origin.y);
    
    UIView *renderView = [[UIView alloc] initWithFrame:imageView.bounds];
    renderView.backgroundColor = [UIColor clearColor];
    [renderView addSubview:renderImageView];
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    UIGraphicsBeginImageContextWithOptions(renderView.frame.size, NO, screenScale);
    
    [renderView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *renderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.active = isActive;
    self.hidden = isHidden;
    
    renderImage = [renderImage resizedImageToSize:videoSize];
    
    // paste to CALayer
    CALayer* aLayer = [CALayer layer];
    CGRect startFrame = CGRectMake(0.0, 0.0, videoSize.width, videoSize.height);
    aLayer.contents = (id)renderImage.CGImage;
    aLayer.frame = startFrame;
    
    return aLayer;
}

+ (UIImage *)renderImageOfView:(UIView *)view withZoom:(float)zoom
{
    CGSize sz = CGSizeMake(view.frame.size.width * zoom, view.frame.size.height * zoom);
    
    UIGraphicsBeginImageContext(sz);
    
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), zoom, zoom);
    
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeNormal);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
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

@end

