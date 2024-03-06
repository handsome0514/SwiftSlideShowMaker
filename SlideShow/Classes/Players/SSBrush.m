//
//  SSBrush.m
//  SlideShow
//
//  Created by Arda Ozupek on 10.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSBrush.h"

@implementation SSBrush

#pragma mark - Life Cycle
+(SSBrush *)brushWithType:(SSBrushType)type {
    SSBrush* brush = [[SSBrush alloc] init];
    brush->_type = type;
    brush->_image = [SSBrush imageForType:brush.type];
    brush->_name = [SSBrush nameForType:brush.type];
    return brush;
}

#pragma mark - Image
+(UIImage*)imageForType:(SSBrushType)type {
    NSString* name = @"";
    if (type == kSSBrushTypeCircle) {
        name = @"scribble_brush_circle";
    }
    else if (type == kSSBrushTypeGlow) {
        name = @"scribble_brush_glow";
    }
    else if (type == kSSBrushTypeSparkles) {
        name = @"scribble_brush_sparkles";
    }
    else if (type == kSSBrushTypeBlur) {
        name = @"scribble_brush_blur";
    }
    else if (type == kSSBrushTypeScratch) {
        name = @"scribble_brush_scratch";
    }
    else if (type == kSSBrushTypeAngled) {
        name = @"scribble_brush_angled";
    }
    UIImage* image = [UIImage imageNamed:name];
    NSAssert(image, @"Brush image couldn't found!");
    return image;
}


#pragma mark - Name
+(NSString*)nameForType:(SSBrushType)type {
    NSString* name = @"";
    if (type == kSSBrushTypeCircle) {
        name = @"Circle";
    }
    else if (type == kSSBrushTypeGlow) {
        name = @"Glow";
    }
    else if (type == kSSBrushTypeSparkles) {
        name = @"Sparkles";
    }
    else if (type == kSSBrushTypeBlur) {
        name = @"Blur";
    }
    else if (type == kSSBrushTypeScratch) {
        name = @"Scratch";
    }
    else if (type == kSSBrushTypeAngled) {
        name = @"Angled";
    }
    return name;
}
@end
