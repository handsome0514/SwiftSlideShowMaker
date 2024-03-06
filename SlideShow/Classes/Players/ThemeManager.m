//
//  ThemeManager.m
//  SlideShow
//
//  Created by Arda Ozupek on 24.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "ThemeManager.h"
#import "SSCore.h"
@implementation ThemeManager

#pragma mark - Life Cycle
+(ThemeManager *)sharedInstance {
    static ThemeManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ThemeManager alloc] init];
    });
    return instance;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        _purpleColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
        _pinkColor = [UIColor colorWithRed:20.0f/255.0f green:20.0f/255.0f blue:20.0f/255.0f alpha:1.0];
        _redColor = [UIColor colorWithRed:249.0f/255.0f green:57.0f/255.0f blue:74.0f/255.0f alpha:1.0];
        _grayColor = [UIColor colorWithRed:0.62 green:0.62 blue:0.62 alpha:1.0];
        _lightGrayColor = [UIColor colorWithRed:0.74 green:0.74 blue:0.74 alpha:1.0];
        _pinkImage = [self imageWithColor:self.pinkColor];
        _grayImage = [self imageWithColor:self.grayColor];
        [self initFontList];
        [self initColorList];
        [self initThemeList];
    }
    return self;
}


#pragma mark - Fonts
-(void)initFontList {
    NSMutableArray<UIFont*>* fonts = [[NSMutableArray alloc] init];
    CGFloat fontSize = 13.0f;
    [fonts addObject:[UIFont fontWithName:@"Andes" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Arial-Black" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"ArialMT" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"BacktoBlackDemo" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"BodoniFLF-Roman" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Bisous" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Blacksword" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"BradleyHandITCTT-Bold" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"BrushScriptStd" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"DINAlternate-Bold" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Futura-Medium" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Georgia-Bold" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"GillSans" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"GlossAndBloom" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Jellyka---le-Grand-Saut-Textual" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"HighTide" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"JellykaCuttyCupcakes" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"KaushanScript-Regular" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"lazer84" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"DKLemonYellowSun" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Limelight-Regular" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Montserrat-ExtraLight" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"MyriadPro-CondIt" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"NuevaStd-CondItalic" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"On-Air-Inline" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Phosphate-Inline" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Pristina-Regular" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"Roboto-Thin" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"RoundedElegance-Regular" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"SFProDisplay-Light" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"SavoyeLetPlain" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"SignPainter-HouseScript" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"SkarpaLT" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"DKSleepyTime" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"SnellRoundhand" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"StencilStd" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"TimesNewRomanPSMT" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"TypoRound-LightItalicDemo" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"VCROSDMono" size:fontSize]];
    [fonts addObject:[UIFont fontWithName:@"VertigoFLF" size:fontSize]];
    self->_fonts = [fonts copy];
}


#pragma mark - Colors
-(void)initColorList {
    NSMutableArray<UIColor*>* colors = [[NSMutableArray alloc] init];
    NSArray* hexColors = @[@"0xFFF0F8FF", @"0xFFFAEBD7", @"0xFF00FFFF", @"0xFF7FFFD4", @"0xFFF0FFFF", @"0xFFF5F5DC", @"0xFFFFE4C4", @"0xFF000000", @"0xFFFFEBCD", @"0xFF0000FF", @"0xFF8A2BE2", @"0xFFA52A2A", @"0xFFDEB887", @"0xFF5F9EA0", @"0xFF7FFF00", @"0xFFD2691E", @"0xFFFF7F50", @"0xFF6495ED", @"0xFFFFF8DC", @"0xFFDC143C", @"0xFF00FFFF", @"0xFF00008B", @"0xFF008B8B", @"0xFFB8860B", @"0xFFA9A9A9", @"0xFF006400", @"0xFFBDB76B", @"0xFF8B008B", @"0xFF556B2F", @"0xFFFF8C00", @"0xFF9932CC", @"0xFF8B0000", @"0xFFE9967A", @"0xFF8FBC8F", @"0xFF483D8B", @"0xFF2F4F4F", @"0xFF00CED1", @"0xFF9400D3", @"0xFFFF1493", @"0xFF00BFFF", @"0xFF696969", @"0xFF1E90FF", @"0xFFB22222", @"0xFFFFFAF0", @"0xFF228B22", @"0xFFFF00FF", @"0xFFDCDCDC", @"0xFFF8F8FF", @"0xFFFFD700", @"0xFFDAA520", @"0xFF808080", @"0xFF008000", @"0xFFADFF2F", @"0xFFF0FFF0", @"0xFFFF69B4", @"0xFFCD5C5C", @"0xFF4B0082", @"0xFFFFFFF0", @"0xFFF0E68C", @"0xFFE6E6FA", @"0xFFFFF0F5", @"0xFF7CFC00", @"0xFFFFFACD", @"0xFFADD8E6", @"0xFFF08080", @"0xFFE0FFFF", @"0xFFFAFAD2", @"0xFFD3D3D3", @"0xFF90EE90", @"0xFFFFB6C1", @"0xFFFFA07A", @"0xFF20B2AA", @"0xFF87CEFA", @"0xFF778899", @"0xFFB0C4DE", @"0xFFFFFFE0", @"0xFF00FF00", @"0xFF32CD32", @"0xFFFAF0E6", @"0xFFFF00FF", @"0xFF800000", @"0xFF66CDAA", @"0xFF0000CD", @"0xFFBA55D3", @"0xFF9370DB", @"0xFF3CB371", @"0xFF7B68EE", @"0xFF00FA9A", @"0xFF48D1CC", @"0xFFC71585", @"0xFF191970", @"0xFFF5FFFA", @"0xFFFFE4E1", @"0xFFFFE4B5", @"0xFFFFDEAD", @"0xFF000080", @"0xFFFDF5E6", @"0xFF808000", @"0xFF6B8E23", @"0xFFFFA500", @"0xFFFF4500", @"0xFFDA70D6", @"0xFFEEE8AA", @"0xFF98FB98", @"0xFFAFEEEE", @"0xFFDB7093", @"0xFFFFEFD5", @"0xFFFFDAB9", @"0xFFCD853F", @"0xFFFFC0CB", @"0xFFDDA0DD", @"0xFFB0E0E6", @"0xFF800080", @"0xFFFF0000", @"0xFFBC8F8F", @"0xFF4169E1", @"0xFF8B4513", @"0xFFFA8072", @"0xFFF4A460", @"0xFF2E8B57", @"0xFFFFF5EE", @"0xFFA0522D", @"0xFFC0C0C0", @"0xFF87CEEB", @"0xFF6A5ACD", @"0xFF708090", @"0xFFFFFAFA", @"0xFF00FF7F", @"0xFF4682B4", @"0xFFD2B48C", @"0xFF008080", @"0xFFD8BFD8", @"0xFFFF6347", @"0xFF40E0D0", @"0xFFEE82EE", @"0xFFF5DEB3", @"0xFFFFFFFF", @"0xFFF5F5F5", @"0xFFFFFF00", @"0xFF9ACD32"];
    for (NSString* hex in hexColors) {
        UIColor* color = [self colorFromHex:hex];
        if (color && ![colors containsObject:color]) {
            [colors addObject:color];
        }
    }
    self->_colors = [colors copy];
}


#pragma mark - Helper
-(UIImage*)imageWithColor:(UIColor*)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

-(UIColor*)colorFromHex:(NSString*)hex {
    NSString* colorString = [[hex uppercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([colorString length] < 6) {
        return [UIColor grayColor];
    }
    
    if ([colorString hasPrefix:@"0X"]) {
        colorString = [colorString substringFromIndex:2];
    }
    else if ([colorString hasPrefix:@"#"]) {
        colorString = [colorString substringFromIndex:1];
    }
    else if ([colorString length] != 6) {
        return  [UIColor grayColor];
    }
    
    NSRange range = NSMakeRange(2, 2);
    NSString* rString = [colorString substringWithRange:range];
    range.location += 2;
    NSString* gString = [colorString substringWithRange:range];
    range.location += 2;
    NSString* bString = [colorString substringWithRange:range];
    
    unsigned int red, green, blue;
    [[NSScanner scannerWithString:rString] scanHexInt:&red];
    [[NSScanner scannerWithString:gString] scanHexInt:&green];
    [[NSScanner scannerWithString:bString] scanHexInt:&blue];
    
    return [UIColor colorWithRed:((float) red / 255.0f)
                           green:((float) green / 255.0f)
                            blue:((float) blue / 255.0f)
                           alpha:1.0f];
}

-(void)initThemeList {
    NSMutableArray<NSDictionary*>* themes = [[NSMutableArray alloc] init];
    // theme 1
    {
        NSArray *themeArr = @[
            @(kSSTransitionTypeDirectional)
                             ];
        [themes addObject:@{@"name": @"Original", @"music" : @"", @"overlay": @"", @"theme": themeArr, @"thumbnail" : @"Original"}];
    }
    
    // theme 1
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeHeart),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeHeart),
                             @(kSSTransitionTypeDreamyZoom),
                             @(kSSTransitionTypeHeart),
                             @(kSSTransitionTypeBurn)
                             ];
        NSArray *filters = @[@(3), @(5), @(15), @(10), @(8), @(7)];
        [themes addObject:@{@"name": @"Love", @"music" : @"Perfect", @"overlay": @"Floating Hearts", @"theme": themeArr, @"thumbnail" : @"Love", @"filter" : filters}];
    }
    
    // theme 2
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeInvertedPageCurl),
                             @(kSSTransitionTypeDreamyZoom),
                             @(kSSTransitionTypeHeart),
                             @(kSSTransitionTypeRipple),
                             @(kSSTransitionTypeHeart),
                             @(kSSTransitionTypeColorPhase)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Romance", @"music" : @"Slow Hands", @"overlay": @"Falling Roses", @"theme": themeArr, @"thumbnail" : @"Romance", @"filter" : filters}];
    }
    
    // theme 9
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeSimpleZoom),
                             @(kSSTransitionTypeBurn),
                             @(kSSTransitionTypeButterflyWave),
                             @(kSSTransitionTypeFlyeye),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeRipple)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Birthday", @"music" : @"Happy Birthday", @"overlay": @"Birthday Confetti", @"theme": themeArr, @"thumbnail" : @"Birthday", @"filter" : filters}];
    }
    
    // theme 10
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeWindowBlinds),
                             @(kSSTransitionTypeRotateScaleFade),
                             @(kSSTransitionTypeKaleidoscope),
                             @(kSSTransitionTypeCrossZoom),
                             @(kSSTransitionTypeRipple),
                             @(kSSTransitionTypeMorph)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Birthday Rock", @"music" : @"Happy Birthday Rock", @"overlay": @"Falling Sparks", @"theme": themeArr, @"thumbnail" : @"Birthday Rock", @"filter" : filters}];
    }
    
    
    // theme 4
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeMorph),
                             @(kSSTransitionTypeRipple),
                             @(kSSTransitionTypeDreamyZoom),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeBurn),
                             @(kSSTransitionTypeColorPhase)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Memories", @"music" : @"Memories", @"overlay": @"Ascend", @"theme": themeArr, @"thumbnail" : @"Memories", @"filter" : filters}];
    }
    
    
    // theme 5
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeBurn),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeMorph),
                             @(kSSTransitionTypeRipple),
                             @(kSSTransitionTypeKaleidoscope),
                             @(kSSTransitionTypeDirectionalWrap)
                             ];
        NSArray *filters = @[@(3), @(5), @(15), @(10), @(8), @(7)];
        [themes addObject:@{@"name": @"Missing You", @"music" : @"Every Breath You Take", @"overlay": @"Side Snow", @"theme": themeArr, @"thumbnail" : @"MissYou", @"filter" : filters}];
    }
    
    // theme 8
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeStereoViewer),
                             @(kSSTransitionTypeCircle),
                             @(kSSTransitionTypeGlitchDisplace),
                             @(kSSTransitionTypeDirectionalWrap),
                             @(kSSTransitionTypeLinearBlur),
                             @(kSSTransitionTypeCrosshatch)
                             ];
        NSArray *filters = @[@(10), @(14), @(13), @(1), @(11), @(15)];
        [themes addObject:@{@"name": @"Vintage Cinema", @"music" : @"Summer of 69", @"overlay": @"Retro Film", @"theme": themeArr, @"thumbnail" : @"VintageCinema", @"filter" : filters}];
    }
    
    // theme 7
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeButterflyWave),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeMorph),
                             @(kSSTransitionTypeRipple),
                             @(kSSTransitionTypeKaleidoscope),
                             @(kSSTransitionTypeDirectionalWrap)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Good Life", @"music" : @"Good Life", @"overlay": @"Flame Flicker", @"theme": themeArr, @"thumbnail" : @"Good Life", @"filter" : filters}];
    }
    
    // theme 11
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeMorph),
                             @(kSSTransitionTypeDirectionalWrap),
                             @(kSSTransitionTypeInvertedPageCurl),
                             @(kSSTransitionTypeWindowSlice),
                             @(kSSTransitionTypeDoorway)
                             ];
        NSArray *filters = @[@(3), @(5), @(15), @(10), @(8), @(7)];
        [themes addObject:@{@"name": @"Free Fall", @"music" : @"Free Fallin", @"overlay": @"Falling Leaves", @"theme": themeArr, @"thumbnail" : @"FreeFall", @"filter" : filters}];
    }
    
    // theme 6
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeInvertedPageCurl),
                             @(kSSTransitionTypeWindowBlinds),
                             @(kSSTransitionTypeCrosswrap),
                             @(kSSTransitionTypeWind),
                             @(kSSTransitionTypeStereoViewer),
                             @(kSSTransitionTypeSimpleZoom)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Winter Wonderland", @"music" : @"What A Wonderful World", @"overlay": @"Side Snow", @"theme": themeArr, @"thumbnail" : @"Winter", @"filter" : filters}];
    }
    
    // theme 13
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeGlitchDisplace),
                             @(kSSTransitionTypeStereoViewer),
                             @(kSSTransitionTypeKaleidoscope),
                             @(kSSTransitionTypeGlitchDisplace),
                             @(kSSTransitionTypeDoorway),
                             @(kSSTransitionTypeSimpleZoom)
                             ];
        NSArray *filters = @[@(10), @(14), @(13), @(1), @(11), @(15)];
        [themes addObject:@{@"name": @"80's", @"music" : @"Dont Stop The Rock", @"overlay": @"VHS Glitch", @"theme": themeArr, @"thumbnail" : @"80s", @"filter" : filters}];
    }
    
    // theme 13
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeRotateScaleFade),
                             @(kSSTransitionTypeGlitchDisplace),
                             @(kSSTransitionTypeDirectional),
                             @(kSSTransitionTypeFlyeye),
                             @(kSSTransitionTypeButterflyWave)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Happy", @"music" : @"Happy", @"overlay": @"Streaks", @"theme": themeArr, @"thumbnail" : @"Happy", @"filter" : filters}];
    }
    
    // theme 14
    {
        NSArray *themeArr = @[
                             @(kSSTransitionTypeGlitchDisplace),
                             @(kSSTransitionTypeCrossZoom),
                             @(kSSTransitionTypeDoorway),
                             @(kSSTransitionTypeCrosswrap),
                             @(kSSTransitionTypeColorPhase),
                             @(kSSTransitionTypeKaleidoscope)
                             ];
        NSArray *filters = @[@(0)];
        [themes addObject:@{@"name": @"Poppin", @"music" : @"Shake It Off", @"overlay": @"Spotlight", @"theme": themeArr, @"thumbnail" : @"Poppin", @"filter" : filters}];
    }
    
    self->_themes = [themes copy];
}


@end
