//
//  SSProjectScribbleItem.m
//  SlideShow
//
//  Created by Arda Ozupek on 10.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectScribbleItem.h"
#import "SSCore.h"

@interface SSProjectScribbleItem ()
{
    CGPoint lastPosition;
}
@property (nonatomic, strong) UIImage* brushImage;
@end

@implementation SSProjectScribbleItem

#pragma mark - Life Cycle
+(SSProjectScribbleItem *)scribble {
    SSProjectScribbleItem* scribble = [[SSProjectScribbleItem alloc] init];
    return scribble;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self->_undoStack = @[];
        self->_stackIndex = -1;
        self->_color = [UIColor whiteColor];
        self->_scale = 0.5f;
        self.brush = [SSEffectManager sharedInstance].brushes.firstObject;
        self->_imageView = [[UIImageView alloc] init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}


#pragma mark - NSCoding
-(void)encodeWithCoder:(NSCoder *)aCoder {
    
    NSInteger brushIndex = [[SSEffectManager sharedInstance].brushes indexOfObject:self.brush];
    [aCoder encodeInteger:brushIndex forKey:@"brushIndex"];
    [aCoder encodeObject:[NSKeyedArchiver archivedDataWithRootObject:self.color] forKey:@"color"];
    [aCoder encodeFloat:self.scale forKey:@"scale"];
    [aCoder encodeBool:self.erase forKey:@"erase"];
    NSMutableArray<NSData*>* undoStack = [[NSMutableArray alloc] init];
    for (UIImage* image in self.undoStack) {
        NSData* data = UIImagePNGRepresentation(image);
        [undoStack addObject:data];
    }
    [aCoder encodeObject:[undoStack copy] forKey:@"undoStack"];
    [aCoder encodeInteger:self.stackIndex forKey:@"stackIndex"];
    [aCoder encodeObject:NSStringFromCGRect(self.imageView.frame) forKey:@"imageView.frame"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        NSInteger brushIndex = [aDecoder decodeIntegerForKey:@"brushIndex"];
        if (brushIndex >= [SSEffectManager sharedInstance].brushes.count) {
            brushIndex = 0;
        }
        self->_brush = [SSEffectManager sharedInstance].brushes[brushIndex];
        self->_color = [NSKeyedUnarchiver unarchiveObjectWithData:[aDecoder decodeObjectForKey:@"color"]];
        self->_scale = [aDecoder decodeFloatForKey:@"scale"];
        self->_erase = [aDecoder decodeObjectForKey:@"erase"];
        NSArray<NSData*>* undoStackData = [aDecoder decodeObjectForKey:@"undoStack"];
        NSMutableArray<UIImage*>* undoStack = [[NSMutableArray alloc] init];
        for (NSData* data in undoStackData) {
            UIImage* image = [UIImage imageWithData:data];
            [undoStack addObject:image];
        }
        self->_undoStack = [undoStack copy];
        self->_stackIndex = [aDecoder decodeIntegerForKey:@"stackIndex"];
        UIImageView* imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.frame = CGRectFromString([aDecoder decodeObjectForKey:@"imageView.frame"]);
        if (self.stackIndex >= 0) {
            imageView.image = self.undoStack[self.stackIndex];
        }
        self->_imageView = imageView;
    }
    return self;
}


#pragma mark - NSCopying
-(id)copyWithZone:(NSZone *)zone {
    SSProjectScribbleItem* item = [super copyWithZone:zone];
    if (item) {
        item->_imageView = [[UIImageView alloc] initWithFrame:self.imageView.frame];
        item.imageView.contentMode = self.imageView.contentMode;
        item.imageView.image = self.imageView.image;
        item->_brush = self.brush;
        item->_color = self.color;
        item->_scale = self.scale;
        item->_erase = self.isErasing;
        item->_undoStack = [self.undoStack copy];
        item->_stackIndex = self.stackIndex;
        item->_brushImage = self.brushImage;
        item->lastPosition = lastPosition;
    }
    return item;
}


#pragma mark - Brush
-(void)setBrush:(SSBrush *)brush {
    _brush = brush;
    [self refreshBrush];
}

-(void)setColor:(UIColor *)color {
    NSAssert(self.brush, @"Brush is nil! Set the brush first!");
    _color = color;
    [self refreshBrush];
}

-(void)setScale:(CGFloat)scale {
    NSAssert(self.brush, @"Brush is nil! Set the brush first!");
    _scale = scale;
    [self refreshBrush];
}

-(void)refreshBrush {
    self.brushImage = [SSEffectProcessor tintImage:self.brush.image withColor:self.color scale:self.scale];
}


#pragma mark - History
-(void)undo {
    if (self.stackIndex == -1) {
        return;
    }
    NSInteger index = MAX(-1, self.stackIndex - 1);
    UIImage* image = index >= 0 ? self.undoStack[index] : nil;
    self.imageView.image = image;
    self->_stackIndex = index;
}

-(void)redo {
    NSInteger stackCount = self.undoStack.count;
    if (self.stackIndex == stackCount - 1) {
        return;
    }
    NSInteger index = MIN(stackCount - 1, self.stackIndex + 1);
    UIImage* image = index >= 0 ? self.undoStack[index] : nil;
    self.imageView.image = image;
    self->_stackIndex = index;
}

-(void)clear {
    self->_undoStack = @[];
    self->_stackIndex = -1;
    self.imageView.image = nil;
}


#pragma mark - User Interaction
-(void)handleTouchesBegan:(CGPoint)position {
    lastPosition = position;
}

-(void)handleTouchesMoved:(CGPoint)position {
    CGBlendMode blendMode = self.isErasing ? kCGBlendModeClear : kCGBlendModeNormal;
    UIGraphicsBeginImageContextWithOptions(self.imageView.frame.size, NO, self.brushImage.scale);
    NSAssert(self.imageView.frame.size.width == self.imageView.frame.size.height, @"Invalid size!");
    [self.imageView.image drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    UIImage* textureColor;
    float angle = hypot(lastPosition.x - position.x, lastPosition.y - position.y);
    angle *= rand() % 180;
    CGPoint vector = CGPointMake(position.x - lastPosition.x, position.y - lastPosition.y);
    CGFloat distance = hypotf(vector.x, vector.y);
    vector.x /= distance;
    vector.y /= distance;
    for (CGFloat i = 0; i < distance; i += 1.0f) {
        textureColor = [UIImage imageWithCGImage:[SSEffectProcessor rotateImage:self.brushImage angle:angle * -1]];
        CGPoint p = CGPointMake(lastPosition.x + i * vector.x, lastPosition.y + i * vector.y);
        p.x -= self.brushImage.size.width / 2.0f;
        p.y -= self.brushImage.size.height / 2.0f;
        [textureColor drawAtPoint:p blendMode:blendMode alpha:0.5f];
    }
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    self.imageView.image = image;
    UIGraphicsEndImageContext();
    lastPosition = position;
}

-(void)handleTouchesEnded {
    UIImage* image = self.imageView.image;
    if (!image) {
        return;
    }
    NSMutableArray<UIImage*>* stack = [self.undoStack mutableCopy];
    NSInteger stackCount = stack.count;
    if (self.stackIndex != stackCount - 1) {
        [stack removeObjectsInRange:NSMakeRange(self.stackIndex + 1, stackCount - (self.stackIndex + 1))];
    }
    [stack addObject:image];
    self->_undoStack = [stack copy];
    self->_stackIndex = self.undoStack.count - 1;
}

@end
