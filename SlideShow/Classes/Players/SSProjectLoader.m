//
//  SSProjectLoader.m
//  SlideShowMagic
//
//  Created by Arda Ozupek on 15.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectLoader.h"
#import "SSCore.h"

@implementation SSProjectLoader

#pragma mark - Life Cycle
+(SSProjectLoader *)loaderWithProjectId:(NSString *)projectId {
    NSString* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* projectFile = [NSString stringWithFormat:@"%@.ssd", projectId];
    NSString* projectFilePath = [documentsPath stringByAppendingPathComponent:projectFile];
    BOOL projectFileExists = [[NSFileManager defaultManager] fileExistsAtPath:projectFilePath];
    if (!projectFileExists) {
        return nil;
    }
    
    NSString* thumbnailFile = [NSString stringWithFormat:@"%@.jpg", projectId];
    NSString* thumbnailFilePath = [documentsPath stringByAppendingPathComponent:thumbnailFile];
    UIImage* thumbnail = [UIImage imageWithContentsOfFile:thumbnailFilePath];
    if (!thumbnail) {
        return nil;
    }
    
    SSProjectLoader* loader = [[SSProjectLoader alloc] init];
    loader->_projectId = projectId;
    loader->_createdTime = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"create_time_%@", projectId]];
    loader->_numberImage = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"number_image_%@", projectId]];
    loader->_projectFilePath = projectFilePath;
    loader->_thumbnail = thumbnail;
    
    return loader;
}


#pragma mark - Compare
-(BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    if ([object isMemberOfClass:[self class]]) {
        SSProjectLoader* loader = object;
        if ([loader.projectId isEqualToString:self.projectId]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Load
-(SSProject*)loadProject {
    NSData* data = [NSData dataWithContentsOfFile:self.projectFilePath];
    if (!data) {
        return nil;
    }
    SSProject* project = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return project;
}


#pragma mark - Save
+(SSProjectLoader*)saveProject:(SSProject*)project {
    NSAssert(project, @"Given project is nil!");
    
    NSData* projectData = [NSKeyedArchiver archivedDataWithRootObject:project];
    if (!projectData) {
        DLog(@"Failed to encode project!");
        return nil;
    }
    
    NSData* thumbData = UIImageJPEGRepresentation(project.imageItems.firstObject.rawThumbnail, 0.8f);
    if (!thumbData) {
        DLog(@"Couldn't encode thumbnail image!");
        return nil;
    }
    
    NSString* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* projectFile = [NSString stringWithFormat:@"%@.ssd", project.projectId];
    NSString* projectFilePath = [documentsPath stringByAppendingPathComponent:projectFile];
    if (![projectData writeToFile:projectFilePath atomically:YES]) {
        DLog(@"Couldn't write to file!");
        return nil;
    }
    
    NSString* thumbFile = [NSString stringWithFormat:@"%@.jpg", project.projectId];
    NSString* thumbFilePath = [documentsPath stringByAppendingPathComponent:thumbFile];
    if (![thumbData writeToFile:thumbFilePath atomically:YES]) {
        [[NSFileManager defaultManager] removeItemAtPath:projectFilePath error:nil];
        DLog(@"Coudn't write to file!");
        return nil;
    }
    
    SSProjectLoader* loader = [SSProjectLoader loaderWithProjectId:project.projectId];
    return loader;
}


#pragma mark - Path
-(NSString *)exportedVideoPath {
    NSString* documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* fileName = [NSString stringWithFormat:@"%@.mp4", self.projectId];
    NSString* filePath = [documentsPath stringByAppendingPathComponent:fileName];
    return filePath;
}


@end
