//
//  SSEffectManager.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSEffectManager.h"
#import <GPUImage.h>
#import "SSCore.h"
#import "Slideshow-Swift.h"

@interface SSEffectManager()

@end

@implementation SSEffectManager

#pragma mark - Life Cycle
+(SSEffectManager *)sharedInstance {
    static SSEffectManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SSEffectManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self initLUTs];
        [self initTransitions];
        [self initBrushes];
    }
    return self;
}


#pragma mark - LUT
-(void)initLUTs {
    NSMutableArray<SSLookupTable*>* lookupTables = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<=18; i++) {
        NSString* file = [NSString stringWithFormat:@"filter_%ld", i];
        NSString* name = i ? [NSString stringWithFormat:@"Filter %ld", i] : @"None";
        SSLookupTable* lut = [SSLookupTable lookupTableWithFile:file andName:name];
        NSAssert(lut, @"Internal inconsistency!");
        [lookupTables addObject:lut];
    }
    self->_lookupTables = lookupTables;
}


#pragma mark - Transitions
-(void)initTransitions {
    NSMutableArray<SSTransition*>* transitions = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<kSSTransitionCount; i++) {
        [transitions addObject:[SSTransition transitionWithType:i locked:i >= 8]];
    }
    self->_transitions = [transitions copy];
}

-(NSInteger)indexOfTransitionType:(SSTransitionType)type {
    NSInteger index = 0;
    for (NSInteger i=0; i<self.transitions.count; i++) {
        if (self.transitions[i].type == type) {
            index = i;
            break;
        }
    }
    return index;
}

-(SSTransitionType)transitionTypeAtIndex:(NSInteger)index {
    return self.transitions[index].type;
}


#pragma mark - Brushes
-(void)initBrushes {
    NSMutableArray<SSBrush*>* brushes = [[NSMutableArray alloc] init];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeCircle]];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeGlow]];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeSparkles]];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeBlur]];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeScratch]];
    [brushes addObject:[SSBrush brushWithType:kSSBrushTypeAngled]];
    self->_brushes = [brushes copy];
}


#pragma mark - Random
-(SSLookupTable *)randomLookupTable {
    NSInteger index = arc4random() % self.lookupTables.count;
    return self.lookupTables[index];
}

-(NSInteger)randomLookupTableIndex {
    return arc4random() % self.lookupTables.count;
}

-(SSTransitionType)randomTransitionType {
    NSInteger count = self.transitions.count;
    NSInteger index = arc4random() % count;
    return self.transitions[index].type;
}

-(SSTransitionType)randomFreeTransitionType {
    NSMutableArray<SSTransition*>* freeTransitions = [[NSMutableArray alloc] init];
    for (SSTransition* transition in self.transitions) {
        if (!transition.isLocked) {
            [freeTransitions addObject:transition];
        }
    }
    NSInteger count = freeTransitions.count;
    NSInteger index = arc4random() % count;
    return freeTransitions[index].type;
}


#pragma mark - Watermark
-(SSPicture*)createWatermark:(CGSize)size {
    UIView* view = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, size}];
    view.backgroundColor = [UIColor clearColor];
    view.opaque = NO;
    UIImageView* imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"watermark.png"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = [UIColor clearColor];
    
    CGFloat watermarkWidth = size.width * 200.0f / 1280.0f;
    CGSize watermarkSize = CGSizeMake(watermarkWidth, watermarkWidth);
    
    CGFloat margin = size.width * 10.0f / 1280.0f;
    imageView.frame = CGRectMake(view.bounds.size.width - watermarkSize.width - margin,
                                 view.bounds.size.height - watermarkSize.height - margin,
                                 watermarkSize.width,
                                 watermarkSize.height);
    [view addSubview:imageView];
    UIImage* image = [SSEffectProcessor imageFromView:view scale:1.0f opaque:NO];
    SSPicture* picture = [[SSPicture alloc] initWithImage:image];
    return picture;
}

@end
