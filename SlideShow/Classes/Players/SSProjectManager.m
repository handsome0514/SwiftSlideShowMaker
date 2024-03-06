//
//  SSProjectManager.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSProjectManager.h"
#import "SSCore.h"

NSString* const SSProjectManagerProjectsKey = @"projects";

@implementation SSProjectManager

#pragma mark - Life Cycle
+(SSProjectManager *)sharedInstance {
    static SSProjectManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SSProjectManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [self loadCachedProjects];
    }
    return self;
}


#pragma mark - Persistence
-(void)loadCachedProjects {
    NSArray<NSString*>* projectIdentifiers = [[NSUserDefaults standardUserDefaults] objectForKey:SSProjectManagerProjectsKey];
    NSMutableArray<SSProjectLoader*>* loaders = [[NSMutableArray alloc] init];
    for (NSString* identifier in projectIdentifiers) {
        SSProjectLoader* loader = [SSProjectLoader loaderWithProjectId:identifier];
        if (loader) {
            [loaders addObject:loader];
        }
    }
    self->_loaders = [loaders copy];
}


#pragma mark - New Project
-(SSProject *)createProject {
    NSAssert(!self.currentProject, @"Current project is not closed!");
    SSProject* project = [SSProject project];
    NSAssert(project, @"Couldn't create project!");
    _currentProject = project;
    return self.currentProject;
}

-(void)closeCurrentProject {
    NSAssert(self.currentProject, @"Current project is nil!");
    _currentProject = nil;
    [[GPUImageContext sharedFramebufferCache] purgeAllUnassignedFramebuffers];
}

-(void)saveCurrentProject {
    NSAssert(self.currentProject, @"Current project is nil!");
    SSProjectLoader* loader = [SSProjectLoader saveProject:self.currentProject];
    NSMutableArray<SSProjectLoader*>* loaders = [self.loaders mutableCopy];
    NSInteger index = [loaders indexOfObject:loader];
    if (index == NSNotFound) {
        [loaders addObject:loader];
    }
    else {
        [loaders replaceObjectAtIndex:index withObject:loader];
    }
    self->_loaders = [loaders copy];
    [self synchronizeProjectIdentifiers];
}


#pragma mark - Persist
-(void)synchronizeProjectIdentifiers {
    NSMutableArray<NSString*>* projectIdentifiers = [[NSMutableArray alloc] init];
    for (SSProjectLoader* projectLoader in self.loaders) {
        [projectIdentifiers addObject:projectLoader.projectId];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[projectIdentifiers copy] forKey:SSProjectManagerProjectsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Loader
-(SSProject*)loadProject:(SSProjectLoader*)loader {
    NSAssert(!self.currentProject, @"Current project must be nil!");
    SSProject* project = [loader loadProject];
    if (project) {
        _currentProject = project;
    }
    return self.currentProject;
}

-(void)deleteLoader:(SSProjectLoader *)loader {
    NSAssert(loader, @"Given loader is nil!");
    NSAssert(![loader.projectId isEqualToString:self.currentProject.projectId], @"Given project is already loaded!");
    NSMutableArray<SSProjectLoader*>* loaders = [self.loaders mutableCopy];
    [loaders removeObject:loader];
    self->_loaders = [loaders copy];
    [self synchronizeProjectIdentifiers];
}

-(NSInteger)totalImage {
    NSArray *loaders = [SSProjectManager sharedInstance].loaders;
    NSInteger count = 0;
    for (SSProjectLoader *loader in loaders) {
        count += [loader numberImage];
    }
    return count;
}
@end
