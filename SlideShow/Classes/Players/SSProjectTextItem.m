//
//  SSProjectTextItem.m
//  SlideShow
//
//  Created by Arda Ozupek on 4.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectTextItem.h"
#import "SSCore.h"
#import "ThemeManager.h"

const CGFloat SSProjectTextItemMaxStrokeWidth = 10.0f;

@interface SSProjectTextItem ()

@end

@implementation SSProjectTextItem

#pragma mark - Life Cycle
+(SSProjectTextItem *)textWithTitle:(NSString *)title {
    SSProjectTextItem* text = [[SSProjectTextItem alloc] init];
    text->_title = title;
    [text refreshLabel];
    return text;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        SSLabel* label = [[SSLabel alloc] init];
        label.minimumScaleFactor = 0.002f;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        self->_label = label;
        self->_font = [UIFont fontWithName:@"KaushanScript-Regular" size:500.0f];
        self->_titleColor = [ThemeManager sharedInstance].colors.firstObject;
        self->_stroke = NO;
        self->_strokeWidth = SSProjectTextItemMaxStrokeWidth * -0.25f;
        self->_strokeColor = [ThemeManager sharedInstance].colors[19];
        self->_displaySize = CGSizeZero;
        self->_displayRotation = 0.0f;
        self->_displayCenter = CGPointZero;
    }
    return self;
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.title forKey:@"title"];
    [aCoder encodeObject:self.font.fontName forKey:@"font.fontName"];
    [aCoder encodeFloat:self.font.pointSize forKey:@"font.pointSize"];
    [aCoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.titleColor] forKey:@"titleColor"];
    [aCoder encodeBool:self.stroke forKey:@"stroke"];
    [aCoder encodeFloat:self.strokeWidth forKey:@"strokeWidth"];
    [aCoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.strokeColor] forKey:@"strokeColor"];
    [aCoder encodeObject:NSStringFromCGSize(self.displaySize) forKey:@"displaySize"];
    [aCoder encodeObject:NSStringFromCGPoint(self.displayCenter) forKey:@"displayCenter"];
    [aCoder encodeFloat:self.displayRotation forKey:@"displayRotation"];
    [aCoder encodeObject:NSStringFromCGRect(self.label.frame) forKey:@"label.frame"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self->_title = [aDecoder decodeObjectForKey:@"title"];
        self->_font = [UIFont fontWithName:[aDecoder decodeObjectForKey:@"font.fontName"]
                                      size:[aDecoder decodeFloatForKey:@"font.pointSize"]];
        self->_titleColor = [NSKeyedUnarchiver unarchiveObjectWithData:[aDecoder decodeObjectForKey:@"titleColor"]];
        self->_stroke = [aDecoder decodeBoolForKey:@"stroke"];
        self->_strokeWidth = [aDecoder decodeFloatForKey:@"strokeWidth"];
        self->_strokeColor = [NSKeyedUnarchiver unarchiveObjectWithData:[aDecoder decodeObjectForKey:@"strokeColor"]];
        self->_displaySize = CGSizeFromString([aDecoder decodeObjectForKey:@"displaySize"]);
        self->_displayCenter = CGPointFromString([aDecoder decodeObjectForKey:@"displayCenter"]);
        self->_displayRotation = [aDecoder decodeFloatForKey:@"displayRotation"];
        SSLabel* label = [[SSLabel alloc] init];
        label.minimumScaleFactor = 0.002f;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.frame = CGRectFromString([aDecoder decodeObjectForKey:@"label.frame"]);
        self->_label = label;
        [self refreshLabel:NO];
    }
    return self;
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectTextItem* item = [super copyWithZone:zone];
    if (item) {
        SSLabel* label = [[SSLabel alloc] init];
        label.minimumScaleFactor = self.label.minimumScaleFactor;
        label.adjustsFontSizeToFitWidth = self.label.adjustsFontSizeToFitWidth;
        label.baselineAdjustment = self.label.baselineAdjustment;
        label.attributedText = self.label.attributedText;
        label.frame = self.label.frame;
        item->_label = label;
        item->_title = self.title;
        item->_font = self.font;
        item->_titleColor = self.titleColor;
        item->_stroke = self.stroke;
        item->_strokeWidth = self.strokeWidth;
        item->_strokeColor = self.strokeColor;
        item->_displaySize = self.displaySize;
        item->_displayCenter = self.displayCenter;
        item->_displayRotation = self.displayRotation;
    }
    return item;
}


#pragma mark - Setter
-(void)setTitle:(NSString *)title {
    _title = title;
}

-(void)setFont:(UIFont *)font {
    _font = [font fontWithSize:500.0f];
}

-(void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
}

-(void)setStroke:(BOOL)stroke {
    _stroke = stroke;
}

-(void)setStrokeWidth:(CGFloat)strokeWidth {
    _strokeWidth = strokeWidth;
}

-(void)setStrokeColor:(UIColor *)strokeColor {
    _strokeColor = strokeColor;
}


#pragma mark - Display
-(NSAttributedString*)attributedText {
    return [self attributedTextWithFontSize:self.font.pointSize];
}

-(NSAttributedString*)attributedTextWithFontSize:(CGFloat)fontSize {
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    attributes[NSFontAttributeName] = self.font;
    attributes[NSForegroundColorAttributeName] = self.titleColor;
    NSMutableParagraphStyle* paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
    attributes[NSParagraphStyleAttributeName] = paragraph;
    if (self.stroke) {
        attributes[NSStrokeColorAttributeName] = self.strokeColor;
        attributes[NSStrokeWidthAttributeName] = @(self.strokeWidth);
    }
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:self.title attributes:attributes];
    return attributedString;
}

-(void)refreshLabel {
    [self refreshLabel:YES];
}

-(void)refreshLabel:(BOOL)changeSize {
    NSAttributedString* attributedString = [self attributedText];
    self.label.attributedText = attributedString;
    if (changeSize) {
        [self.label sizeToFit];
    }
}

-(CGFloat)displayFontSize {
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithAttributedString:self.label.attributedText];
    NSStringDrawingContext* context = [NSStringDrawingContext new];
    context.minimumScaleFactor = self.label.minimumScaleFactor;
    [text boundingRectWithSize:self.label.frame.size options:NSStringDrawingUsesLineFragmentOrigin context:context];
    CGFloat adjustedFontSize = self.label.font.pointSize * context.actualScaleFactor;
    return adjustedFontSize;
}


#pragma mark - Render
-(SSLabel *)generateLabelToRenderAtSize:(CGSize)size {
    SSLabel* label = [[SSLabel alloc] init];
    label.minimumScaleFactor = self.label.minimumScaleFactor;
    label.adjustsFontSizeToFitWidth = self.label.adjustsFontSizeToFitWidth;
    label.baselineAdjustment = self.label.baselineAdjustment;
    label.attributedText = [self attributedText];
    label.frame = (CGRect){CGPointZero, CGSizeDenormalize(self.displaySize, size)};
    label.center = CGPointDenormalize(self.displayCenter, size);
    label.transform = CGAffineTransformMakeRotation(self.displayRotation);
    return label;
}

@end
