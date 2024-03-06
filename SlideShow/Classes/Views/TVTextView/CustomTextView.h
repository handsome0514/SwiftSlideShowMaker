//
//  CustomTextView.h
//  PhotoInk
//
//  Created by Serg Shulga on 9/3/12.
//  Copyright (c) 2012 Prophonix. All rights reserved.
//

#ifndef ah_retain
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_dealloc self
#define release self
#define autorelease self
#else
#define ah_retain retain
#define ah_dealloc dealloc
#define __bridge
#endif
#endif

#import <UIKit/UIKit.h>

@interface CustomTextView : UITextView

@property (nonatomic, assign) CGFloat reflectionGap;
@property (nonatomic, assign) CGFloat reflectionScale;
@property (nonatomic, assign) CGFloat reflectionAlpha;
@property (nonatomic, retain) UIImageView *reflectionView;
@property (nonatomic, assign) BOOL dynamic;

@property (nonatomic, retain) UIColor* textBackgroundColor;

- (void) update;

@end
