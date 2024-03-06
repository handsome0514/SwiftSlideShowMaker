//
//  SSLookupTable.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <GPUImage.h>

@class SSPicture;

NS_ASSUME_NONNULL_BEGIN

@interface SSLookupTable : NSObject
+(SSLookupTable*)lookupTableWithFile:(NSString*)file andName:(NSString*)name;
@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, strong, readonly) SSPicture* picture;
@end

NS_ASSUME_NONNULL_END
