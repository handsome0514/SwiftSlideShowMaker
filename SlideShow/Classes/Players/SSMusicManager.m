//
//  SSMusicManager.m
//  SlideShow
//
//  Created by Arda Ozupek on 29.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSMusicManager.h"
#import "SSMusic.h"
#import <AFNetworking.h>

NSString* const SSMusicManagerDownloadFolderName = @"musics";

@implementation SSMusicManager

#pragma mark - Life Cycle
+(SSMusicManager*)sharedInstance {
    static SSMusicManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SSMusicManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self musicFolderPath]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        //[self initStockMusics];
    }
    return self;
}


#pragma mark - Stock Musics
-(void)initStockMusics {
    NSMutableArray<SSMusic*>* stockMusics = [[NSMutableArray alloc] init];
    
    NSArray* fileNames = @[@[@"7_rings", @"7 Rings", @(YES)],
                           @[@"baby_shark", @"Baby Shark", @(YES)],
                           @[@"fight_song", @"Fight Song", @(YES)],
                           @[@"girls_like_you", @"Girls Like You", @(YES)],
                           @[@"happier", @"Happier", @(YES)],
                           @[@"happy_birthday", @"Happy Birthday", @(YES)],
                           @[@"natural", @"Natural", @(YES)],
                           @[@"shallow", @"Shallow", @(YES)],
                           @[@"sucker", @"Sucker", @(YES)],
                           @[@"sunflower", @"Sunflower", @(YES)],
                           @[@"thank_you_next", @"Thank you, Next", @(YES)],
                           @[@"the_middle", @"The Middle", @(YES)],
                           @[@"without_me", @"Without Me", @(YES)],
                           @[@"wow", @"WOW", @(YES)]];
    
    for (NSArray* item in fileNames) {
        NSString* fileName = item[0];
        NSString* title = item[1];
        BOOL locked = [item[2] boolValue];
        NSString* path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"mp3"];
        NSAssert(path.length, @"Music file not found!");
        NSURL* url = [NSURL fileURLWithPath:path];
        SSMusic* music = [SSMusic localStockMusicWithURL:url title:title locked:locked];
        if (music) {
            [stockMusics addObject:music];
        }
    }
    
    NSString* jsonFilePath = [[NSBundle mainBundle] pathForResource:@"remotemusics" ofType:@"json"];
    NSData* jsonData = [NSData dataWithContentsOfFile:jsonFilePath];
    NSArray* remoteMusicsData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    for (NSArray* item in remoteMusicsData) {
        NSString* fileName = item[0];
        NSString* title = item[1];
        NSTimeInterval duration = [item[2] doubleValue];
        BOOL locked = [item[3] boolValue];
        
        SSMusic* music = nil;
        if ([self musicFileDownloaded:fileName]) {
            NSString* path = [[self musicFolderPath] stringByAppendingPathComponent:fileName];
            NSURL* url = [NSURL fileURLWithPath:path];
            music = [SSMusic localStockMusicWithURL:url title:title locked:locked];
        }
        else {
            NSString* path = [NSString stringWithFormat:@"http://104.131.250.165/Music/%@", fileName];
            path = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL* url = [NSURL URLWithString:path];
            music = [SSMusic remoteStockMusicWithURL:url title:title locked:locked duration:duration];
        }
        
        if (music) {
            [stockMusics addObject:music];
        }
    }
    
    self->_stockMusics = [stockMusics copy];
}

-(SSMusic*)findStockMusic:(NSString*)title {
    SSMusic* foundMusic = nil;
    for (SSMusic* music in self.stockMusics) {
        if ([music.title isEqualToString:title]) {
            foundMusic = music;
            break;
        }
    }
    return foundMusic;
}

-(void)downloadStockMusic:(SSMusic*)music progress:(void(^)(CGFloat))progress completion:(void(^)(BOOL))completion {
    NSAssert(music.isRemoteMusic, @"Given music is not local!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager* manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        NSURLRequest* request = [NSURLRequest requestWithURL:music.url];
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request
                                                                         progress:^(NSProgress * _Nonnull downloadProgress)
        {
            if (progress) {
                progress(downloadProgress.fractionCompleted);
            }
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSString* fileName = music.url.lastPathComponent;
            NSString* path = [[self musicFolderPath] stringByAppendingPathComponent:fileName];
            NSURL* downloadURL = [NSURL fileURLWithPath:path];
            return downloadURL;
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            BOOL succeed = (!error && filePath);
            if (succeed) {
                [music changeToLocal:filePath];
            }
            if (completion) {
                completion(succeed);
            }
        }];
        [downloadTask resume];
    });
}

-(BOOL)musicFileDownloaded:(NSString*)fileName {
    NSString* path = [[self musicFolderPath] stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

-(NSString*)musicFolderPath {
    NSString* path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    path = [path stringByAppendingPathComponent:SSMusicManagerDownloadFolderName];
    return path;
}


#pragma mark - Library Music
-(SSMusic*)findLibraryMusic:(MPMediaEntityPersistentID)mediaEntityId {
    MPMediaQuery* query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:mediaEntityId]
                                                               forProperty:MPMediaItemPropertyPersistentID
                                                            comparisonType:MPMediaPredicateComparisonEqualTo]];
    NSArray<MPMediaItem*>* results = query.items;
    MPMediaItem* mediaItem = results.firstObject;
    SSMusic* foundMusic = nil;
    for (SSMusic* music in self.libraryMusics) {
        if (music.mediaItem.persistentID == mediaItem.persistentID) {
            foundMusic = music;
            break;
        }
    }
    return foundMusic;
}

-(void)loadLibraryMusics:(void(^)(void))completion {
    __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        MPMediaQuery* query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithUnsignedInteger:MPMediaTypeMusic]
                                                                   forProperty:MPMediaItemPropertyMediaType]];
        
        NSArray<MPMediaItem*>* results = query.items;
        NSMutableArray<SSMusic*>* musics = [[NSMutableArray alloc] init];
        for (MPMediaItem* item in results) {
            SSMusic* music = [SSMusic libraryMusicWithMediaItem:item];
            if (music) {
                [musics addObject:music];
            }
        }
        NSSortDescriptor* sortByArtist = [NSSortDescriptor sortDescriptorWithKey:@"artist"
                                                                       ascending:YES
                                                                        selector:@selector(caseInsensitiveCompare:)];
        NSSortDescriptor* sortByAlbum = [NSSortDescriptor sortDescriptorWithKey:@"album"
                                                                      ascending:YES
                                                                       selector:@selector(caseInsensitiveCompare:)];
        NSSortDescriptor* sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                     ascending:YES
                                                                      selector:@selector(caseInsensitiveCompare:)];
        NSArray<SSMusic*>* sortedMusics = [musics sortedArrayUsingDescriptors:@[sortByArtist, sortByAlbum, sortByTitle]];
        SSMusicManager* sself = wself;
        sself->_libraryMusics = sortedMusics;
        if (completion) {
            completion();
        }
    });
}

-(void)handleMediaLibraryPermission:(UIViewController*)viewController completion:(void(^)(void))completion {
    __weak typeof(self) wself = self;
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus status = [MPMediaLibrary authorizationStatus];
        if (status == MPMediaLibraryAuthorizationStatusNotDetermined) {
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wself handleMediaLibraryPermission:viewController completion:completion];
                });
            }];
        } else if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
            if (completion) {
                completion();
            }
        } else {
            BOOL isRestricted = status == MPMediaLibraryAuthorizationStatusRestricted;
            NSString* msg = isRestricted ? @"You are not allowed to use media library of this device." : @"Media library access denided!";
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:msg
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            if (!isRestricted) {
                [alert addAction:[UIAlertAction actionWithTitle:@"Settings"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action)
                                  {
                                      NSURL* url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                      if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                          [[UIApplication sharedApplication] openURL:url];
                                      }
                                  }]];
            }
            [viewController presentViewController:alert animated:YES completion:nil];
        }
    } else {
        if (completion) {
            completion();
        }
    }
}

-(BOOL)didMediaLibraryPermissionGranted {
    if (@available(iOS 9.3, *)) {
        MPMediaLibraryAuthorizationStatus status = [MPMediaLibrary authorizationStatus];
        return status == MPMediaLibraryAuthorizationStatusAuthorized;
    } else {
        return YES;
    }
}

@end
