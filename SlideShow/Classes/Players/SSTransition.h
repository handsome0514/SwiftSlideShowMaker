//
//  SSTransition.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKey.h>

typedef NS_ENUM(NSInteger, SSTransitionType) {
    kSSTransitionTypeDirectional = 0,
    kSSTransitionTypeWindowSlice = 1,
    kSSTransitionTypeSimpleZoom = 2,
    kSSTransitionTypeLinearBlur = 3,
    kSSTransitionTypeWaterDrop = 4,
    kSSTransitionTypeInvertedPageCurl = 5,
    kSSTransitionTypeStereoViewer = 6,
    kSSTransitionTypeDirectionalWrap = 7,
    kSSTransitionTypeMorph = 8,
    kSSTransitionTypeCrossZoom = 9,
    kSSTransitionTypeDreamy = 10,
    kSSTransitionTypeCrosshatch = 11,
    kSSTransitionTypeButterflyWave = 12,
    kSSTransitionTypeKaleidoscope = 13,
    kSSTransitionTypeWindowBlinds = 14,
    kSSTransitionTypeGlitchDisplace = 15,
    kSSTransitionTypeDreamyZoom = 16,
    kSSTransitionTypeRipple = 17,
    kSSTransitionTypeBurn = 18,
    kSSTransitionTypeCircle = 19,
    kSSTransitionTypeColorPhase = 20,
    kSSTransitionTypeCrosswrap = 21,
    kSSTransitionTypeDoorway = 22,
    kSSTransitionTypeFlyeye = 23,
    kSSTransitionTypeHeart = 24,
    kSSTransitionTypeRotateScaleFade = 25,
    kSSTransitionTypeWind = 26,
    kSSTransitionCount = 27
};

NS_ASSUME_NONNULL_BEGIN

@interface SSTransition : NSObject
+(SSTransition *)transitionWithType:(SSTransitionType)type locked:(BOOL)locked;
@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, assign, readonly) SSTransitionType type;
@property (nonatomic, assign, readonly, getter=isLocked) BOOL locked;

-(void) transtion:(NSString*)view;
@end

NS_ASSUME_NONNULL_END
