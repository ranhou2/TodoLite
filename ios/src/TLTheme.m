#import "TLTheme.h"

NSNotificationName const TLThemeDidChangeNotification = @"TLThemeDidChangeNotification";
NSString *const TLAppVersion = @"1.0.0";
static NSString *const kAccentIndexKey = @"tl_accent_index";

@implementation TLTheme

+ (UIColor *)colorWithHex:(NSUInteger)hex {
    return [self colorWithHex:hex alpha:1.0];
}

+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:alpha];
}

+ (NSArray<NSNumber *> *)accentHexes {
    static NSArray<NSNumber *> *hexes = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hexes = @[@0x0A84FF, @0x0EA5B7, @0x10B981, @0x8B7BF7, @0xF2994A, @0xF0619E, @0x5B6472];
    });
    return hexes;
}

+ (NSArray<NSString *> *)accentNames {
    static NSArray<NSString *> *names = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        names = @[@"天蓝", @"湖蓝", @"薄荷", @"藕紫", @"蜜橘", @"樱粉", @"石墨"];
    });
    return names;
}

+ (NSInteger)accentCount {
    return (NSInteger)[self accentHexes].count;
}

+ (NSString *)accentNameAtIndex:(NSInteger)index {
    NSArray *names = [self accentNames];
    if (index < 0 || index >= (NSInteger)names.count) return names.firstObject;
    return names[(NSUInteger)index];
}

+ (UIColor *)accentColorAtIndex:(NSInteger)index {
    NSArray<NSNumber *> *hexes = [self accentHexes];
    if (index < 0 || index >= (NSInteger)hexes.count) index = 0;
    return [self colorWithHex:hexes[(NSUInteger)index].unsignedIntegerValue];
}

+ (NSInteger)accentIndex {
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:kAccentIndexKey];
    if (index < 0 || index >= [self accentCount]) index = 0;
    return index;
}

+ (void)setAccentIndex:(NSInteger)index {
    if (index < 0 || index >= [self accentCount]) return;
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:kAccentIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:TLThemeDidChangeNotification object:nil];
}

+ (UIColor *)accentWithAlpha:(CGFloat)alpha {
    return [[self accent] colorWithAlphaComponent:alpha];
}

+ (UIColor *)accent {
    return [self accentColorAtIndex:[self accentIndex]];
}

+ (UIColor *)bg { return [self colorWithHex:0xF2F2F7]; }
+ (UIColor *)card { return [UIColor whiteColor]; }
+ (UIColor *)text { return [self colorWithHex:0x111114]; }
+ (UIColor *)sub { return [self colorWithHex:0x6D6D72]; }
+ (UIColor *)hint { return [self colorWithHex:0xB0B0B6]; }
+ (UIColor *)divider { return [self colorWithHex:0xE6E6EB]; }
+ (UIColor *)chevron { return [self colorWithHex:0xB7B7BC]; }
+ (UIColor *)red { return [self colorWithHex:0xFF3B30]; }
+ (UIColor *)orange { return [self colorWithHex:0xF2994A]; }
+ (UIColor *)green { return [self colorWithHex:0x34C759]; }
+ (UIColor *)chipBg { return [self colorWithHex:0xE9E9EE]; }
+ (UIColor *)fieldBg { return [self colorWithHex:0xEFEFF2]; }

+ (UIFont *)font:(CGFloat)size {
    return [UIFont systemFontOfSize:size];
}

+ (UIFont *)font:(CGFloat)size weight:(UIFontWeight)weight {
    return [UIFont systemFontOfSize:size weight:weight];
}

@end
