//
//  SSLabel.m
//  SlideShowMagic
//
//  Created by Arda Ozupek on 16.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSLabel.h"

@implementation SSLabel

-(void)drawTextInRect:(CGRect)rect {
    UIEdgeInsets myLabelInsets = UIEdgeInsetsMake(20, 20, 20, 20);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, myLabelInsets)];
}

@end
