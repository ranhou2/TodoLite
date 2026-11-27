#import "TLListViewController.h"
#import "TLMainViewController.h"
#import "TLTheme.h"
#import "TLUIKitAdditions.h"
#import "TLEditorViewController.h"

#pragma mark - TLTodoCell

@interface TLTodoCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UIImageView *chevronView;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, copy) void (^onToggle)(void);
- (void)configureWithTodo:(TLTodo *)todo isFirst:(BOOL)isFirst isLast:(BOOL)isLast;
@end

@interface TLTodoCell ()
@property (nonatomic, strong) NSLayoutConstraint *cardTop;
@end

@implementation TLTodoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = [UIColor whiteColor];
        _cardView.layer.cornerCurve = kCACornerCurveContinuous;
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        _checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _checkButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_checkButton addTarget:self action:@selector(toggleTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_checkButton];

        _titleLabel = TLLabel(@"", 16, UIFontWeightMedium, [TLTheme text]);
        _titleLabel.numberOfLines = 2;
        [self.contentView addSubview:_titleLabel];

        _metaLabel = TLLabel(@"", 13, UIFontWeightRegular, [TLTheme sub]);
        [self.contentView addSubview:_metaLabel];

        _chevronView = TLImageView(@"chevron.right", 12, [TLTheme chevron]);
        [self.contentView addSubview:_chevronView];

        _separator = TLHairline();
        [self.contentView addSubview:_separator];

        [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
        [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
        [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;

        [_checkButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16].active = YES;
        [_checkButton.widthAnchor constraintEqualToConstant:26].active = YES;
        [_checkButton.heightAnchor constraintEqualToConstant:26].active = YES;
        [_checkButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;

        [_titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:14].active = YES;
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.checkButton.trailingAnchor constant:14].active = YES;
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.chevronView.leadingAnchor constant:-12].active = YES;

        [_metaLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:3].active = YES;
        [_metaLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor].active = YES;
        [_metaLabel.trailingAnchor constraintEqualToAnchor:self.titleLabel.trailingAnchor].active = YES;
        [_metaLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-14].active = YES;

        [_chevronView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16].active = YES;
        [_chevronView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor].active = YES;
        [_chevronView.widthAnchor constraintEqualToConstant:14].active = YES;
        [_chevronView.heightAnchor constraintEqualToConstant:16].active = YES;

        [_separator.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:56].active = YES;
        [_separator.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
        [_separator.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [_separator.heightAnchor constraintEqualToConstant:0.5].active = YES;
    }
    return self;
}

- (void)toggleTapped {
    if (self.onToggle != nil) self.onToggle();
}

- (void)configureWithTodo:(TLTodo *)todo isFirst:(BOOL)isFirst isLast:(BOOL)isLast {
    self.cardView.layer.cornerRadius = 26;
    if (isFirst && isLast) {
        self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                                            kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else if (isFirst) {
        self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    } else if (isLast) {
        self.cardView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    } else {
        self.cardView.layer.maskedCorners = 0;
    }
    self.separator.hidden = isLast;

    UIColor *accent = [TLTheme accent];
    self.checkButton.layer.cornerRadius = 13;
    self.checkButton.layer.borderWidth = 1.5;
    self.checkButton.layer.borderColor = (todo.done ? accent : [TLTheme colorWithHex:0xC7C7CC]).CGColor;
    self.checkButton.backgroundColor = todo.done ? accent : [UIColor clearColor];
    UIImage *checkImage = todo.done ? TLImage(@"checkmark", 13) : nil;
    [self.checkButton setImage:checkImage forState:UIControlStateNormal];
    self.checkButton.tintColor = [UIColor whiteColor];

    self.titleLabel.text = todo.title;
    self.titleLabel.textColor = todo.done ? [TLTheme sub] : [TLTheme text];
    if (todo.done) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:todo.title ?: @"" attributes:@{
            NSFontAttributeName: [TLTheme font:16 weight:UIFontWeightMedium],
            NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle),
            NSStrikethroughColorAttributeName: [TLTheme hint],
            NSForegroundColorAttributeName: [TLTheme sub]
        }];
        self.titleLabel.attributedText = attr;
    } else {
        self.titleLabel.text = todo.title;
    }
    self.metaLabel.attributedText = [self attributedMetaForTodo:todo];
}

- (NSAttributedString *)attributedMetaForTodo:(TLTodo *)todo {
    NSString *dueText = nil;
    UIColor *dueColor = [TLTheme sub];
    if (!todo.done && todo.due.length > 0) {
        NSNumber *days = [TLDue daysUntilText:todo.due];
        if (days == nil) {
            dueText = [NSString stringWithFormat:@"截止 %@", todo.due];
            dueColor = [TLTheme accent];
        } else if (days.integerValue < 0) {
            dueText = @"已逾期";
            dueColor = [TLTheme red];
        } else if (days.integerValue == 0) {
            dueText = @"今天到期";
            dueColor = [TLTheme orange];
        } else if (days.integerValue == 1) {
            dueText = @"明天到期";
            dueColor = [TLTheme orange];
        } else {
            dueText = [NSString stringWithFormat:@"截止 %@", todo.due];
            dueColor = [TLTheme accent];
        }
    }

    NSString *note = todo.note ?: @"";
    if (note.length == 0 && todo.done && todo.doneAt > 0) {
        note = [NSString stringWithFormat:@"完成于 %@", [TLDue displayTimeForMillis:todo.doneAt]];
    }

    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    NSDictionary *base = @{NSFontAttributeName: [TLTheme font:13], NSForegroundColorAttributeName: [TLTheme sub]};
    if (dueText.length > 0) {
        [result appendAttributedString:[[NSAttributedString alloc] initWithString:dueText attributes:@{
            NSFontAttributeName: [TLTheme font:13],
            NSForegroundColorAttributeName: dueColor
        }]];
        if (note.length > 0) {
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:@" · " attributes:base]];
        }
    }
    if (note.length > 0) {
        [result appendAttributedString:[[NSAttributedString alloc] initWithString:note attributes:base]];
    }
    return result;
}

@end

#pragma mark - TLEmptyCardView

@interface TLEmptyCardView : UIView
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
- (void)configureSymbol:(NSString *)symbol tint:(UIColor *)tint title:(NSString *)title desc:(NSString *)desc;
@end

@implementation TLEmptyCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 26;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.translatesAutoresizingMaskIntoConstraints = NO;

        _iconView = TLImageView(@"list.bullet", 26, [TLTheme accent]);
        [self addSubview:_iconView];

        _titleLabel = TLLabel(@"", 17, UIFontWeightSemibold, [TLTheme text]);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_titleLabel];

        _descLabel = TLLabel(@"", 14, UIFontWeightRegular, [TLTheme sub]);
        _descLabel.textAlignment = NSTextAlignmentCenter;
        _descLabel.numberOfLines = 2;
        [self addSubview:_descLabel];

        [_iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:26].active = YES;
        [_iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_iconView.widthAnchor constraintEqualToConstant:30].active = YES;
        [_iconView.heightAnchor constraintEqualToConstant:30].active = YES;

        [_titleLabel.topAnchor constraintEqualToAnchor:self.iconView.bottomAnchor constant:12].active = YES;
        [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:20].active = YES;
        [_titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-20].active = YES;

        [_descLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6].active = YES;
        [_descLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24].active = YES;
        [_descLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24].active = YES;
        [_descLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-26].active = YES;
    }
    return self;
}

- (void)configureSymbol:(NSString *)symbol tint:(UIColor *)tint title:(NSString *)title desc:(NSString *)desc {
    self.iconView.image = TLImage(symbol, 26);
    self.iconView.tintColor = tint;
    self.titleLabel.text = title;
    self.descLabel.text = desc;
}

@end

#pragma mark - TLListViewController

@interface TLListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIView *versionChip;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TLEmptyCardView *emptyCard;
@property (nonatomic, strong) UILabel *groupLabel;
@property (nonatomic, strong) UIView *tableHeader;
@property (nonatomic, strong) UIView *tableFooter;
@property (nonatomic, strong) NSArray<TLTodo *> *rows;
@end

@implementation TLListViewController

- (instancetype)initWithMode:(TLListMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _mode = mode;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    _titleLabel = TLLabel(@"", 34, UIFontWeightBold, [TLTheme text]);
    [self.view addSubview:_titleLabel];

    _subtitleLabel = TLLabel(@"", 14, UIFontWeightRegular, [TLTheme sub]);
    [self.view addSubview:_subtitleLabel];

    if (self.mode == TLListModePending) {
        _versionChip = [[UIView alloc] init];
        _versionChip.backgroundColor = [TLTheme chipBg];
        _versionChip.layer.cornerRadius = 12;
        _versionChip.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_versionChip];

        UILabel *version = TLLabel([NSString stringWithFormat:@"v%@", TLAppVersion], 12, UIFontWeightMedium, [TLTheme colorWithHex:0x8A8A8E]);
        version.translatesAutoresizingMaskIntoConstraints = NO;
        [_versionChip addSubview:version];
        [version.topAnchor constraintEqualToAnchor:_versionChip.topAnchor constant:4].active = YES;
        [version.bottomAnchor constraintEqualToAnchor:_versionChip.bottomAnchor constant:-4].active = YES;
        [version.leadingAnchor constraintEqualToAnchor:_versionChip.leadingAnchor constant:10].active = YES;
        [version.trailingAnchor constraintEqualToAnchor:_versionChip.trailingAnchor constant:-10].active = YES;

        [_versionChip.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
        [_versionChip.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:2].active = YES;
        [_versionChip.heightAnchor constraintEqualToConstant:24].active = YES;

        [_titleLabel.topAnchor constraintEqualToAnchor:_versionChip.bottomAnchor constant:8].active = YES;
    } else {
        [_titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10].active = YES;
    }

    [_titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;

    [_subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2].active = YES;
    [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor].active = YES;
    [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 72;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 96, 0);
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tableView];

    [_tableView.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:12].active = YES;
    [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
    [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    _emptyCard = [[TLEmptyCardView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_emptyCard];
    [_emptyCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20].active = YES;
    [_emptyCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20].active = YES;
    [_emptyCard.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:24].active = YES;

    [self refreshContent];
}

- (void)refreshContent {
    if (self.mode == TLListModePending) {
        self.rows = [TLTodoStore shared].pendingItems;
        NSArray<TLTodo *> *all = [TLTodoStore shared].allItems;
        NSArray<TLTodo *> *done = [TLTodoStore shared].doneItems;
        NSInteger pendingCount = (NSInteger)self.rows.count;
        NSInteger total = (NSInteger)all.count;
        NSInteger doneCount = (NSInteger)done.count;
        NSInteger overdue = 0;
        for (TLTodo *todo in self.rows) {
            NSNumber *days = [TLDue daysUntilText:todo.due];
            if (days != nil && days.integerValue < 0) overdue += 1;
        }

        NSString *subtitle;
        if (total == 0) {
            subtitle = @"还没有待办，先写下第一件事";
        } else if (pendingCount == 0) {
            subtitle = @"全部完成，给自己一点奖励";
        } else if (overdue > 0) {
            subtitle = [NSString stringWithFormat:@"有 %ld 项已逾期，先处理它们", (long)overdue];
        } else {
            subtitle = [NSString stringWithFormat:@"还有 %ld 项待完成", (long)pendingCount];
        }
        self.subtitleLabel.text = subtitle;
        self.titleLabel.text = @"待办";
        self.groupLabel.text = [NSString stringWithFormat:@"待完成 · %ld", (long)pendingCount];
        [self rebuildFooterWithDoneCount:doneCount];
        self.emptyCard.hidden = (pendingCount > 0);
        if (pendingCount == 0) {
            if (total == 0) {
                [self.emptyCard configureSymbol:@"list.bullet" tint:[TLTheme accent] title:@"开始今天的清单" desc:@"点右下角的 + 新建一条待办。"];
            } else {
                [self.emptyCard configureSymbol:@"checkmark.circle" tint:[TLTheme green] title:@"任务都完成了" desc:@"新增一条，或去「完成」查看记录。"];
            }
        }
    } else {
        self.rows = [TLTodoStore shared].doneItems;
        NSInteger doneCount = (NSInteger)self.rows.count;
        self.titleLabel.text = @"完成";
        self.subtitleLabel.text = (doneCount == 0) ? @"还没有完成的任务"
                                                   : [NSString stringWithFormat:@"共完成 %ld 项，继续保持", (long)doneCount];
        self.groupLabel.text = [NSString stringWithFormat:@"已完成 · %ld", (long)doneCount];
        [self rebuildFooterWithDoneCount:doneCount];
        self.emptyCard.hidden = (doneCount > 0);
        if (doneCount == 0) {
            [self.emptyCard configureSymbol:@"checkmark.circle" tint:[TLTheme green] title:@"这里空空的" desc:@"勾选待办后，任务会出现在这里。"];
        }
    }

    [self.tableView reloadData];
}

- (void)rebuildFooterWithDoneCount:(NSInteger)doneCount {
    if (self.rows.count == 0) {
        self.tableView.tableFooterView = nil;
        return;
    }
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 52)];
    footer.backgroundColor = [UIColor clearColor];

    if (self.mode == TLListModePending && doneCount > 0) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[NSString stringWithFormat:@"已完成 %ld 项   ›", (long)doneCount] forState:UIControlStateNormal];
        [button setTitleColor:[TLTheme sub] forState:UIControlStateNormal];
        button.titleLabel.font = [TLTheme font:14];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.frame = CGRectMake(4, 8, 320, 34);
        [button addTarget:self action:@selector(openDoneTab) forControlEvents:UIControlEventTouchUpInside];
        [footer addSubview:button];
    } else if (self.mode == TLListModeDone && doneCount > 0) {
        UILabel *hint = TLLabel(@"轻点圆圈可以把任务放回待办", 13, UIFontWeightRegular, [TLTheme hint]);
        hint.translatesAutoresizingMaskIntoConstraints = YES;
        hint.frame = CGRectMake(4, 12, 320, 24);
        [footer addSubview:hint];
    }
    self.tableView.tableFooterView = footer;
}

- (void)openDoneTab {
    if (self.host != nil) [self.host selectTabIndex:1];
}

#pragma mark UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.rows.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.rows.count > 0 ? 44 : 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.rows.count == 0) return nil;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44)];
    header.backgroundColor = [UIColor clearColor];
    _groupLabel = TLLabel(@"", 13, UIFontWeightMedium, [TLTheme sub]);
    _groupLabel.translatesAutoresizingMaskIntoConstraints = YES;
    _groupLabel.frame = CGRectMake(4, 12, tableView.bounds.size.width - 8, 22);
    [header addSubview:_groupLabel];
    if (self.mode == TLListModePending) {
        _groupLabel.text = [NSString stringWithFormat:@"待完成 · %ld", (long)self.rows.count];
    } else {
        _groupLabel.text = [NSString stringWithFormat:@"已完成 · %ld", (long)self.rows.count];
    }
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TLTodoCell";
    TLTodoCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[TLTodoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    TLTodo *todo = self.rows[(NSUInteger)indexPath.row];
    BOOL isFirst = (indexPath.row == 0);
    BOOL isLast = (indexPath.row == (NSInteger)self.rows.count - 1);
    [cell configureWithTodo:todo isFirst:isFirst isLast:isLast];

    __weak typeof(self) weakSelf = self;
    cell.onToggle = ^{
        TLTodoStore *store = [TLTodoStore shared];
        [store toggleTodo:todo];
        if (todo.done) {
            [weakSelf.host showToastMessage:@"已放回待办"];
        } else {
            [weakSelf.host showToastMessage:@"完成了一件，真不错"];
        }
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TLTodo *todo = self.rows[(NSUInteger)indexPath.row];
    if (self.host != nil) [self.host openEditorForTodo:todo];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLTodo *todo = self.rows[(NSUInteger)indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                         title:@"删除"
                                                                       handler:^(UIContextualAction *action,
                                                                                 UIView *sourceView,
                                                                                 void (^completionHandler)(BOOL)) {
        TLTodo *snapshot = todo;
        [[TLTodoStore shared] removeTodo:snapshot];
        [weakSelf.host showToastMessage:@"已删除" actionTitle:@"点此撤销" handler:^{
            [[TLTodoStore shared] restoreTodo:snapshot];
        }];
        completionHandler(YES);
    }];
    action.backgroundColor = [TLTheme red];
    return [UISwipeActionsConfiguration configurationWithActions:@[action]];
}

@end
