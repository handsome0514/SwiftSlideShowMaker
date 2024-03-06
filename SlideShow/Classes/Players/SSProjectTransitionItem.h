//
//  SSProjectTransitionItem.h
//  SlideShow
//
//  Created by Arda Ozupek on 30.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectItem.h"
#import "SSTransition.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectTransitionItem : SSProjectItem <NSCopying, NSCoding>
+(SSProjectTransitionItem*)itemWithTransitionType:(SSTransitionType)type;
@property (nonatomic, assign) SSTransitionType selectedTransitionType;
@property (nonatomic, assign, readonly) SSTransitionType randomizedTransitionType;
@property (nonatomic, assign) BOOL shouldRandomizeTransition;
@property (nonatomic, assign) BOOL shouldUseAllTransitions;
@property (nonatomic, assign) SSTransitionType transitionType;
@end

NS_ASSUME_NONNULL_END
