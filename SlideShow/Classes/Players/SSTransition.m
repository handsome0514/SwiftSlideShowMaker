//
//  SSTransition.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSTransition.h"
#import "SSEffectManager.h"

@implementation SSTransition

#pragma mark - Life Cycle
+(SSTransition *)transitionWithType:(SSTransitionType)type locked:(BOOL)locked {
    SSTransition* transition = [[SSTransition alloc] init];
    transition->_type = type;
    transition->_name = [SSTransition nameForType:transition.type];
    transition->_locked = locked;
    return transition;
}


#pragma mark - Name
+(NSString*)nameForType:(SSTransitionType)type {
    NSString* name = @"";
    if (type == kSSTransitionTypeDirectional) {
        name = @"Directional";
    }
    else if (type == kSSTransitionTypeSimpleZoom) {
        name = @"Simple Zoom";
    }
    else if (type == kSSTransitionTypeWindowSlice) {
        name = @"Window Slice";
    }
    else if (type == kSSTransitionTypeDirectionalWrap) {
        name = @"Directional Wrap";
    }
    else if (type == kSSTransitionTypeMorph) {
        name = @"Morph";
    }
    else if (type == kSSTransitionTypeLinearBlur) {
        name = @"Linear Blur";
    }
    else if (type == kSSTransitionTypeStereoViewer) {
        name = @"Stereo Viewer";
    }
    else if (type == kSSTransitionTypeWaterDrop) {
        name = @"Water Drop";
    }
    else if (type == kSSTransitionTypeInvertedPageCurl) {
        name = @"Inverted Page Curl";
    }
    else if (type == kSSTransitionTypeButterflyWave) {
        name = @"Butterfly Wave";
    }
    else if (type == kSSTransitionTypeWindowBlinds) {
        name = @"Window Blinds";
    }
    else if (type == kSSTransitionTypeHeart) {
        name = @"Heart";
    }
    else if (type == kSSTransitionTypeCrosshatch) {
        name = @"Crosshatch";
    }
    else if (type == kSSTransitionTypeCrossZoom) {
        name = @"Cross Zoom";
    }
    else if (type == kSSTransitionTypeDreamy) {
        name = @"Dreamy";
    }
    else if (type == kSSTransitionTypeKaleidoscope) {
        name = @"Kaleidoscope";
    }
    else if (type == kSSTransitionTypeGlitchDisplace) {
        name = @"Glitch Displace";
    }
    else if (type == kSSTransitionTypeDreamyZoom) {
        name = @"Dreamy Zoom";
    }
    else if (type == kSSTransitionTypeRipple) {
        name = @"Ripple";
    }
    else if (type == kSSTransitionTypeCircle) {
        name = @"Circle";
    }
    else if (type == kSSTransitionTypeColorPhase) {
        name = @"Color Phase";
    }
    else if (type == kSSTransitionTypeCrosswrap) {
        name = @"Crosswrap";
    }
    else if (type == kSSTransitionTypeDoorway) {
        name = @"Doorway";
    }
    else if (type == kSSTransitionTypeRotateScaleFade) {
        name = @"Rotate Scale Fade";
    }
    else if (type == kSSTransitionTypeWind) {
        name = @"Wind";
    }
    else if (type == kSSTransitionTypeBurn) {
        name = @"Burn";
    }
    else if (type == kSSTransitionTypeFlyeye) {
        name = @"Flyeye";
    }
    
    return name;
}

-(void) transition:(UIView*)currentView {
    // remove the current view and replace with myView1
    CATransition *trans = [CATransition animation];
    trans.duration = 1.5;
    trans.type = kCATransitionMoveIn;
    trans.subtype = kCATransitionFromLeft;

    [currentView.layer addAnimation:trans forKey:nil];

    [currentView removeFromSuperview];
}
@end
