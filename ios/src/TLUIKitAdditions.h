#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UILabel *TLLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color);
UIImageView *TLImageView(NSString *symbolName, CGFloat pointSize, UIColor *tint);
UIImage *TLImage(NSString *symbolName, CGFloat pointSize);
UIView *TLHairline(void);
void TLApplyShadow(UIView *view, UIColor *color, CGFloat radius, CGFloat opacity, CGFloat offsetY);

/// 主按钮：胶囊、主题色，禁用时变灰
@interface TLPillButton : UIButton
- (instancetype)initWithTitle:(NSString *)title;
@property (nonatomic, assign) BOOL pillEnabled;
- (void)refreshAccent;
@end

/// 白色大圆角卡片
@interface TLCardView : UIView
@end

/// 圆形图标的轻量按钮（返回 / 关闭）
@interface TLCircleIconButton : UIButton
- (instancetype)initWithSymbol:(NSString *)symbol;
@end

/// 36x36 彩色圆角图标方块（白色图标），对应 Android 的 IconSquare
@interface TLIconSquareView : UIView
@property (nonatomic, strong) UIImageView *imageView;
- (instancetype)initWithSymbol:(NSString *)symbol tint:(UIColor *)tint;
- (void)setIconTintColor:(UIColor *)tint;
@end

/// 设置列表里的操作行：彩色图标 + 标题 + 右侧值 + 箭头
@interface TLRowView : UIControl
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIImageView *chevronView;
@property (nonatomic, strong) UIView *colorDot;
@property (nonatomic, assign) BOOL showsDivider;
- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithTitle:(NSString *)title icon:(nullable NSString *)symbol tint:(nullable UIColor *)tint;
- (void)setDetailText:(nullable NSString *)text;
- (void)setAccentDotColor:(nullable UIColor *)color;
- (void)setIconTintColor:(UIColor *)tint;
- (void)setDestructive:(BOOL)destructive;
@end

/// 「关于」页的信息行：标题 + 右侧值（可选箭头）
@interface TLInfoRowView : UIControl
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIImageView *chevronView;
@property (nonatomic, assign) BOOL showsDivider;
- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value action:(BOOL)action;
@end

/// 轻提示条，支持“点击撤销”
@interface TLToast : NSObject
+ (void)showMessage:(NSString *)message;
+ (void)showMessage:(NSString *)message actionTitle:(nullable NSString *)actionTitle handler:(nullable void (^)(void))handler;
@end

NS_ASSUME_NONNULL_END
