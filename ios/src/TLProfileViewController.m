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
        [self.heightAnchor constraintEqualToConstant:8].active = YES;

        _fillView = [[UIView alloc] init];
        _fillView.backgroundColor = [TLTheme accent];
        _fillView.layer.cornerRadius = 3;
        _fillView.translatesAutoresizingMaskIntoConstraints = YES;
        [self addSubview:_fillView];
        _fillView.frame = CGRectMake(0, 0, 0, 8);
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

        _checkView = TLImageView(@"checkmark", 20, [TLTheme accent]);
        _checkView.hidden = YES;
        [self addSubview:_checkView];

        _colorDot = [[UIView alloc] init];
        _colorDot.translatesAutoresizingMaskIntoConstraints = NO;
        _colorDot.layer.cornerRadius = 14;
        _colorDot.backgroundColor = dotColor;
        _colorDot.hidden = (dotColor == nil);
        [self addSubview:_colorDot];

        CGFloat textLeading = dotColor ? 56 : 16;
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:textLeading].active = YES;
        [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;

        [_colorDot.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16].active = YES;
        [_colorDot.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_colorDot.widthAnchor constraintEqualToConstant:28].active = YES;
        [_colorDot.heightAnchor constraintEqualToConstant:28].active = YES;

        [_checkView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16].active = YES;
        [_checkView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        [_checkView.widthAnchor constraintEqualToConstant:20].active = YES;
        [_checkView.heightAnchor constraintEqualToConstant:20].active = YES;

        _separator = TLHairline();
        [self addSubview:_separator];
        [_separator.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:(dotColor ? 64 : 16)].active = YES;
        [_separator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [_separator.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [_separator.heightAnchor constraintEqualToConstant:0.5].active = YES;

        [self.heightAnchor constraintEqualToConstant:58].active = YES;
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
@property (nonatomic, strong) TLTabBarView *tabBar;
@property (nonatomic, copy, nullable) void (^onSelectTab)(NSInteger index);
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
    [back.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
    [back.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:2].active = YES;

    _titleLabel = TLLabel(title, 34, UIFontWeightBlack, [TLTheme text]);
    [self.view addSubview:_titleLabel];
    [_titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
    [_titleLabel.heightAnchor constraintEqualToConstant:48].active = YES;
    [_titleLabel.topAnchor constraintEqualToAnchor:back.bottomAnchor constant:12].active = YES;

    _subtitleLabel = TLLabel(subtitle, 15, UIFontWeightRegular, [TLTheme sub]);
    [self.view addSubview:_subtitleLabel];
    [_subtitleLabel.leadingAnchor constraintEqualToAnchor:_titleLabel.leadingAnchor].active = YES;
    [_subtitleLabel.heightAnchor constraintEqualToConstant:24].active = YES;
    [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2].active = YES;

    _tabBar = [[TLTabBarView alloc] initWithFrame:CGRectZero];
    _tabBar.selectedIndex = 2;
    __weak typeof(self) weakSelf = self;
    _tabBar.onSelect = ^(NSInteger index) {
        if (weakSelf.onSelectTab != nil) weakSelf.onSelectTab(index);
    };
    [self.view addSubview:_tabBar];
    [_tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18].active = YES;
    [_tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18].active = YES;
    [_tabBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8].active = YES;
    [_tabBar.heightAnchor constraintEqualToConstant:58].active = YES;

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 40, 0);
    [self.view addSubview:_scrollView];
    [_scrollView.topAnchor constraintEqualToAnchor:_subtitleLabel.bottomAnchor constant:12].active = YES;
    [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_scrollView.bottomAnchor constraintEqualToAnchor:_tabBar.topAnchor constant:-8].active = YES;

    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 0;
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_stack];
    [_stack.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor constant:4].active = YES;
    [_stack.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor constant:-30].active = YES;
    [_stack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor constant:16].active = YES;
    [_stack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor constant:-16].active = YES;
    [_stack.widthAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.widthAnchor constant:-32].active = YES;
}

- (void)addGroupTitle:(NSString *)text {
    UILabel *label = TLLabel(text, 15, UIFontWeightSemibold, [TLTheme sub]);
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:label];
    [label.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [label.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:18].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor constant:-14].active = YES;
    [wrapper.heightAnchor constraintEqualToConstant:54].active = YES;
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

    UILabel *footer = TLLabel(@"选择后立即生效并自动记住，按钮、标签和勾选框会一起变化。", 13, UIFontWeightRegular, [TLTheme hint]);
    footer.numberOfLines = 2;
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
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
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
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
@property (nonatomic, strong) UILabel *pendingValueLabel;
@property (nonatomic, strong) UILabel *doneValueLabel;
@property (nonatomic, strong) UILabel *rateValueLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) TLProgressBar *progressBar;
@property (nonatomic, strong) TLRowView *remindRow;
@property (nonatomic, strong) TLRowView *appearanceRow;
@property (nonatomic, strong) TLRowView *exportRow;
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

#pragma mark 构建

- (UIView *)makeVersionChip {
    UIView *chip = [[UIView alloc] init];
    chip.backgroundColor = [TLTheme chipBg];
    chip.layer.cornerRadius = 12;
    chip.layer.cornerCurve = kCACornerCurveContinuous;
    chip.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *version = TLLabel([NSString stringWithFormat:@"v%@", TLAppVersion], 13, UIFontWeightMedium, [TLTheme text]);
    version.translatesAutoresizingMaskIntoConstraints = NO;
    [chip addSubview:version];
    [version.topAnchor constraintEqualToAnchor:chip.topAnchor constant:4].active = YES;
    [version.bottomAnchor constraintEqualToAnchor:chip.bottomAnchor constant:-4].active = YES;
    [version.leadingAnchor constraintEqualToAnchor:chip.leadingAnchor constant:12].active = YES;
    [version.trailingAnchor constraintEqualToAnchor:chip.trailingAnchor constant:-12].active = YES;
    [chip.heightAnchor constraintEqualToConstant:24].active = YES;
    return chip;
}

- (UIView *)statColumnWithValueLabel:(UILabel *)valueLabel caption:(NSString *)caption {
    UIView *column = [[UIView alloc] init];
    column.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentCenter;
    content.spacing = 2;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [column addSubview:content];

    valueLabel.textAlignment = NSTextAlignmentCenter;
    UILabel *captionLabel = TLLabel(caption, 13, UIFontWeightRegular, [TLTheme sub]);
    captionLabel.textAlignment = NSTextAlignmentCenter;
    [content addArrangedSubview:valueLabel];
    [content addArrangedSubview:captionLabel];

    [content.centerXAnchor constraintEqualToAnchor:column.centerXAnchor].active = YES;
    [content.centerYAnchor constraintEqualToAnchor:column.centerYAnchor].active = YES;
    [content.leadingAnchor constraintGreaterThanOrEqualToAnchor:column.leadingAnchor].active = YES;
    [content.trailingAnchor constraintLessThanOrEqualToAnchor:column.trailingAnchor].active = YES;
    return column;
}

- (void)buildUI {
    UIView *versionChip = [self makeVersionChip];
    [self.view addSubview:versionChip];
    [versionChip.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16].active = YES;
    [versionChip.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:5].active = YES;

    UILabel *title = TLLabel(@"我的", 34, UIFontWeightBlack, [TLTheme text]);
    [self.view addSubview:title];
    [title.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
    [title.heightAnchor constraintEqualToConstant:48].active = YES;
    [title.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50].active = YES;

    UILabel *subtitle = TLLabel(@"本地存储 · 可导出备份到任意位置", 15, UIFontWeightRegular, [TLTheme sub]);
    [self.view addSubview:subtitle];
    [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor].active = YES;
    [subtitle.heightAnchor constraintEqualToConstant:24].active = YES;
    [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2].active = YES;

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
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
    [_stack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor constant:16].active = YES;
    [_stack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor constant:-16].active = YES;
    [_stack.widthAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.widthAnchor constant:-32].active = YES;

    // 完成情况：三栏数据 + 进度条
    [self addGroupTitle:@"完成情况"];
    TLCardView *statsCard = [[TLCardView alloc] init];
    [_stack addArrangedSubview:statsCard];

    UIView *statsRow = [[UIView alloc] init];
    statsRow.translatesAutoresizingMaskIntoConstraints = NO;
    [statsCard addSubview:statsRow];
    [statsRow.topAnchor constraintEqualToAnchor:statsCard.topAnchor constant:20].active = YES;
    [statsRow.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:16].active = YES;
    [statsRow.trailingAnchor constraintEqualToAnchor:statsCard.trailingAnchor constant:-16].active = YES;
    [statsRow.heightAnchor constraintEqualToConstant:58].active = YES;

    _pendingValueLabel = TLLabel(@"0", 26, UIFontWeightBlack, [TLTheme accent]);
    _doneValueLabel = TLLabel(@"0", 26, UIFontWeightBlack, [TLTheme green]);
    _rateValueLabel = TLLabel(@"0%", 26, UIFontWeightBlack, [TLTheme purple]);

    UIView *pendingColumn = [self statColumnWithValueLabel:_pendingValueLabel caption:@"待完成"];
    UIView *doneColumn = [self statColumnWithValueLabel:_doneValueLabel caption:@"已完成"];
    UIView *rateColumn = [self statColumnWithValueLabel:_rateValueLabel caption:@"完成率"];

    UIView *divider1 = [[UIView alloc] init];
    divider1.backgroundColor = [TLTheme divider];
    divider1.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *divider2 = [[UIView alloc] init];
    divider2.backgroundColor = [TLTheme divider];
    divider2.translatesAutoresizingMaskIntoConstraints = NO;

    [statsRow addSubview:pendingColumn];
    [statsRow addSubview:divider1];
    [statsRow addSubview:doneColumn];
    [statsRow addSubview:divider2];
    [statsRow addSubview:rateColumn];

    [pendingColumn.leadingAnchor constraintEqualToAnchor:statsRow.leadingAnchor].active = YES;
    [pendingColumn.topAnchor constraintEqualToAnchor:statsRow.topAnchor].active = YES;
    [pendingColumn.bottomAnchor constraintEqualToAnchor:statsRow.bottomAnchor].active = YES;

    [divider1.leadingAnchor constraintEqualToAnchor:pendingColumn.trailingAnchor].active = YES;
    [divider1.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor].active = YES;
    [divider1.widthAnchor constraintEqualToConstant:1].active = YES;
    [divider1.heightAnchor constraintEqualToConstant:34].active = YES;

    [doneColumn.leadingAnchor constraintEqualToAnchor:divider1.trailingAnchor].active = YES;
    [doneColumn.topAnchor constraintEqualToAnchor:statsRow.topAnchor].active = YES;
    [doneColumn.bottomAnchor constraintEqualToAnchor:statsRow.bottomAnchor].active = YES;
    [doneColumn.widthAnchor constraintEqualToAnchor:pendingColumn.widthAnchor].active = YES;

    [divider2.leadingAnchor constraintEqualToAnchor:doneColumn.trailingAnchor].active = YES;
    [divider2.centerYAnchor constraintEqualToAnchor:statsRow.centerYAnchor].active = YES;
    [divider2.widthAnchor constraintEqualToConstant:1].active = YES;
    [divider2.heightAnchor constraintEqualToConstant:34].active = YES;

    [rateColumn.leadingAnchor constraintEqualToAnchor:divider2.trailingAnchor].active = YES;
    [rateColumn.trailingAnchor constraintEqualToAnchor:statsRow.trailingAnchor].active = YES;
    [rateColumn.topAnchor constraintEqualToAnchor:statsRow.topAnchor].active = YES;
    [rateColumn.bottomAnchor constraintEqualToAnchor:statsRow.bottomAnchor].active = YES;
    [rateColumn.widthAnchor constraintEqualToAnchor:pendingColumn.widthAnchor].active = YES;

    _progressBar = [[TLProgressBar alloc] init];
    [statsCard addSubview:_progressBar];
    [_progressBar.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:16].active = YES;
    [_progressBar.trailingAnchor constraintEqualToAnchor:statsCard.trailingAnchor constant:-16].active = YES;
    [_progressBar.topAnchor constraintEqualToAnchor:statsRow.bottomAnchor constant:18].active = YES;

    _countLabel = TLLabel(@"", 13, UIFontWeightRegular, [TLTheme sub]);
    _countLabel.numberOfLines = 0;
    [statsCard addSubview:_countLabel];
    [_countLabel.leadingAnchor constraintEqualToAnchor:statsCard.leadingAnchor constant:16].active = YES;
    [_countLabel.trailingAnchor constraintEqualToAnchor:statsCard.trailingAnchor constant:-16].active = YES;
    [_countLabel.topAnchor constraintEqualToAnchor:_progressBar.bottomAnchor constant:10].active = YES;
    [_countLabel.bottomAnchor constraintEqualToAnchor:statsCard.bottomAnchor constant:-20].active = YES;

    // 提醒
    [self addGroupTitle:@"提醒"];
    _remindRow = [[TLRowView alloc] initWithTitle:@"截止前提醒" icon:@"bell.fill" tint:[TLTheme orange]];
    [_remindRow addTarget:self action:@selector(openRemind) forControlEvents:UIControlEventTouchUpInside];
    _remindRow.showsDivider = NO;
    [self addCardWithRows:@[_remindRow]];

    // 外观
    [self addGroupTitle:@"外观"];
    _appearanceRow = [[TLRowView alloc] initWithTitle:@"主题色" icon:@"paintpalette.fill" tint:[TLTheme accent]];
    [_appearanceRow addTarget:self action:@selector(openAppearance) forControlEvents:UIControlEventTouchUpInside];
    _appearanceRow.showsDivider = NO;
    [self addCardWithRows:@[_appearanceRow]];

    // 数据管理
    [self addGroupTitle:@"数据管理"];
    _exportRow = [[TLRowView alloc] initWithTitle:@"导出数据" icon:@"arrow.up.circle.fill" tint:[TLTheme accent]];
    [_exportRow addTarget:self action:@selector(exportData) forControlEvents:UIControlEventTouchUpInside];
    _exportRow.showsDivider = YES;

    TLRowView *importRow = [[TLRowView alloc] initWithTitle:@"导入数据" icon:@"arrow.down.circle.fill" tint:[TLTheme purple]];
    [importRow addTarget:self action:@selector(importData) forControlEvents:UIControlEventTouchUpInside];
    [importRow setDetailText:@"合并"];
    importRow.showsDivider = YES;

    _clearDoneRow = [[TLRowView alloc] initWithTitle:@"清空已完成" icon:@"trash.fill" tint:[TLTheme green]];
    [_clearDoneRow addTarget:self action:@selector(clearDoneTapped) forControlEvents:UIControlEventTouchUpInside];
    _clearDoneRow.showsDivider = YES;

    _clearAllRow = [[TLRowView alloc] initWithTitle:@"清空全部待办" icon:@"trash.fill" tint:[TLTheme red]];
    [_clearAllRow addTarget:self action:@selector(clearAllTapped) forControlEvents:UIControlEventTouchUpInside];
    _clearAllRow.showsDivider = NO;

    [self addCardWithRows:@[_exportRow, importRow, _clearDoneRow, _clearAllRow]];

    UILabel *hint = TLLabel(@"导出时可选择任意文件夹；导入会按记录合并，不会覆盖本地数据。", 13, UIFontWeightRegular, [TLTheme hint]);
    hint.numberOfLines = 0;
    UIView *hintWrapper = [[UIView alloc] init];
    hintWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    [hintWrapper addSubview:hint];
    [hint.leadingAnchor constraintEqualToAnchor:hintWrapper.leadingAnchor constant:4].active = YES;
    [hint.trailingAnchor constraintEqualToAnchor:hintWrapper.trailingAnchor constant:-4].active = YES;
    [hint.topAnchor constraintEqualToAnchor:hintWrapper.topAnchor constant:14].active = YES;
    [hint.bottomAnchor constraintEqualToAnchor:hintWrapper.bottomAnchor].active = YES;
    [_stack addArrangedSubview:hintWrapper];

    // 关于
    [self addGroupTitle:@"关于"];
    TLInfoRowView *nameRow = [[TLInfoRowView alloc] initWithTitle:@"应用名称" value:@"今日事" action:NO];
    nameRow.showsDivider = YES;
    TLInfoRowView *versionRow = [[TLInfoRowView alloc] initWithTitle:@"当前版本" value:[NSString stringWithFormat:@"v%@", TLAppVersion] action:NO];
    versionRow.showsDivider = YES;
    TLInfoRowView *authorRow = [[TLInfoRowView alloc] initWithTitle:@"作者" value:@"酷安 @然后啊然后" action:NO];
    authorRow.showsDivider = YES;
    TLInfoRowView *disclaimerRow = [[TLInfoRowView alloc] initWithTitle:@"免责声明" value:@"查看" action:YES];
    [disclaimerRow addTarget:self action:@selector(openDisclaimer) forControlEvents:UIControlEventTouchUpInside];
    disclaimerRow.showsDivider = YES;
    TLInfoRowView *thanksRow = [[TLInfoRowView alloc] initWithTitle:@"开源致谢" value:@"查看" action:YES];
    [thanksRow addTarget:self action:@selector(openAcknowledgments) forControlEvents:UIControlEventTouchUpInside];
    thanksRow.showsDivider = NO;
    [self addCardWithRows:@[nameRow, versionRow, authorRow, disclaimerRow, thanksRow]];

    UILabel *tagline = TLLabel(@"今日事 · 无需登录，打开即用", 13, UIFontWeightRegular, [TLTheme hint]);
    tagline.textAlignment = NSTextAlignmentCenter;
    UIView *taglineWrapper = [[UIView alloc] init];
    taglineWrapper.translatesAutoresizingMaskIntoConstraints = NO;
    tagline.translatesAutoresizingMaskIntoConstraints = NO;
    [taglineWrapper addSubview:tagline];
    [tagline.leadingAnchor constraintEqualToAnchor:taglineWrapper.leadingAnchor].active = YES;
    [tagline.trailingAnchor constraintEqualToAnchor:taglineWrapper.trailingAnchor].active = YES;
    [tagline.topAnchor constraintEqualToAnchor:taglineWrapper.topAnchor constant:14].active = YES;
    [tagline.bottomAnchor constraintEqualToAnchor:taglineWrapper.bottomAnchor constant:-8].active = YES;
    [_stack addArrangedSubview:taglineWrapper];
}

- (void)addGroupTitle:(NSString *)text {
    UILabel *label = TLLabel(text, 15, UIFontWeightSemibold, [TLTheme sub]);
    label.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *wrapper = [[UIView alloc] init];
    wrapper.translatesAutoresizingMaskIntoConstraints = NO;
    [wrapper addSubview:label];
    [label.leadingAnchor constraintEqualToAnchor:wrapper.leadingAnchor constant:4].active = YES;
    [label.topAnchor constraintEqualToAnchor:wrapper.topAnchor constant:18].active = YES;
    [label.bottomAnchor constraintEqualToAnchor:wrapper.bottomAnchor constant:-14].active = YES;
    [wrapper.heightAnchor constraintEqualToConstant:54].active = YES;
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
    NSInteger pending = MAX(0, total - done);
    NSInteger percent = (total == 0) ? 0 : (done * 100) / total;

    UIColor *accent = [TLTheme accent];
    self.pendingValueLabel.text = [NSString stringWithFormat:@"%ld", (long)pending];
    self.pendingValueLabel.textColor = accent;
    self.doneValueLabel.text = [NSString stringWithFormat:@"%ld", (long)done];
    self.rateValueLabel.text = [NSString stringWithFormat:@"%ld%%", (long)percent];
    self.countLabel.text = (total == 0 ? @"还没有记录，先去「待办」写一条吧"
                                        : [NSString stringWithFormat:@"已经完成 %ld / %ld 项", (long)done, (long)total]);
    self.progressBar.progress = (total == 0) ? 0 : (CGFloat)done / (CGFloat)total;
    [self.progressBar refreshAccent];

    [self.appearanceRow setDetailText:[TLTheme accentNameAtIndex:[TLTheme accentIndex]]];
    [self.appearanceRow setIconTintColor:accent];
    [self.remindRow setDetailText:TLReminderLabelForMinutes(TLReminderLeadMinutes())];
    [self.exportRow setDetailText:[NSString stringWithFormat:@"%ld 项", (long)total]];
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
    vc.onSelectTab = ^(NSInteger index) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            [weakSelf.host selectTabIndex:index];
        }];
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
    vc.onSelectTab = ^(NSInteger index) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            [weakSelf.host selectTabIndex:index];
        }];
    };
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)openDisclaimer {
    NSString *message = @"1. 「今日事」是一款完全离线的本地待办工具，不会联网，不收集、不上传任何个人信息，所有数据仅保存在您的设备上。\n\n"
                        "2. 导出功能生成的备份文件保存在您自行选择的位置，请注意妥善保管，避免隐私泄露。\n\n"
                        "3. 本应用仅供个人学习与日常使用，请勿用于商业用途。本 iOS 版本为非官方移植，未获得 Android 原版作者正式授权，原作者如有异议将立即停止分发并删除。\n\n"
                        "4. 开发者不对因使用本应用造成的任何数据丢失或损失承担责任，重要数据请定期导出备份。\n\n"
                        "5. 继续使用本应用即表示您已阅读并同意以上内容。\n\n"
                        "—— 原版作者：酷安 @然后啊然后；iOS 移植：Jacky";
    [self showTextDialogWithTitle:@"免责声明" body:message];
}

- (void)openAcknowledgments {
    NSString *message = @"「今日事」原版基于以下开源项目构建：\n\n"
                        "· mochi-compose（MIT License）\n  提供全套 UI 组件与动效（github.com/feice11/mochi-compose）\n\n"
                        "· Jetpack Compose / AndroidX（Apache License 2.0）\n  Google 现代化 Android UI 框架\n\n"
                        "· Kotlin（Apache License 2.0）\n  JetBrains 出品的编程语言\n\n"
                        "iOS 移植使用 Apple UIKit / Foundation；交叉构建使用 theos/sdks 与 ldid。\n\n"
                        "原版作者：酷安 @然后啊然后；iOS 移植：Jacky";
    [self showTextDialogWithTitle:@"开源致谢" body:message];
}

- (void)showTextDialogWithTitle:(NSString *)title body:(NSString *)body {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                  message:body
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
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
        [self showToast:@"还没有已完成的任务"];
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
