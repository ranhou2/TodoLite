#import "TLUIKitAdditions.h"
#import "TLTheme.h"

@interface TLToast ()
@property (nonatomic, strong) UIView *container;
- (void)dismissNow;
- (void)dismissIfStillCurrent:(TLToast *)candidate;
@end

UILabel *TLLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [TLTheme font:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 1;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    return label;
}

UIImage *TLImage(NSString *symbolName, CGFloat pointSize) {
    UIImage *image = [UIImage systemImageNamed:symbolName];
    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:pointSize weight:UIImageSymbolWeightSemibold];
    return [image imageByApplyingSymbolConfiguration:config];
}

UIImageView *TLImageView(NSString *symbolName, CGFloat pointSize, UIColor *tint) {
    UIImageView *view = [[UIImageView alloc] initWithImage:TLImage(symbolName, pointSize)];
    view.tintColor = tint;
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

UIView *TLHairline(void) {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [TLTheme divider];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    return line;
}

void TLApplyShadow(UIView *view, UIColor *color, CGFloat radius, CGFloat opacity, CGFloat offsetY) {
    view.layer.shadowColor = color.CGColor;
    view.layer.shadowOpacity = (float)opacity;
    view.layer.shadowRadius = radius;
    view.layer.shadowOffset = CGSizeMake(0, offsetY);
}

#pragma mark - TLPillButton

@interface TLPillButton ()
@property (nonatomic, strong) UIColor *enabledColor;
@end

@implementation TLPillButton

- (instancetype)initWithTitle:(NSString *)title {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setTitle:title forState:UIControlStateNormal];
        self.titleLabel.font = [TLTheme font:17 weight:UIFontWeightSemibold];
        self.layer.cornerRadius = 26;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.clipsToBounds = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _enabledColor = [TLTheme accent];
        [self applyStyle];
    }
    return self;
}

- (void)setPillEnabled:(BOOL)pillEnabled {
    _pillEnabled = pillEnabled;
    self.enabled = pillEnabled;
    [self applyStyle];
}

- (void)applyStyle {
    if (self.pillEnabled) {
        self.backgroundColor = self.enabledColor;
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        self.backgroundColor = [TLTheme colorWithHex:0xD9D9DE];
        [self setTitleColor:[TLTheme colorWithHex:0x8A8A8E] forState:UIControlStateNormal];
    }
}

- (void)refreshAccent {
    self.enabledColor = [TLTheme accent];
    [self applyStyle];
}

@end

#pragma mark - TLCardView

@implementation TLCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [TLTheme card];
        self.layer.cornerRadius = 26;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

@end

#pragma mark - TLCircleIconButton

@implementation TLCircleIconButton

- (instancetype)initWithSymbol:(NSString *)symbol {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self setImage:TLImage(symbol, 16) forState:UIControlStateNormal];
        self.tintColor = [TLTheme text];
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 18;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self.widthAnchor constraintEqualToConstant:36].active = YES;
        [self.heightAnchor constraintEqualToConstant:36].active = YES;
    }
    return self;
}

@end

#pragma mark - TLIconSquareView

@implementation TLIconSquareView

- (instancetype)initWithSymbol:(NSString *)symbol tint:(UIColor *)tint {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = tint;
        self.layer.cornerRadius = 11;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.clipsToBounds = YES;
        [self.widthAnchor constraintEqualToConstant:36].active = YES;
        [self.heightAnchor constraintEqualToConstant:36].active = YES;

        _imageView = TLImageView(symbol, 19, [UIColor whiteColor]);
        [self addSubview:_imageView];
        [_imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_imageView.widthAnchor constraintEqualToConstant:22].active = YES;
        [_imageView.heightAnchor constraintEqualToConstant:22].active = YES;
    }
    return self;
}

- (void)setIconTintColor:(UIColor *)tint {
    self.backgroundColor = tint;
}

@end

#pragma mark - TLRowView

@interface TLRowView ()
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) TLIconSquareView *iconView;
@property (nonatomic, assign) BOOL destructive;
@end

@implementation TLRowView

- (instancetype)initWithTitle:(NSString *)title {
    return [self initWithTitle:title icon:nil tint:nil];
}

- (instancetype)initWithTitle:(NSString *)title icon:(NSString *)symbol tint:(UIColor *)tint {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];

        _titleLabel = TLLabel(title, 16, UIFontWeightMedium, [TLTheme text]);
        [self addSubview:_titleLabel];

        _valueLabel = TLLabel(@"", 15, UIFontWeightRegular, [TLTheme sub]);
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_valueLabel];

        _chevronView = TLImageView(@"chevron.right", 14, [TLTheme chevron]);
        [self addSubview:_chevronView];

        _colorDot = [[UIView alloc] init];
        _colorDot.hidden = YES;
        [self addSubview:_colorDot];

        _separator = TLHairline();
        [self addSubview:_separator];

        if (symbol.length > 0) {
            _iconView = [[TLIconSquareView alloc] initWithSymbol:symbol tint:tint ?: [TLTheme accent]];
            [self addSubview:_iconView];
            [_iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
            [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:12].active = YES;
        } else {
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
        }
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

        [_chevronView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
        [_chevronView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_chevronView.widthAnchor constraintEqualToConstant:18].active = YES;
        [_chevronView.heightAnchor constraintEqualToConstant:18].active = YES;

        [_valueLabel.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-6].active = YES;
        [_valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:8].active = YES;
        [_valueLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        [_separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:(symbol.length > 0 ? 64 : 16)].active = YES;
        [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [_separator.heightAnchor constraintEqualToConstant:0.5].active = YES;

        [self.heightAnchor constraintEqualToConstant:58].active = YES;
    }
    return self;
}

- (void)setDetailText:(NSString *)text {
    self.valueLabel.text = text ?: @"";
    self.valueLabel.hidden = (text.length == 0);
}

- (void)setAccentDotColor:(UIColor *)color {
    self.colorDot.hidden = YES;
}

- (void)setIconTintColor:(UIColor *)tint {
    [self.iconView setIconTintColor:tint];
}

- (void)setDestructive:(BOOL)destructive {
    _destructive = destructive;
    self.titleLabel.textColor = [TLTheme text];
}

- (void)setShowsDivider:(BOOL)showsDivider {
    _showsDivider = showsDivider;
    self.separator.hidden = !showsDivider;
}

@end

#pragma mark - TLInfoRowView

@interface TLInfoRowView ()
@property (nonatomic, strong) UIView *separator;
@end

@implementation TLInfoRowView

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value action:(BOOL)action {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = action;

        _titleLabel = TLLabel(title, 16, UIFontWeightMedium, [TLTheme text]);
        [self addSubview:_titleLabel];

        _valueLabel = TLLabel(value ?: @"", 16, UIFontWeightRegular, [TLTheme sub]);
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_valueLabel];

        _chevronView = TLImageView(@"chevron.right", 13, [TLTheme chevron]);
        _chevronView.hidden = !action;
        [self addSubview:_chevronView];

        _separator = TLHairline();
        [self addSubview:_separator];

        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

        if (action) {
            [_chevronView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
            [_chevronView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
            [_chevronView.widthAnchor constraintEqualToConstant:16].active = YES;
            [_chevronView.heightAnchor constraintEqualToConstant:16].active = YES;
            [_valueLabel.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-6].active = YES;
        } else {
            [_valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
        }
        [_valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:8].active = YES;

        [_separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
        [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [_separator.heightAnchor constraintEqualToConstant:0.5].active = YES;

        [self.heightAnchor constraintEqualToConstant:56].active = YES;
    }
    return self;
}

- (void)setShowsDivider:(BOOL)showsDivider {
    _showsDivider = showsDivider;
    self.separator.hidden = !showsDivider;
}

@end

#pragma mark - TLToast

@implementation TLToast

+ (void)showMessage:(NSString *)message {
    [self showMessage:message actionTitle:nil handler:nil];
}

+ (void)showMessage:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(void))handler {
    UIWindow *window = nil;
    for (UIWindow *candidate in [UIApplication sharedApplication].windows) {
        if (candidate.isKeyWindow) {
            window = candidate;
            break;
        }
    }
    if (window == nil) window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) return;

    static TLToast *currentToast = nil;
    if (currentToast != nil) {
        [currentToast dismissNow];
    }

    TLToast *toast = [[TLToast alloc] init];
    currentToast = toast;

    UIView *container = [[UIView alloc] init];
    container.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.82];
    container.layer.cornerRadius = 22;
    container.layer.cornerCurve = kCACornerCurveContinuous;
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.alpha = 0;

    UILabel *label = TLLabel(message, 15, UIFontWeightMedium, [UIColor whiteColor]);
    label.numberOfLines = 2;
    [container addSubview:label];

    UIButton *actionButton = nil;
    if (actionTitle.length > 0 && handler != nil) {
        actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [actionButton setTitle:actionTitle forState:UIControlStateNormal];
        [actionButton setTitleColor:[TLTheme accent] forState:UIControlStateNormal];
        actionButton.titleLabel.font = [TLTheme font:15 weight:UIFontWeightSemibold];
        actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [actionButton addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            handler();
            [toast dismissNow];
        }] forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:actionButton];
    }

    [window addSubview:container];

    CGFloat bottomInset = window.safeAreaInsets.bottom;
    [container.centerXAnchor constraintEqualToAnchor:window.centerXAnchor].active = YES;
    [container.bottomAnchor constraintEqualToAnchor:window.bottomAnchor constant:-(bottomInset + 96)].active = YES;
    [container.leadingAnchor constraintGreaterThanOrEqualToAnchor:window.leadingAnchor constant:24].active = YES;
    [container.trailingAnchor constraintLessThanOrEqualToAnchor:window.trailingAnchor constant:-24].active = YES;

    [label.topAnchor constraintEqualToAnchor:container.topAnchor constant:12].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12].active = YES;
    [label.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:18].active = YES;

    if (actionButton != nil) {
        [label.trailingAnchor constraintEqualToAnchor:actionButton.leadingAnchor constant:-14].active = YES;
        [actionButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
        [actionButton.centerYAnchor constraintEqualToAnchor:container.centerYAnchor].active = YES;
    } else {
        [label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-18].active = YES;
    }

    toast.container = container;
    [UIView animateWithDuration:0.22 animations:^{
        container.alpha = 1;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast dismissIfStillCurrent:currentToast];
    });
}

- (void)dismissIfStillCurrent:(TLToast *)candidate {
    if (candidate != self) return;
    [self dismissNow];
}

- (void)dismissNow {
    UIView *container = self.container;
    if (container == nil) return;
    self.container = nil;
    [UIView animateWithDuration:0.2 animations:^{
        container.alpha = 0;
    } completion:^(BOOL finished) {
        [container removeFromSuperview];
    }];
}

@end
