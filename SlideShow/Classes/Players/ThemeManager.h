//
//  ThemeManager.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThemeManager : NSObject
+(ThemeManager*)sharedInstance;
@property (nonatomic, strong, readonly) UIColor* purpleColor;
@property (nonatomic, strong, readonly) UIColor* pinkColor;
@property (nonatomic, strong, readonly) UIColor* redColor;
@property (nonatomic, strong, readonly) UIColor* grayColor;
@property (nonatomic, strong, readonly) UIColor* lightGrayColor;
@property (nonatomic, strong, readonly) UIImage* pinkImage;
@property (nonatomic, strong, readonly) UIImage* grayImage;

@property (nonatomic, strong, readonly) NSArray<UIFont*>* fonts;
@property (nonatomic, strong, readonly) NSArray<UIColor*>* colors;

@property (nonatomic, strong, readonly) NSArray<NSDictionary*>* themes;

@end

NS_ASSUME_NONNULL_END
