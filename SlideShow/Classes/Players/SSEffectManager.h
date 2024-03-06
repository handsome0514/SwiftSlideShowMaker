//
//  SSEffectManager.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>
#import "SSTransition.h"
#import "SSProjectSettings.h"

@class SSPicture;
@class SSLookupTable;
@class SSTransition;
@class SSBrush;

NS_ASSUME_NONNULL_BEGIN

@interface SSEffectManager : NSObject
+(SSEffectManager*)sharedInstance;
@property (nonatomic, strong, readonly) NSArray<SSLookupTable*>* lookupTables;
@property (nonatomic, strong, readonly) NSArray<SSTransition*>* transitions;
@property (nonatomic, strong, readonly) NSArray<SSBrush*>* brushes;
-(NSInteger)indexOfTransitionType:(SSTransitionType)type;
-(SSTransitionType)transitionTypeAtIndex:(NSInteger)index;
-(NSInteger)randomLookupTableIndex;
-(SSTransitionType)randomTransitionType;
-(SSTransitionType)randomFreeTransitionType;
-(SSPicture*)createWatermark:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
