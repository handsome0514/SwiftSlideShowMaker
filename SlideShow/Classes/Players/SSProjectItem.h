//
//  SSProjectItem.h
//  SlideShow
//
//  Created by Arda Ozupek on 30.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSProjectItem : NSObject  <NSCopying>
{
    @protected
    NSString* _itemId;
    NSTimeInterval _duration;
}
@property (nonatomic, copy, readonly) NSString* itemId;
@property (nonatomic, assign) NSTimeInterval duration;
@end

NS_ASSUME_NONNULL_END
