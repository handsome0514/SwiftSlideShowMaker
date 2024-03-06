//
//  SSVideoExporter.h
//  SlideShow
//
//  Created by Arda Ozupek on 15.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <GPUImage.h>

@class SSProject;

typedef void (^SSVideoExporterCompletionBlock)(BOOL succeed);
typedef void (^SSVideoExporterProgressBlock)(CGFloat progress);

NS_ASSUME_NONNULL_BEGIN

@interface SSVideoExporter : NSObject <GPUImageInput>
+(SSVideoExporter*)exporterWithProject:(SSProject*)project;
@property (nonatomic, strong, readonly) SSProject* project;
@property (nonatomic, assign, readonly, getter=isProcessing) BOOL processing;

-(void)exportWithCompletion:(SSVideoExporterCompletionBlock)completion progress:(SSVideoExporterProgressBlock)progress;
-(void)clear;
@end

NS_ASSUME_NONNULL_END
