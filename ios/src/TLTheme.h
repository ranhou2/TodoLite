#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const TLThemeDidChangeNotification;
extern NSString *const TLAppVersion;

/// 主题色与全局配色（对应 Android 端的七种浅色主题）
@interface TLTheme : NSObject

+ (UIColor *)accent;
+ (NSInteger)accentIndex;
+ (void)setAccentIndex:(NSInteger)index;
+ (NSString *)accentNameAtIndex:(NSInteger)index;
+ (UIColor *)accentColorAtIndex:(NSInteger)index;
+ (NSInteger)accentCount;
+ (UIColor *)accentWithAlpha:(CGFloat)alpha;

+ (UIColor *)bg;
+ (UIColor *)card;
+ (UIColor *)text;
+ (UIColor *)sub;
+ (UIColor *)hint;
+ (UIColor *)divider;
+ (UIColor *)chevron;
+ (UIColor *)red;
+ (UIColor *)orange;
+ (UIColor *)green;
+ (UIColor *)chipBg;
+ (UIColor *)fieldBg;
+ (UIColor *)purple;
+ (UIColor *)tabSelected;
+ (UIColor *)iconTint;

+ (UIColor *)colorWithHex:(NSUInteger)hex;
+ (UIColor *)colorWithHex:(NSUInteger)hex alpha:(CGFloat)alpha;

+ (UIFont *)font:(CGFloat)size;
+ (UIFont *)font:(CGFloat)size weight:(UIFontWeight)weight;

@end

NS_ASSUME_NONNULL_END
