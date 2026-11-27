#import "TLProfileViewController.h"
#import "TLMainViewController.h"
#import "TLTheme.h"
#import "TLUIKitAdditions.h"
#import "TLReminders.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#pragma mark - 进度条

@interface TLProgressBar : UIView
@property (nonatomic, assign) CGFloat progress;
@end

@interface TLProgressBar ()
@property (nonatomic, strong) UIView *fillView;
@end

@implementation TLProgressBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [TLTheme divider];
        self.layer.cornerRadius = 3;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self.heightAnchor constraintEqualToConstant:6].active = YES;

        _fillView = [[UIView alloc] init];
        _fillView.backgroundColor = [TLTheme accent];
        _fillView.layer.cornerRadius = 3;
        _fillView.translatesAutoresizingMaskIntoConstraints = YES;
        [self addSubview:_fillView];
        _fillView.frame = CGRectMake(0, 0, 0, 6);
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = MIN(MAX(progress, 0.0), 1.0);
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width * self.progress;
    self.fillView.frame = CGRectMake(0, 0, width, self.bounds.size.height);
    self.fillView.layer.cornerRadius = self.bounds.size.height / 2.0;
}

- (void)refreshAccent {
    self.fillView.backgroundColor = [TLTheme accent];
}

@end

#pragma mark - 选择行

@interface TLChoiceRow : UIControl
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *checkView;
@property (nonatomic, strong) UIView *colorDot;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, assign) BOOL selectedRow;
- (instancetype)initWithTitle:(NSString *)title dotColor:(nullable UIColor *)dotColor;
@end

@implementation TLChoiceRow

- (instancetype)initWithTitle:(NSString *)title dotColor:(UIColor *)dotColor {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];

        _titleLabel = TLLabel(title, 16, UIFontWeightMedium, [TLTheme text]);
        [self addSubview:_titleLabel];

        _checkView = TLImageView(@"checkmark", 15, [TLTheme accent]);
        _checkView.hidden = YES;
        [self addSubview:_checkView];

        _colorDot = [[UIView alloc] init];
        _colorDot.translatesAutoresizingMaskIntoConstraints = NO;
        _colorDot.layer.cornerRadius = 13;
        _colorDot.backgroundColor = dotColor;
        _colorDot.hidden = (dotColor == nil);
        [self addSubview:_colorDot];

        CGFloat textLeading = dotColor ? 58 : 18;
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:textLeading].active = YES;
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

        [_colorDot.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:18].active = YES;
        [_colorDot.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_colorDot.widthAnchor constraintEqualToConstant:26].active = YES;
        [_colorDot.heightAnchor constraintEqualToConstant:26].active = YES;

        [_checkView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20].active = YES;
        [_checkView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_checkView.widthAnchor constraintEqualToConstant:16].active = YES;
        [_checkView.heightAnchor constraintEqualToConstant:16].active = YES;

        _separator = TLHairline();
        [self addSubview:_separator];
        [_separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:(dotColor ? 58 : 18)].active = YES;
        [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [_separator.heightAnchor constraintEqualToConstant:0.5].active = YES;

        [self.heightAnchor constraintEqualToConstant:54].active = YES;
    }
    return self;
}

- (void)setSelectedRow:(BOOL)selectedRow {
    _selectedRow = selectedRow;
    self.checkView.hidden = !selectedRow;
}

- (void)setShowsDivider:(BOOL)shows {
    self.separator.hidden = !shows;
}

@end

#pragma mark - 通用二级页

@interface TLPageViewController : UIViewController
@property (nonatomic, copy, nullable) void (^onBack)(void);
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
- (void)buildPageWithTitle:(NSString *)title subtitle:(NSString *)subtitle;
- (TLCardView *)addCardWithRows:(NSArray<UIView *> *)rows;
- (void)addGroupTitle:(NSString *)text;
- (void)backTapped;
@end

@implementation TLPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TLTheme bg];
}

- (void)buildPageWithTitle:(NSString *)title subtitle:(NSString *)subtitle {
    TLCircleIconButton *back = [[TLCircleIconButton alloc] initWithSymbol:@"chevron.left"];
    [back addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    [back.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18].active = YES;
    [back.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:2].active = YES;

    _titleLabel = TLLabel(title, 30, UIFontWeightBold, [TLTheme text]);
    [self.view addSubview:_titleLabel];
    [_titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [_titleLabel.topAnchor constraintEqualToAnchor:back.bottomAnchor constant:8].active = YES;

    _subtitleLabel = TLLabel(subtitle, 14, UIFontWeightRegular, [TLTheme sub]);
    [self.view addSubview:_subtitleLabel];
    [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor].active = YES;
    [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2].active = YES;

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    [_scrollView.topAnchor constraintEqualToAnchor:_subtitleLabel.bottomAnchor constant:12].active = YES;
    [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 0;
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_stack];
    [_stack.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor constant:6].active = YES;
    [_stack.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor constant:-30].active = YES;
    [_stack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor constant:20].active = YES;
    [_stack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor constant:-20].active = YES;
    [_stack.widthAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.widthAnchor constant:-40].active = YES;
}

- (void)addGroupTitle:(NSString *)text {
    UILabel *label = TLLabel(text, 13, UIFontWeightMedium, [TLTheme sub]);
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:label];
    [label.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [label.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:18].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor constant:-8].active = YES;
    [wrapper.heightAnchor constraintEqualToConstant:46].active = YES;
    [self.stack addArrangedSubview:wrapper];
}

- (TLCardView *)addCardWithRows:(NSArray<UIView *> *)rows {
    TLCardView *card = [[TLCardView alloc] init];
    [self.stack addArrangedSubview:card];
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisVertical;
    rowStack.spacing = 0;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:rowStack];
    [rowStack.topAnchor constraintEqualToAnchor:card.topAnchor].active = YES;
    [rowStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor].active = YES;
    [rowStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor].active = YES;
    [rowStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor].active = YES;
    for (UIView *row in rows) {
        [rowStack addArrangedSubview:row];
        [row.leadingAnchor constraintEqualToAnchor:rowStack.leadingAnchor].active = YES;
        [row.trailingAnchor constraintEqualToAnchor:rowStack.trailingAnchor].active = YES;
    }
    return card;
}

- (void)backTapped {
    if (self.onBack != nil) {
        self.onBack();
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

#pragma mark - 外观

@interface TLAppearanceViewController : TLPageViewController
@end

@implementation TLAppearanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildPageWithTitle:@"外观" subtitle:@"主题色 · 浅色系"];
    [self addGroupTitle:@"主题色"];

    NSMutableArray *rows = [NSMutableArray array];
    for (NSInteger i = 0; i < [TLTheme accentCount]; i++) {
        TLChoiceRow *row = [[TLChoiceRow alloc] initWithTitle:[TLTheme accentNameAtIndex:i]
                                                    dotColor:[TLTheme accentColorAtIndex:i]];
        row.tag = i;
        row.selectedRow = (i == [TLTheme accentIndex]);
        [row addTarget:self action:@selector(colorTapped:) forControlEvents:UIControlEventTouchUpInside];
        [rows addObject:row];
        row.separator.hidden = (i == [TLTheme accentCount] - 1);
    }
    [self addCardWithRows:rows];

    UILabel *footer = TLLabel(@"天蓝 · 湖蓝 · 薄荷 · 藕紫 · 蜜橘 · 樱粉 · 石墨", 13, UIFontWeightRegular, [TLTheme hint]);
    footer.numberOfLines = 2;
    UIView *wrapper = [[UIView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:footer];
    [footer.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [footer.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor].active = YES;
    [footer.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:14].active = YES;
    [wrapper.heightAnchor constraintEqualToConstant:50].active = YES;
    [self.stack addArrangedSubview:wrapper];
}

- (void)colorTapped:(TLChoiceRow *)sender {
    [TLTheme setAccentIndex:sender.tag];
    [self reloadRows];
}

- (void)reloadRows {
    for (UIView *view in self.stack.arrangedSubviews) {
        if (![view isKindOfClass:[TLCardView class]]) continue;
        for (UIView *rowView in view.subviews) {
            if (![rowView isKindOfClass:[UIStackView class]]) continue;
            for (UIView *row in ((UIStackView *)rowView).arrangedSubviews) {
                if (![row isKindOfClass:[TLChoiceRow class]]) continue;
                TLChoiceRow *choice = (TLChoiceRow *)row;
                choice.selectedRow = (choice.tag == [TLTheme accentIndex]);
                choice.checkView.tintColor = [TLTheme accent];
            }
        }
    }
}

@end

#pragma mark - 提醒

@interface TLRemindViewController : TLPageViewController
@end

@implementation TLRemindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buildPageWithTitle:@"提醒" subtitle:@"截止前弹窗提醒"];
    [self addGroupTitle:@"提醒时间"];

    NSMutableArray *rows = [NSMutableArray array];
    NSArray<NSNumber *> *options = TLReminderLeadOptions();
    for (NSInteger i = 0; i < (NSInteger)options.count; i++) {
        NSInteger minutes = options[(NSUInteger)i].integerValue;
        TLChoiceRow *row = [[TLChoiceRow alloc] initWithTitle:TLReminderLabelForMinutes(minutes) dotColor:nil];
        row.tag = minutes;
        row.selectedRow = (minutes == TLReminderLeadMinutes());
        [row addTarget:self action:@selector(leadTapped:) forControlEvents:UIControlEventTouchUpInside];
        [rows addObject:row];
        row.separator.hidden = (i == (NSInteger)options.count - 1);
    }
    [self addCardWithRows:rows];

    UILabel *footer = TLLabel(@"提醒按截止当天结束时间倒推：截止「11月27日」且提前 1 小时，会在 27 日 23:00 收到弹窗提醒。已逾期或已完成的待办不再提醒。",
                              13, UIFontWeightRegular, [TLTheme hint]);
    footer.numberOfLines = 0;
    UIView *wrapper = [[UIView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:footer];
    [footer.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [footer.trailingAnchor constraintEqualToAnchor:wrapper.trailingAnchor constant:-4].active = YES;
    [footer.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:14].active = YES;
    [footer.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor constant:-6].active = YES;
    [self.stack addArrangedSubview:wrapper];
}

- (void)leadTapped:(TLChoiceRow *)sender {
    TLReminderSetLeadMinutes(sender.tag);
    TLRemindersReschedule();
    for (UIView *view in self.stack.arrangedSubviews) {
        if (![view isKindOfClass:[TLCardView class]]) continue;
        for (UIView *rowView in view.subviews) {
            if (![rowView isKindOfClass:[UIStackView class]]) continue;
            for (UIView *row in ((UIStackView *)rowView).arrangedSubviews) {
                if (![row isKindOfClass:[TLChoiceRow class]]) continue;
                TLChoiceRow *choice = (TLChoiceRow *)row;
                choice.selectedRow = (choice.tag == sender.tag);
                choice.checkView.tintColor = [TLTheme accent];
            }
        }
    }
}

@end

#pragma mark - 我的

@interface TLProfileViewController () <UIDocumentPickerDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stack;
@property (nonatomic, strong) UILabel *percentLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) TLProgressBar *progressBar;
@property (nonatomic, strong) TLRowView *appearanceRow;
@property (nonatomic, strong) TLRowView *remindRow;
@property (nonatomic, strong) TLRowView *clearDoneRow;
@property (nonatomic, strong) TLRowView *clearAllRow;
@property (nonatomic, assign) BOOL exportingData;
@end

@implementation TLProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self buildUI];
    [self refreshContent];
}

- (void)buildUI {
    UILabel *title = TLLabel(@"我的", 34, UIFontWeightBold, [TLTheme text]);
    [self.view addSubview:title];
    [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [title.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10].active = YES;

    UILabel *subtitle = TLLabel(@"今日事 · 无需登录，打开即用", 14, UIFontWeightRegular, [TLTheme sub]);
    [self.view addSubview:subtitle];
    [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor].active = YES;
    [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2].active = YES;

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_scrollView];
    [_scrollView.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:12].active = YES;
    [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 0;
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_stack];
    [_stack.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor constant:4].active = YES;
    [_stack.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor constant:-30].active = YES;
    [_stack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor constant:20].active = YES;
    [_stack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor constant:-20].active = YES;
    [_stack.widthAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.widthAnchor constant:-40].active = YES;

    // 完成情况卡片
    TLCardView *statsCard = [[TLCardView alloc] init];
    [_stack addArrangedSubview:statsCard];

    UILabel *caption = TLLabel(@"完成情况", 13, UIFontWeightMedium, [TLTheme sub]);
    [statsCard addSubview:caption];
    [caption.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:18].active = YES;
    [caption.topAnchor constraintEqualToAnchor:statsCard.topAnchor constant:18].active = YES;

    _percentLabel = TLLabel(@"0%", 34, UIFontWeightBold, [TLTheme accent]);
    [statsCard addSubview:_percentLabel];
    [_percentLabel.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:18].active = YES;
    [_percentLabel.topAnchor constraintEqualToAnchor:caption.bottomAnchor constant:6].active = YES;

    UILabel *rateCaption = TLLabel(@"完成率", 13, UIFontWeightRegular, [TLTheme sub]);
    [statsCard addSubview:rateCaption];
    [rateCaption.leadingAnchor constraintEqualToAnchor:_percentLabel.trailingAnchor constant:6].active = YES;
    [rateCaption.lastBaselineAnchor constraintEqualToAnchor:_percentLabel.lastBaselineAnchor].active = YES;

    _countLabel = TLLabel(@"", 14, UIFontWeightRegular, [TLTheme sub]);
    [statsCard addSubview:_countLabel];
    [_countLabel.leadingAnchor constraintEqualToAnchor:_percentLabel.leadingAnchor].active = YES;
    [_countLabel.topAnchor constraintEqualToAnchor:_percentLabel.bottomAnchor constant:4].active = YES;

    _progressBar = [[TLProgressBar alloc] init];
    [statsCard addSubview:_progressBar];
    [_progressBar.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:18].active = YES;
    [_progressBar.trailingAnchor constraintEqualToAnchor:statsCard.trailingAnchor constant:-18].active = YES;
    [_progressBar.topAnchor constraintEqualToAnchor:_countLabel.bottomAnchor constant:14].active = YES;
    [_progressBar.bottomAnchor constraintEqualToAnchor:statsCard.bottomAnchor constant:-20].active = YES;

    // 设置
    [self addGroupTitle:@"设置"];
    _appearanceRow = [[TLRowView alloc] initWithTitle:@"外观"];
    [_appearanceRow addTarget:self action:@selector(openAppearance) forControlEvents:UIControlEventTouchUpInside];
    _remindRow = [[TLRowView alloc] initWithTitle:@"提醒"];
    [_remindRow addTarget:self action:@selector(openRemind) forControlEvents:UIControlEventTouchUpInside];
    TLRowView *aboutRow = [[TLRowView alloc] initWithTitle:@"关于"];
    [aboutRow addTarget:self action:@selector(openAbout) forControlEvents:UIControlEventTouchUpInside];
    _appearanceRow.showsDivider = YES;
    _remindRow.showsDivider = YES;
    aboutRow.showsDivider = NO;
    [self addCardWithRows:@[_appearanceRow, _remindRow, aboutRow]];

    // 数据管理
    [self addGroupTitle:@"数据管理"];
    TLRowView *exportRow = [[TLRowView alloc] initWithTitle:@"导出数据"];
    [exportRow addTarget:self action:@selector(exportData) forControlEvents:UIControlEventTouchUpInside];
    TLRowView *importRow = [[TLRowView alloc] initWithTitle:@"导入数据"];
    [importRow addTarget:self action:@selector(importData) forControlEvents:UIControlEventTouchUpInside];
    _clearDoneRow = [[TLRowView alloc] initWithTitle:@"清空已完成"];
    [_clearDoneRow addTarget:self action:@selector(clearDoneTapped) forControlEvents:UIControlEventTouchUpInside];
    _clearDoneRow.showsDivider = YES;
    [_clearDoneRow setDestructive:YES];
    _clearAllRow = [[TLRowView alloc] initWithTitle:@"清空全部待办"];
    [_clearAllRow addTarget:self action:@selector(clearAllTapped) forControlEvents:UIControlEventTouchUpInside];
    [_clearAllRow setDestructive:YES];
    _clearAllRow.showsDivider = NO;
    [self addCardWithRows:@[exportRow, importRow, _clearDoneRow, _clearAllRow]];

    UILabel *hint = TLLabel(@"导出时可选择任意文件夹；导入会按记录合并，不会覆盖本地数据。", 12, UIFontWeightRegular, [TLTheme hint]);
    hint.numberOfLines = 0;
    UIView *hintWrapper = [[UIView alloc] init];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [hintWrapper addSubview:hint];
    [hint.leadingAnchor constraintEqualToAnchor:hintWrapper.leadingAnchor constant:4].active = YES;
    [hint.trailingAnchor constraintEqualToAnchor:hintWrapper.trailingAnchor constant:-4].active = YES;
    [hint.topAnchor constraintEqualToAnchor:hintWrapper.topAnchor constant:12].active = YES;
    [hintWrapper.heightAnchor constraintEqualToConstant:56].active = YES;
    [_stack addArrangedSubview:hintWrapper];

    UILabel *footer = TLLabel(@"所有数据仅保存在你的设备上。\n今日事 v1.0.0 · 本地存储", 12, UIFontWeightRegular, [TLTheme hint]);
    footer.numberOfLines = 0;
    footer.textAlignment = NSTextAlignmentCenter;
    UIView *footerWrapper = [[UIView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    [footerWrapper addSubview:footer];
    [footer.leadingAnchor constraintEqualToAnchor:footerWrapper.leadingAnchor].active = YES;
    [footer.trailingAnchor constraintEqualToAnchor:footerWrapper.trailingAnchor].active = YES;
    [footer.topAnchor constraintEqualToAnchor:footerWrapper.topAnchor constant:10].active = YES;
    [footerWrapper.heightAnchor constraintEqualToConstant:60].active = YES;
    [_stack addArrangedSubview:footerWrapper];
}

- (void)addGroupTitle:(NSString *)text {
    UILabel *label = TLLabel(text, 13, UIFontWeightMedium, [TLTheme sub]);
    UIView *wrapper = [[UIView alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:label];
    [label.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [label.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:16].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor constant:-8].active = YES;
    [wrapper.heightAnchor constraintEqualToConstant:44].active = YES;
    [_stack addArrangedSubview:wrapper];
}

- (void)addCardWithRows:(NSArray<UIView *> *)rows {
    TLCardView *card = [[TLCardView alloc] init];
    [_stack addArrangedSubview:card];
    UIStackView *rowStack = [[UIStackView alloc] init];
    rowStack.axis = UILayoutConstraintAxisVertical;
    rowStack.spacing = 0;
    rowStack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:rowStack];
    [rowStack.topAnchor constraintEqualToAnchor:card.topAnchor].active = YES;
    [rowStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor].active = YES;
    [rowStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor].active = YES;
    [rowStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor].active = YES;
    for (UIView *row in rows) {
        [rowStack addArrangedSubview:row];
        [row.leadingAnchor constraintEqualToAnchor:rowStack.leadingAnchor].active = YES;
        [row.trailingAnchor constraintEqualToAnchor:rowStack.trailingAnchor].active = YES;
    }
}

#pragma mark 刷新

- (void)refreshContent {
    TLTodoStore *store = [TLTodoStore shared];
    NSInteger total = (NSInteger)store.allItems.count;
    NSInteger done = (NSInteger)store.doneItems.count;
    NSInteger percent = (total == 0) ? 0 : (NSInteger)(((double)done / (double)total) * 100.0 + 0.5);
    self.percentLabel.text = [NSString stringWithFormat:@"%ld%%", (long)percent];
    self.countLabel.text = [NSString stringWithFormat:@"已经完成 %ld / %ld 项", (long)done, (long)total];
    self.progressBar.progress = (total == 0) ? 0 : (CGFloat)done / (CGFloat)total;
    [self.progressBar refreshAccent];
    self.percentLabel.textColor = [TLTheme accent];

    [self.appearanceRow setDetailText:[TLTheme accentNameAtIndex:[TLTheme accentIndex]]];
    [self.appearanceRow setAccentDotColor:[TLTheme accent]];
    [self.remindRow setDetailText:TLReminderLabelForMinutes(TLReminderLeadMinutes())];
    [self.remindRow setAccentDotColor:nil];
    [self.clearDoneRow setDetailText:[NSString stringWithFormat:@"%ld 项", (long)done]];
    [self.clearAllRow setDetailText:[NSString stringWithFormat:@"%ld 项", (long)total]];
    [self.progressBar setNeedsLayout];
}

#pragma mark 操作

- (void)openAppearance {
    TLAppearanceViewController *vc = [[TLAppearanceViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self) weakSelf = self;
    vc.onBack = ^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        [weakSelf refreshContent];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)openRemind {
    TLRemindViewController *vc = [[TLRemindViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self) weakSelf = self;
    vc.onBack = ^{
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        [weakSelf refreshContent];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)openAbout {
    NSString *message = [NSString stringWithFormat:@"今日事 v%@\n\n"
                         "1. 「今日事」是一款完全离线的本地待办工具，不会联网，不收集、不上传任何个人信息。\n"
                         "2. 导出功能生成的备份文件保存在你自行选择的位置，请注意妥善保管。\n"
                         "3. 本应用仅供个人学习与日常使用，请勿用于商业用途；本应用为非官方 iOS 移植版本，与 Android 原版作者无授权关系。\n"
                         "4. 开发者不对因使用本应用造成的任何数据丢失或损失承担责任，重要数据请定期导出备份。\n\n"
                         "作者：酷安 @然后啊然后\niOS 移植与适配：Jacky", TLAppVersion];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关于"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)exportData {
    NSString *json = [[TLTodoStore shared] exportJSON];
    NSString *fileName = [NSString stringWithFormat:@"今日事备份-%@.json", [TLDue textForDate:[NSDate date]]];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    NSError *error = nil;
    BOOL written = [json writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!written) {
        [self showAlertTitle:@"导出失败" message:error.localizedDescription ?: @"无法写入文件"];
        return;
    }
    self.exportingData = YES;
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[url] asCopy:YES];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)importData {
    self.exportingData = NO;
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    self.exportingData = NO;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (self.exportingData) {
        self.exportingData = NO;
        [self showToast:[NSString stringWithFormat:@"已导出 %ld 条待办", (long)[TLTodoStore shared].allItems.count]];
        return;
    }
    if (urls.count == 0) return;
    NSURL *url = urls.firstObject;
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data == nil) {
        [self showAlertTitle:@"导入失败" message:@"无法读取所选文件"];
        return;
    }
    NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *errorMessage = nil;
    NSInteger added = [[TLTodoStore shared] importJSON:raw error:&errorMessage];
    if (added < 0) {
        [self showAlertTitle:@"导入失败" message:errorMessage ?: @"文件格式不正确"];
        return;
    }
    if (added == 0) {
        [self showToast:@"没有新的待办可导入"];
    } else {
        [self showToast:[NSString stringWithFormat:@"已导入 %ld 条待办", (long)added]];
    }
    [self refreshContent];
}

- (void)clearDoneTapped {
    NSInteger done = (NSInteger)[TLTodoStore shared].doneItems.count;
    if (done == 0) {
        [self showToast:@"还没有已完成的记录"];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清空已完成"
                                                                  message:[NSString stringWithFormat:@"将删除 %ld 条已完成的记录，无法恢复。", (long)done]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[TLTodoStore shared] clearDone];
        [weakSelf showToast:[NSString stringWithFormat:@"已清空 %ld 条完成记录", (long)done]];
        [weakSelf refreshContent];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearAllTapped {
    NSInteger total = (NSInteger)[TLTodoStore shared].allItems.count;
    if (total == 0) {
        [self showToast:@"列表已经是空的"];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"清空全部待办"
                                                                  message:[NSString stringWithFormat:@"将删除全部 %ld 条记录，包括未完成的任务，无法恢复。", (long)total]
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"清空" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[TLTodoStore shared] clearAll];
        [weakSelf showToast:@"已清空全部待办"];
        [weakSelf refreshContent];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
    if (self.host != nil) [self.host showToastMessage:message];
}

- (void)showAlertTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
