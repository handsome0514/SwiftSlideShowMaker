//
//  SSProjectSettings.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectSettings : NSObject <NSCopying, NSCoding>
@property (nonatomic, assign) SSOutputRatio outputRatio;
@property (nonatomic, assign) SSDurationType durationType;
@property (nonatomic, assign) NSTimeInterval fixedPhotoDuration;
@property (nonatomic, assign) NSTimeInterval fixedTransitionDuration;
@property (nonatomic, assign) NSTimeInterval fixedTotalDuration;

@property (nonatomic, assign, readonly) CGSize outputSize;
@end

NS_ASSUME_NONNULL_END
