//
//  CustomTextView.m
//  PhotoInk
//
//  Created by Serg Shulga on 9/3/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#import "CustomTextView.h"
#import <CoreText/CoreText.h>
#import "TVTextView.h"

@interface CustomTextView ()

@property (nonatomic, retain) CAGradientLayer *gradientLayer;

@end


@implementation CustomTextView

@synthesize reflectionGap = _reflectionGap;
@synthesize reflectionScale = _reflectionScale;
@synthesize reflectionAlpha = _reflectionAlpha;
@synthesize gradientLayer = _gradientLayer;
@synthesize reflectionView = _reflectionView;
@synthesize dynamic = _dynamic;
@synthesize textBackgroundColor;

+ (Class)layerClass
{
    return [CAReplicatorLayer class];
}

- (void) drawRect:(CGRect)rect
{
    if(self.textBackgroundColor)
    {
        
#if 0
//new
        CGFloat redValue, greenValue, blueValue, alphaValue;
        [self.textBackgroundColor getRed:&redValue green:&greenValue blue:&blueValue alpha:&alphaValue];
        
        CGSize size = [self.text boundingRectWithSize:rect.size
                                              options:NSStringDrawingTruncatesLastVisibleLine
                                           attributes:@{NSFontAttributeName:self.font}
                                              context:nil].size;
        CGRect textRect = CGRectMake((rect.size.width - size.width) / 2 - 4, (rect.size.height - size.height) / 2 - 1, size.width, size.height);
        
        CGContextRef textContext = UIGraphicsGetCurrentContext();
        CGContextSaveGState(textContext);
        CGContextSetLineWidth(textContext, UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2 : 1.8);
        CGContextSetTextDrawingMode (textContext, kCGTextStroke);
        
        NSDictionary *attrs = @{NSFontAttributeName : self.font, NSForegroundColorAttributeName : self.textBackgroundColor};
        [self.text drawInRect:textRect withAttributes:attrs];
        
        CGContextRestoreGState(textContext);
        
#else
        
        
        TVTextView *tx = (TVTextView*)self.delegate;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentLeft;
        paragraphStyle.lineSpacing = [tx getVSpacing];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSLog(@"%f", [tx getHSpacing]);
        
        NSDictionary * dictAttributeText = @{
                                             NSParagraphStyleAttributeName : paragraphStyle,
                                             NSKernAttributeName : [NSNumber numberWithFloat: [tx getHSpacing]],
                                             NSFontAttributeName : self.font,
                                             NSForegroundColorAttributeName : self.textBackgroundColor
                                             };

        CGFloat lineSpacing = [tx getVSpacing];
        
        // Text rect calculating
        CGSize currentTextSize = self.contentSize;
        
        currentTextSize = self.textContainer.size; //thesun
        
//        CGSize currentTextSizeBorder = [self.text boundingRectWithSize:currentTextSize
//                                                         options:NSStringDrawingUsesDeviceMetrics
//                                                      attributes:dictAttributeText
//                                                         context:nil].size;
        
        CGRect textRect = CGRectMake(0, 0, currentTextSize.width - 10, currentTextSize.height);

        
        // Creating new mutable attributed string attributes
        CFAttributedStringRef newAttributedString  = CFBridgingRetain([[NSAttributedString alloc] initWithString:
                                                                       self.text attributes: dictAttributeText]);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, textRect);
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(newAttributedString);
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                    CFRangeMake(0, CFAttributedStringGetLength(newAttributedString)),
                                                    path,
                                                    NULL);
        
        // Getting lines of text
        CFArrayRef lines = CTFrameGetLines(frame);
        
        // Initialize begin data
        CGFloat beginX = 6;
        CGFloat beginY = 7;
        
        // Setting text background color
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),
                                       [self.textBackgroundColor CGColor]);
        
        // Drawing setted text background color for each line in text
        for(int i = 0; i < CFArrayGetCount(lines); i++)
        {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CFRange range  = CTLineGetStringRange(line);
            
            NSString* lineString = [self.text substringWithRange: NSMakeRange(range.location, range.length)];
            CGSize textLineSize  = [lineString sizeWithFont: self.font];
            
            CGRect fillingRect = CGRectZero;
            
            CGFloat lineHeight = self.font.lineHeight;
            CGFloat ascent = self.font.ascender;
            CGFloat descent = self.font.descender;
            CGFloat capHeight = self.font.capHeight;
            
            CGFloat fontDeviation = (lineHeight - ascent - (-descent) - 1) / 2;
            
            //NSLog(@"%f, %f, %f, %f, %f, %f", lineHeight, ascent, descent, capHeight,self.font.pointSize, fontDeviation);
            
            fillingRect.origin.x    = beginX;
            fillingRect.origin.y    = (beginY + (lineHeight - capHeight - (-descent) - 1 - fontDeviation));//(beginY + (ascent - capHeight)) * scaleY;
            fillingRect.size.width  = textLineSize.width  + 4;
            fillingRect.size.height = capHeight + (-descent) + 1 + fontDeviation;//ascent + (-descent);//lineHeight - (ascent - capHeight) + 3;//lineHeight - (textLineSize.height - 5) * scaleY;
            
#if 0
            CGContextFillRect(UIGraphicsGetCurrentContext(), fillingRect);
#else
            
            
            CGSize size = [lineString boundingRectWithSize:rect.size
                                                  options:NSStringDrawingTruncatesLastVisibleLine
                                               attributes:dictAttributeText
                                                  context:nil].size;
            CGRect textRect = CGRectMake((rect.size.width - size.width) / 2 - 4, (rect.size.height - size.height) / 2 - 1, size.width, size.height);
            
            
            CGFloat strokeWidth = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 2.0 : 1.8);
            
            fillingRect.origin.x    = beginX - (strokeWidth / 2.0);
            fillingRect.origin.y    = beginY + (strokeWidth / 2.0) +  (i == 0 ? 0 : (lineSpacing * i));
            fillingRect.size.width  = size.width  + strokeWidth;
            fillingRect.size.height = size.height + strokeWidth;
            
            CGFloat redValue, greenValue, blueValue, alphaValue;
            [self.textBackgroundColor getRed:&redValue green:&greenValue blue:&blueValue alpha:&alphaValue];
            
            CGContextRef textContext = UIGraphicsGetCurrentContext();
            CGContextSaveGState(textContext);
            CGContextSetLineWidth(textContext, strokeWidth);
            CGContextSetTextDrawingMode (textContext, kCGTextStroke);
            
            [lineString drawInRect:fillingRect withAttributes: dictAttributeText];
            
            
            
            CGContextRestoreGState(textContext);
            
#endif
            
            
            
            beginY += textLineSize.height;
        }
        
        CFRelease(path);
        CFRelease(frame);
        CFRelease(framesetter);
        CFRelease(newAttributedString);
#endif
    }

}
- (void)update
{
   // return;
    if (_dynamic)
    {
        //remove gradient view
        [_reflectionView removeFromSuperview];
        self.reflectionView = nil;
        
        //update instances
        CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;
        layer.shouldRasterize = YES;
        layer.rasterizationScale = [UIScreen mainScreen].scale;
        layer.instanceCount = 2;
        CATransform3D transform = CATransform3DIdentity;
        transform = CATransform3DTranslate(transform, 0.0f, layer.bounds.size.height + _reflectionGap, 0.0f);
        transform = CATransform3DScale(transform, 1.0f, -1.0f, 0.0f);
        layer.instanceTransform = transform;
        layer.instanceAlphaOffset = _reflectionAlpha - 1.0f;
        
        //create gradient layer
        if (!_gradientLayer)
        {
            _gradientLayer = [[CAGradientLayer alloc] init];
            self.layer.mask = _gradientLayer;
            _gradientLayer.colors = [NSArray arrayWithObjects:
                                     (__bridge id)[UIColor blackColor].CGColor,
                                     (__bridge id)[UIColor blackColor].CGColor,
                                     (__bridge id)[UIColor clearColor].CGColor,
                                     nil];
        }
        
        //update mask
        [CATransaction begin];
        [CATransaction setDisableActions:YES]; // don't animate
        CGFloat total = layer.bounds.size.height * 2.0f + _reflectionGap;
        CGFloat halfWay = (layer.bounds.size.height + _reflectionGap) / total - 0.01f;
        _gradientLayer.backgroundColor = [[UIColor clearColor] CGColor];
        _gradientLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, total);
        _gradientLayer.locations = [NSArray arrayWithObjects:
                                    [NSNumber numberWithFloat: 0.0f],
                                    [NSNumber numberWithFloat: halfWay],
                                    [NSNumber numberWithFloat: halfWay + (1.0f - halfWay) * _reflectionScale],
                                    nil];
        [CATransaction commit];
    }
    else
    {
        //remove gradient layer
        self.layer.mask = nil;
        self.gradientLayer = nil;
        
        //update instances
        CAReplicatorLayer *layer = (CAReplicatorLayer *)self.layer;
        layer.shouldRasterize = NO;
        layer.instanceCount = 1;
        
        //create reflection view
        if (!_reflectionView)
        {
            _reflectionView = [[UIImageView alloc] initWithFrame: self.bounds];
            _reflectionView.contentMode = UIViewContentModeScaleToFill;
            _reflectionView.userInteractionEnabled = NO;
            [self addSubview:_reflectionView];
        }
        
        //get reflection bounds
        CGSize size = CGSizeMake(self.bounds.size.width, self.bounds.size.height * _reflectionScale + _reflectionGap);
        if (size.height > 0.0f && size.width > 0.0f)
        {
            //create gradient mask
            UIGraphicsBeginImageContextWithOptions(size, YES, 0.0f);
            CGContextRef gradientContext = UIGraphicsGetCurrentContext();
            CGFloat colors[] = {1.0f, 1.0f, 0.0f, 1.0f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
            CGPoint gradientStartPoint = CGPointMake(0.0f, 0.0f);
            CGPoint gradientEndPoint = CGPointMake(0.0f, size.height);
            CGContextDrawLinearGradient(gradientContext, gradient, gradientStartPoint,
                                        gradientEndPoint, kCGGradientDrawsAfterEndLocation);
            CGImageRef gradientMask = CGBitmapContextCreateImage(gradientContext);
            CGGradientRelease(gradient);
            CGColorSpaceRelease(colorSpace);
            UIGraphicsEndImageContext();
            
            //create drawing context
            UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1.0f, -1.0f);
            CGContextTranslateCTM(context, 0.0f, -(self.bounds.size.height));
            
            //clip to gradient
            CGContextClipToMask(context, CGRectMake(0.0f, self.bounds.size.height - size.height,
                                                    size.width, size.height), gradientMask);
            CGImageRelease(gradientMask);
            
            //draw reflected layer content
            [self.layer renderInContext:context];
            
            //capture resultant image
            _reflectionView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        
        //update reflection
        _reflectionView.alpha = _reflectionAlpha;
        _reflectionView.frame = CGRectMake(0, self.bounds.size.height + _reflectionGap, size.width, size.height);
    }

    [self setNeedsDisplay];
}

- (void)setUp
{
    //set default properties
    _reflectionGap   = -2.0f;//-6.0f;
    //_reflectionGap   = 0.0f;
    _reflectionScale = 0.0f;
    _reflectionAlpha = 1.0f;
    
    _dynamic = NO;
    
    //thesun
//    self.textContainer.maximumNumberOfLines = 1;
    
    //update reflection
    [self setNeedsLayout];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        self.textBackgroundColor = nil;
        [self setUp];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setUp];
        self.textBackgroundColor = nil;
        self.layer.masksToBounds = NO;
    }
    
    return self;
}

- (void)setReflectionGap:(CGFloat)reflectionGap
{
    _reflectionGap = reflectionGap;
    [self setNeedsLayout];
}

- (void)setReflectionScale:(CGFloat)reflectionScale
{
    _reflectionScale = reflectionScale;
    [self setNeedsLayout];
}

- (void)setReflectionAlpha:(CGFloat)reflectionAlpha
{
    _reflectionAlpha = reflectionAlpha;
    [self setNeedsLayout];
}

- (void)setDynamic:(BOOL)dynamic
{
    _dynamic = dynamic;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
//    [self update];
}

- (void) setText:(NSString *)text
{
    [super setText: text];
}

- (void)dealloc
{
    
}

@end
