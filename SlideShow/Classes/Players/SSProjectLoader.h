//
//  SSProjectLoader.h
//  SlideShowMagic
//
//  Created by Arda Ozupek on 15.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SSProject;

@interface SSProjectLoader : NSObject
+(SSProjectLoader*)loaderWithProjectId:(NSString*)projectId;
@property (nonatomic, copy, readonly) NSString* projectId;
@property (nonatomic, copy, readonly) NSString* projectFilePath;
@property (nonatomic, strong, readonly) UIImage* thumbnail;
@property (nonatomic, copy, readonly) NSString* exportedVideoPath;
@property (nonatomic, copy, readonly) NSString* createdTime;
@property NSInteger numberImage;

-(SSProject*)loadProject;
+(SSProjectLoader*)saveProject:(SSProject*)project;
@end
