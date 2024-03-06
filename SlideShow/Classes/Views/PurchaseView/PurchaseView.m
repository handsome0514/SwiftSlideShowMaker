//
//  PurchaseView.m
//  SloMo Video - Speed Control
//
//  Created by Wang Gel on 5/11/20.
//  Copyright © 2020 Fourmi Studio. All rights reserved.
//

#import "PurchaseView.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <StoreKit/StoreKit.h>
#import "SlideShow-Swift.h"
#import <SwiftColor-Swift.h>
#import <UIColor_Hex_Swift-Swift.h>
#import <MASegmentedControl.h>

static PurchaseView *purchaseView = nil;

@interface PurchaseView ()
{
    IBOutlet UIImageView *backgroundImageView;
    IBOutlet UIView *weekView;
    IBOutlet UIView *monthView;
    IBOutlet UIView *yearView;
    IBOutlet UILabel *monthLabel;
    IBOutlet UIButton *closeButton;
    IBOutlet UIButton *purchaseButton;
    IBOutlet UIImageView *checkImageView;
    IBOutlet UILabel *welcomLabel;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *priceLabel;
    
    IBOutlet NSLayoutConstraint *topTryConstraint;
    IBOutlet NSLayoutConstraint *topPrivacyConstraint;
    IBOutlet NSLayoutConstraint *topPricesConstraint;
    IBOutlet NSLayoutConstraint *topCarouselConstraint;
    IBOutlet NSLayoutConstraint *widthLogoConstraint;
    IBOutlet NSLayoutConstraint *heightLogoConstraint;
    IBOutlet NSLayoutConstraint *widthContentConstraint;
    IBOutlet NSLayoutConstraint *leadingContinueConstraint;
    IBOutlet NSLayoutConstraint *topDescConstraint;
            
    NSString *selectedIdentifier;
    
    BOOL isSelected;
    
    NSTimer *carouselTimer;
    NSInteger currentItemIndex;
}

@end

@implementation PurchaseView

+ (PurchaseView *)loadFromNib {
    NSString *nibName = @"PurchaseView";
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        nibName = @"PurchaseView_iPad";
    }
    return (PurchaseView *)[[[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil] firstObject];
}

+ (PurchaseView *)showPurchaseView {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (purchaseView == nil) {
        purchaseView = [PurchaseView loadFromNib];;
    }
    purchaseView.frame = [UIScreen mainScreen].bounds;
    purchaseView.alpha = 0.0;
    [keyWindow addSubview:purchaseView];
    [UIView animateWithDuration:0.3 animations:^{
        purchaseView.alpha = 1.0;
    }];
    [purchaseView localizePrice];
    [purchaseView layoutIfNeeded];
    [purchaseView selectView:1];
    
    NSArray *itemArray = [NSArray arrayWithObjects: @"Weekly", @"Yearly", nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(35, 200, 250, 50);
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents: UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 1;
    [purchaseView addSubview:segmentedControl];
    
    return purchaseView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidPurchaseNotification:) name:kProductPurchasedNotification object:nil];
    
    [purchaseButton addShadows:0.2 :[UIColor lightGrayColor] :30.0];
        
    CGRect bounds = [UIScreen mainScreen].bounds;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        if (bounds.size.height <= 568) {
            widthLogoConstraint.constant = 48;
            heightLogoConstraint.constant = 48;
            topDescConstraint.constant = -4;
            UIView *view = [self viewWithTag:1000];
            for (UILabel *label in view.subviews) {
                if ([label isKindOfClass:[UILabel class]]) {
                    label.font = [label.font fontWithSize:label.font.pointSize - 2];
                }
            }
            for (int i = 1; i <= 3; i++) {
                UIView *view = [self viewWithTag:i * 100];
                for (NSLayoutConstraint *constraint in view.constraints) {
                    if (constraint.constant == 2) {
                        constraint.constant = -2;
                    } else {
                        constraint.constant = 0;
                    }
                }
                UILabel *label = [view viewWithTag:i * 100 + 1];
                label.font = [label.font fontWithSize:label.font.pointSize - 4];
                label = [view viewWithTag:i * 100 + 3];
                label.font = [label.font fontWithSize:label.font.pointSize - 2];
                label = [view viewWithTag:i * 100 + 5];
                label.font = [label.font fontWithSize:label.font.pointSize - 4];
            }
            purchaseButton.titleLabel.font = [purchaseButton.titleLabel.font fontWithSize:purchaseButton.titleLabel.font.pointSize - 4];
        } else if (bounds.size.height <= 667) {
            topTryConstraint.constant = 12;
            topPrivacyConstraint.constant = 8;
            topPricesConstraint.constant = 16;
            topCarouselConstraint.constant = 24;
            topDescConstraint.constant = -8;
        } else if (bounds.size.width >= 414) {
        for (int i = 1; i <= 3; i++) {
            UIView *view = [self viewWithTag:i * 100];
            for (NSLayoutConstraint *constraint in view.constraints) {
                if (constraint.constant == 2) {
                    constraint.constant = 4;
                    } else if (constraint.constant == 4) {
                    constraint.constant = 8;
                    }
                }
                UILabel *label = [view viewWithTag:i * 100 + 1];
                label.font = [label.font fontWithSize:label.font.pointSize + 2];
                label = [view viewWithTag:i * 100 + 3];
                label.font = [label.font fontWithSize:label.font.pointSize + 1];
                label = [view viewWithTag:i * 100 + 5];
                label.font = [label.font fontWithSize:label.font.pointSize + 2];
            }
        }
        if (bounds.size.height <= 667 || (bounds.size.width == 414 && bounds.size.height == 736)) {
            //backgroundImageView.image = [UIImage imageNamed:@"IAPBackground6"];
        } else {
            //backgroundImageView.image = [UIImage imageNamed:@"IAPBackground"];
        }
    } else {
        if (bounds.size.width >= 1024) {
            widthLogoConstraint.constant = 148;
            heightLogoConstraint.constant = 148;
            widthContentConstraint.constant = 560;
            welcomLabel.font = [welcomLabel.font fontWithSize:welcomLabel.font.pointSize + 16];
            titleLabel.font = [titleLabel.font fontWithSize:titleLabel.font.pointSize + 16];
            UIView *view = [self viewWithTag:1000];
            for (UILabel *label in view.subviews) {
                if ([label isKindOfClass:[UILabel class]]) {
                    label.font = [label.font fontWithSize:label.font.pointSize + 6];
                    for (NSLayoutConstraint *constraint in label.constraints) {
                        if (constraint.constant == 22) {
                            constraint.constant = 32;
                        }
                    }
                }
            }
            for (int i = 1; i <= 3; i++) {
                UIView *view = [self viewWithTag:i * 100];
                for (NSLayoutConstraint *constraint in view.constraints) {
                    if (constraint.constant == 8) {
                        constraint.constant = 20;
                    } else if (constraint.constant == 6) {
                        constraint.constant = 16;
                    }
                }
                UILabel *label = [view viewWithTag:i * 100 + 1];
                label.font = [label.font fontWithSize:label.font.pointSize + 12];
                label = [view viewWithTag:i * 100 + 3];
                label.font = [label.font fontWithSize:label.font.pointSize + 8];
                label = [view viewWithTag:i * 100 + 5];
                label.font = [label.font fontWithSize:label.font.pointSize + 12];
            }
            purchaseButton.titleLabel.font = [purchaseButton.titleLabel.font fontWithSize:purchaseButton.titleLabel.font.pointSize + 8];
            leadingContinueConstraint.constant += 48;
        }
    }
    
    isSelected = NO;
    selectedIdentifier = IAPManagerProWeeklylyId;
    
    weekView.layer.borderColor = [[UIColor alloc] initWithRgba_throws:@"#7758B5" error:nil].CGColor;
    [weekView addShadows:0.1 :[UIColor lightGrayColor] :24.0];
    UIImageView *imageView = [weekView viewWithTag:104];
    imageView.image = [UIImage imageNamed:@"check"];
    monthView.layer.borderColor = [UIColor whiteColor].CGColor;
    yearView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    [self selectView:1];
    
    currentItemIndex = 0;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self layoutIfNeeded];
    
    if (isSelected == NO) {
        [self selectView:1];
        isSelected = YES;
    }
}

- (void)handleDidPurchaseNotification:(NSNotification *)notification {
    [self closeButtonPressed:nil];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)isIPhoneX {
    CGFloat height = [UIScreen mainScreen].nativeBounds.size.height;
    return height == 2436 || height == 2688 || height == 1792;
}

- (void)localizePrice {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    for (SKProduct *product in [PurchaseManager sharedManager].products) {
        if ([product.productIdentifier isEqualToString:IAPManagerProWeeklylyId]) {
            formatter.locale = product.priceLocale;
            UILabel *label = [self viewWithTag:103];
            label.text = [NSString stringWithFormat:@"%@", [formatter stringFromNumber:product.price]];
        } else if ([product.productIdentifier isEqualToString:IAPManagerProMonthlyId]) {
            formatter.locale = product.priceLocale;
            UILabel *label = [self viewWithTag:203];
            label.text = [NSString stringWithFormat:@"%@", [formatter stringFromNumber:product.price]];
        } else if ([product.productIdentifier isEqualToString:IAPManagerProYearlyId]) {
            formatter.locale = product.priceLocale;
            UILabel *label = [self viewWithTag:303];
            label.text = [NSString stringWithFormat:@"%@", [formatter stringFromNumber:product.price]];
        }
    }
}

- (void)selectView:(int)index {
    for (int i = 1; i <= 3; i++) {
        if (i != index) {
            UIView *view = [self viewWithTag:i * 100];
            view.layer.borderColor = [UIColor whiteColor].CGColor;
            view.backgroundColor = [UIColor whiteColor];
            [view addShadows:0.0 :[UIColor lightGrayColor] :24.0];
            UIImageView *imageView = [view viewWithTag:i * 100 + 4];
            imageView.image = [UIImage imageNamed:@"uncheck"];
        }
    }
    
    UILabel *label = [self viewWithTag:index * 100 + 3];
    if (index == 1) {
        priceLabel.text = [NSString stringWithFormat:@"7 days then %@ per week", label.text];
    } else if (index == 2) {
        priceLabel.text = [NSString stringWithFormat:@"7 days then %@ per month", label.text];
    } else {
        priceLabel.text = [NSString stringWithFormat:@"7 days then %@ per year", label.text];
    }
}

#pragma mark - IBAction

- (IBAction)purchaseButtonPressed:(UIButton *)sender {
    [SVProgressHUD show];
    [[PurchaseManager sharedManager] purchaseWithProductId:selectedIdentifier];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"ProductPurchased" object:nil];
}

- (IBAction)selectButtonPressed:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
            selectedIdentifier = IAPManagerProWeeklylyId;
            break;
            
        case 2:
            selectedIdentifier = IAPManagerProMonthlyId;
            break;
            
        case 3:
            selectedIdentifier = IAPManagerProYearlyId;
            break;
            
        default:
            break;
    }
    [self selectView:(int)sender.tag];
}

- (IBAction)restoreButtonPressed:(UIButton *)sender {
    [SVProgressHUD show];
    [[PurchaseManager sharedManager] restore];
}

- (IBAction)termsButtonPressed:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@""] options:@{} completionHandler:^(BOOL success) {
        
    }];
}

- (IBAction)privacyButtonPressed:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@""] options:@{} completionHandler:^(BOOL success) {
        
    }];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        //[self stopCarouselTimer];
        [self removeFromSuperview];
        [[NSNotificationCenter defaultCenter] postNotificationName:kProductClosedNotification object:nil];
    }];
}

- (IBAction)infoButtonPressed:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"SubscriptionViewController"];
    //controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.parentViewController presentViewController:controller animated:YES completion:nil];
}

@end
