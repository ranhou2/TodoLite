#import "TLMainViewController.h"
#import "TLTheme.h"
#import "TLUIKitAdditions.h"
#import "TLReminders.h"
#import "TLListViewController.h"
#import "TLProfileViewController.h"
#import "TLEditorViewController.h"

#pragma mark - TLTabBarView

@interface TLTabBarView ()
@property (nonatomic, strong) NSMutableArray<UIControl *> *items;
@property (nonatomic, strong) NSMutableArray<UIView *> *pills;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *icons;
@property (nonatomic, strong) NSMutableArray<UILabel *> *labels;
@end

@implementation TLTabBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 29;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        TLApplyShadow(self, [UIColor blackColor], 18, 0.08, 6);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _items = [NSMutableArray array];
        _pills = [NSMutableArray array];
        _icons = [NSMutableArray array];
        _labels = [NSMutableArray array];
        [self buildItems];
    }
    return self;
}

- (void)buildItems {
    NSArray<NSString *> *symbols = @[@"list.bullet", @"checkmark.circle.fill", @"person.fill"];
    NSArray<NSString *> *titles = @[@"待办", @"完成", @"我的"];
    for (NSInteger i = 0; i < 3; i++) {
        UIControl *item = [[UIControl alloc] init];
        item.tag = i;
        item.translatesAutoresizingMaskIntoConstraints = YES;
        [item addTarget:self action:@selector(itemTapped:) forControlEvents:UIControlEventTouchUpInside];

        UIView *pill = [[UIView alloc] init];
        pill.layer.cornerRadius = 22;
        pill.userInteractionEnabled = NO;
        [item addSubview:pill];

        UIImageView *icon = TLImageView(symbols[(NSUInteger)i], 20, [TLTheme iconTint]);
        icon.translatesAutoresizingMaskIntoConstraints = YES;
        [item addSubview:icon];

        UILabel *label = TLLabel(titles[(NSUInteger)i], 13, UIFontWeightSemibold, [TLTheme sub]);
        label.translatesAutoresizingMaskIntoConstraints = YES;
        [item addSubview:label];

        [self addSubview:item];
        [_items addObject:item];
        [_pills addObject:pill];
        [_icons addObject:icon];
        [_labels addObject:label];
    }
}

- (void)itemTapped:(UIControl *)sender {
    if (self.onSelect != nil) self.onSelect(sender.tag);
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [self setNeedsLayout];
}

- (void)refreshColors {
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat padding = 5.0;
    CGFloat itemWidth = (self.bounds.size.width - padding * 2) / 3.0;
    CGFloat itemHeight = self.bounds.size.height - padding * 2;
    UIColor *accent = [TLTheme accent];

    for (NSInteger i = 0; i < (NSInteger)self.items.count; i++) {
        UIControl *item = self.items[(NSUInteger)i];
        item.frame = CGRectMake(padding + itemWidth * i, padding, itemWidth, itemHeight);
        UIView *pill = self.pills[(NSUInteger)i];
        UIImageView *icon = self.icons[(NSUInteger)i];
        UILabel *label = self.labels[(NSUInteger)i];
        BOOL selected = (i == self.selectedIndex);

        pill.frame = CGRectMake(0, 0, itemWidth, itemHeight);
        pill.layer.cornerRadius = 24;
        pill.backgroundColor = [TLTheme tabSelected];
        pill.hidden = !selected;

        label.hidden = !selected;
        label.textColor = accent;
        [label sizeToFit];

        icon.tintColor = selected ? accent : [TLTheme iconTint];
        CGFloat iconWidth = selected ? 20.0 : 22.0;
        if (selected) {
            CGFloat groupWidth = iconWidth + 7.0 + label.bounds.size.width;
            CGFloat startX = (itemWidth - groupWidth) / 2.0;
            icon.frame = CGRectMake(startX, (itemHeight - iconWidth) / 2.0, iconWidth, iconWidth);
            label.frame = CGRectMake(startX + iconWidth + 7.0,
                                     (itemHeight - label.bounds.size.height) / 2.0,
                                     label.bounds.size.width,
                                     label.bounds.size.height);
        } else {
            icon.frame = CGRectMake((itemWidth - iconWidth) / 2.0, (itemHeight - iconWidth) / 2.0, iconWidth, iconWidth);
            label.frame = CGRectZero;
        }
    }
}

@end

#pragma mark - TLMainViewController

@interface TLMainViewController ()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) TLTabBarView *tabBar;
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, strong) TLListViewController *pendingList;
@property (nonatomic, strong) TLListViewController *doneList;
@property (nonatomic, strong) TLProfileViewController *profile;
@property (nonatomic, strong) UIViewController *currentChild;
@property (nonatomic, assign) NSInteger currentTab;
@property (nonatomic, assign) BOOL welcomeShown;
@end

@implementation TLMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TLTheme bg];
    self.currentTab = 0;

    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentView];

    _tabBar = [[TLTabBarView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    _tabBar.onSelect = ^(NSInteger index) {
        [weakSelf selectTabIndex:index];
    };
    [self.view addSubview:_tabBar];

    _fab = [UIButton buttonWithType:UIButtonTypeCustom];
    _fab.backgroundColor = [TLTheme accent];
    _fab.tintColor = [UIColor whiteColor];
    _fab.layer.cornerRadius = 29;
    _fab.layer.cornerCurve = kCACornerCurveContinuous;
    [_fab setImage:TLImage(@"plus", 28) forState:UIControlStateNormal];
    _fab.translatesAutoresizingMaskIntoConstraints = NO;
    [_fab addTarget:self action:@selector(addTapped) forControlEvents:UIControlEventTouchUpInside];
    TLApplyShadow(_fab, [TLTheme accent], 16, 0.35, 8);
    [self.view addSubview:_fab];

    [_contentView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    [_contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_contentView.bottomAnchor constraintEqualToAnchor:_tabBar.topAnchor constant:-8].active = YES;

    [_tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18].active = YES;
    [_tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18].active = YES;
    [_tabBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8].active = YES;
    [_tabBar.heightAnchor constraintEqualToConstant:58].active = YES;

    [_fab.widthAnchor constraintEqualToConstant:58].active = YES;
    [_fab.heightAnchor constraintEqualToConstant:58].active = YES;
    [_fab.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
    [_fab.bottomAnchor constraintEqualToAnchor:_tabBar.topAnchor constant:-24].active = YES;

    [self buildChildren];
    [self selectTabIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeChanged)
                                                 name:TLTodoStoreDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged)
                                                 name:TLThemeDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.welcomeShown) {
        self.welcomeShown = YES;
        [self showWelcomeIfNeeded];
    }
}

- (void)showWelcomeIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"tl_welcomed"]) return;
    [defaults setBool:YES forKey:@"tl_welcomed"];
    [defaults synchronize];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"欢迎使用 今日事"
                                                                  message:@"无需登录，打开即用。所有数据只保存在本机，不联网、不收集任何信息。"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"开始使用" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)buildChildren {
    _pendingList = [[TLListViewController alloc] initWithMode:TLListModePending];
    _pendingList.host = self;

    _doneList = [[TLListViewController alloc] initWithMode:TLListModeDone];
    _doneList.host = self;

    _profile = [[TLProfileViewController alloc] init];
    _profile.host = self;
}

- (UIViewController *)childForTab:(NSInteger)index {
    if (index == 1) return self.doneList;
    if (index == 2) return self.profile;
    return self.pendingList;
}

- (void)selectTabIndex:(NSInteger)index {
    if (index < 0 || index > 2) return;
    self.currentTab = index;
    self.tabBar.selectedIndex = index;

    UIViewController *target = [self childForTab:index];
    if (target != self.currentChild) {
        if (self.currentChild.parentViewController == self) {
            [self.currentChild willMoveToParentViewController:nil];
            [self.currentChild.view removeFromSuperview];
            [self.currentChild removeFromParentViewController];
        }

        UIView *childView = target.view;
        childView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:childView];
        [childView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
        [childView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [childView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [childView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        if (target.parentViewController != self) {
            [self addChildViewController:target];
        }
        [target didMoveToParentViewController:self];
        self.currentChild = target;
    }

    self.fab.hidden = (index != 0);
    if ([target respondsToSelector:@selector(refreshContent)]) {
        [(id)target refreshContent];
    }
}

- (void)refreshInterface {
    self.tabBar.selectedIndex = self.currentTab;
    [self.tabBar refreshColors];
    self.fab.backgroundColor = [TLTheme accent];
    TLApplyShadow(self.fab, [TLTheme accent], 16, 0.35, 8);

    if ([self.currentChild respondsToSelector:@selector(refreshContent)]) {
        [(id)self.currentChild refreshContent];
    }
}

- (void)storeChanged {
    [self refreshInterface];
    TLRemindersReschedule();
}

- (void)themeChanged {
    [self refreshInterface];
}

- (void)addTapped {
    [self openEditorForTodo:nil];
}

- (void)openEditorForTodo:(TLTodo *)todo {
    TLEditorViewController *editor = [[TLEditorViewController alloc] initWithTodo:todo];
    __weak typeof(self) weakSelf = self;
    editor.onFinished = ^(NSString *message) {
        [weakSelf dismissViewControllerAnimated:YES completion:^{
            if (message.length > 0) [weakSelf showToastMessage:message];
            [weakSelf refreshInterface];
        }];
    };
    editor.modalPresentationStyle = UIModalPresentationPageSheet;
    if ([editor respondsToSelector:@selector(sheetPresentationController)]) {
        UISheetPresentationController *sheet = editor.sheetPresentationController;
        if (sheet != nil) {
            sheet.detents = @[[UISheetPresentationControllerDetent largeDetent]];
            sheet.prefersGrabberVisible = YES;
            sheet.preferredCornerRadius = 28;
        }
    }
    [self presentViewController:editor animated:YES completion:nil];
}

- (void)showToastMessage:(NSString *)message {
    [TLToast showMessage:message];
}

- (void)showToastMessage:(NSString *)message actionTitle:(NSString *)actionTitle handler:(void (^)(void))handler {
    [TLToast showMessage:message actionTitle:actionTitle handler:handler];
}

@end
