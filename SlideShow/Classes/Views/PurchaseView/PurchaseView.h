//
//  PurchaseView.h
//  SloMo Video - Speed Control
//
//  Created by Wang Gel on 5/11/20.
//  Copyright © 2020 Fourmi Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define IAPManagerGetEverythingId @"com.grassapper.slideshowmagic.geteverything"
#define IAPManagerUnlockTransitionsId @"com.grassapper.slideshowmagic.unlocktransitions"
#define IAPManagerUnlockMusicId @"com.grassapper.slideshowmagic.stockmusic"
#define IAPManagerUnlimitedPhotosId @"com.grassapper.slideshowmagic.unlockUnlimitedPhotos"
#define IAPManagerRemoveWatermarkId @"com.grassapper.slideshowmagic.removewatermark"
#define IAPManagerRemoveAdsId @"com.grassapper.slideshowmagic.removeads"

#define IAPManagerProMonthlyId @"com.grassapper.slideshowmagic.pro.1monthly"
#define IAPManagerProWeeklylyId @"com.grassapper.slideshowmagic.pro.1weekly"
#define IAPManagerProQuarterlyId @"com.grassapper.slideshowmagic.pro.3monthly"
#define IAPManagerProYearlyId @"com.grassapper.slideshowmagic.pro.yearly"

#define kProductsLoadedNotification         @"ProductsLoaded"
#define kProductPurchasedNotification       @"ProductPurchased"
#define kProductPurchaseFailedNotification  @"ProductPurchaseFailed"
#define kProductClosedNotification          @"ProductClosedFailed"

@interface PurchaseView : UIView

@property (nonatomic, strong) UIViewController *parentViewController;

+ (PurchaseView *)loadFromNib;
+ (PurchaseView *)showPurchaseView;

- (void)localizePrice;

@end

NS_ASSUME_NONNULL_END
