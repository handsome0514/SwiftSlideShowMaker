//
//  SSLookupTable.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSLookupTable.h"
#import "SSCore.h"

@implementation SSLookupTable

#pragma mark - Life Cycle
+(SSLookupTable *)lookupTableWithFile:(NSString *)file andName:(NSString *)name {
    NSAssert(file && name, @"Invalid arguments!");
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:file ofType:@"png"]];
    NSAssert(url, @"Invalid url for lut file!");
    SSPicture* picture = [[SSPicture alloc] initWithURL:url];
    NSAssert(picture, @"Internal inconsistency!");
    SSLookupTable* lut = [[SSLookupTable alloc] init];
    lut->_name = name;
    lut->_picture = picture;
    return lut;
}

@end
