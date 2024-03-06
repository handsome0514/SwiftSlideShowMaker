//
//  SSProjectManager.h
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SSProject;
@class SSProjectLoader;

@interface SSProjectManager : NSObject
+(SSProjectManager*)sharedInstance;
@property (nonatomic, strong, readonly) NSArray<SSProjectLoader*>* loaders;
@property (nonatomic, strong, readonly) SSProject* currentProject;

-(SSProject*)createProject;
-(void)closeCurrentProject;
-(void)saveCurrentProject;
-(SSProject*)loadProject:(SSProjectLoader*)loader;
-(void)deleteLoader:(SSProjectLoader*)loader;
-(NSInteger)totalImage;
@end
