//
//  SSLookupFilter.h
//  SlideShow
//
//  Created by Arda Ozupek on 11.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface SSLookupFilter : GPUImageTwoInputFilter
@property (nonatomic, assign) CGFloat intensity;
@end

NS_ASSUME_NONNULL_END
