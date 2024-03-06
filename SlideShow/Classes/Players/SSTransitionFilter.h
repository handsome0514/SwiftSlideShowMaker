//
//  SSTransitionFilter.h
//  SlideShow
//
//  Created by Arda Ozupek on 25.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"
#import "SSTransition.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSTransitionFilter : GPUImageTwoInputFilter
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) SSTransitionType type;
@property (nonatomic, assign) CGFloat ratio;
@end

NS_ASSUME_NONNULL_END
