#import "TLEditorViewController.h"
#import "TLTheme.h"
#import "TLUIKitAdditions.h"

@interface TLEditorViewController () <UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, strong, nullable) TLTodo *editingTodo;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *noteView;
@property (nonatomic, strong) UILabel *notePlaceholder;
@property (nonatomic, strong) NSMutableArray<UIButton *> *dueChips;
@property (nonatomic, strong) UIView *calendarContainer;
@property (nonatomic, strong) NSLayoutConstraint *calendarHeight;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) TLPillButton *saveButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, copy) NSString *due;
@property (nonatomic, assign) BOOL deleting;
@property (nonatomic, strong) NSTimer *deleteResetTimer;
@end

@implementation TLEditorViewController

- (instancetype)initWithTodo:(TLTodo *)todo {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _editingTodo = todo;
        _due = todo.due ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TLTheme colorWithHex:0xF6F6F9];
    _dueChips = [NSMutableArray array];

    [self buildHeader];
    [self buildContent];
    [self buildActions];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)dealloc {
    [self.deleteResetTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark 头部

- (void)buildHeader {
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

    UILabel *title = TLLabel(self.editingTodo ? @"编辑待办" : @"新建待办", 17, UIFontWeightSemibold, [TLTheme text]);
    title.textAlignment = NSTextAlignmentCenter;
    [header addSubview:title];

    TLCircleIconButton *close = [[TLCircleIconButton alloc] initWithSymbol:@"xmark"];
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:close];

    [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:6].active = YES;
    [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [header.heightAnchor constraintEqualToConstant:44].active = YES;

    [close.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:16].active = YES;
    [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor].active = YES;

    [title.centerXAnchor constraintEqualToAnchor:header.centerXAnchor].active = YES;
    [title.centerYAnchor constraintEqualToAnchor:header.centerYAnchor].active = YES;
}

#pragma mark 表单

- (UILabel *)sectionTitle:(NSString *)text {
    UILabel *label = TLLabel(text, 15, UIFontWeightSemibold, [TLTheme sub]);
    return label;
}

- (void)buildContent {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:_scrollView];

    [_scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:50].active = YES;
    [_scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [_scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    _contentStack = [[UIStackView alloc] init];
    _contentStack.axis = UILayoutConstraintAxisVertical;
    _contentStack.spacing = 0;
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scrollView addSubview:_contentStack];

    [_contentStack.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor constant:8].active = YES;
    [_contentStack.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor constant:-24].active = YES;
    [_contentStack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor constant:16].active = YES;
    [_contentStack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor constant:-16].active = YES;
    [_contentStack.widthAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.widthAnchor constant:-32].active = YES;

    // 标题
    [self.contentStack addArrangedSubview:[self sectionTitle:@"标题"]];
    [self.contentStack setCustomSpacing:8 afterView:self.contentStack.arrangedSubviews.lastObject];

    UIView *titleBox = [[UIView alloc] init];
    titleBox.backgroundColor = [TLTheme fieldBg];
    titleBox.layer.cornerRadius = 24;
    titleBox.layer.cornerCurve = kCACornerCurveContinuous;
    titleBox.translatesAutoresizingMaskIntoConstraints = NO;
    [titleBox.heightAnchor constraintEqualToConstant:48].active = YES;
    [self.contentStack addArrangedSubview:titleBox];

    _titleField = [[UITextField alloc] init];
    _titleField.placeholder = @"要做什么？";
    _titleField.font = [TLTheme font:16];
    _titleField.textColor = [TLTheme text];
    _titleField.delegate = self;
    _titleField.translatesAutoresizingMaskIntoConstraints = NO;
    _titleField.text = self.editingTodo.title ?: @"";
    [_titleField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [titleBox addSubview:_titleField];
    [_titleField.leadingAnchor constraintEqualToAnchor:titleBox.leadingAnchor constant:16].active = YES;
    [_titleField.trailingAnchor constraintEqualToAnchor:titleBox.trailingAnchor constant:-16].active = YES;
    [_titleField.centerYAnchor constraintEqualToAnchor:titleBox.centerYAnchor].active = YES;

    // 备注
    [self.contentStack setCustomSpacing:18 afterView:titleBox];
    [self.contentStack addArrangedSubview:[self sectionTitle:@"备注"]];
    [self.contentStack setCustomSpacing:8 afterView:self.contentStack.arrangedSubviews.lastObject];

    UIView *noteBox = [[UIView alloc] init];
    noteBox.backgroundColor = [TLTheme fieldBg];
    noteBox.layer.cornerRadius = 20;
    noteBox.layer.cornerCurve = kCACornerCurveContinuous;
    noteBox.translatesAutoresizingMaskIntoConstraints = NO;
    [noteBox.heightAnchor constraintEqualToConstant:96].active = YES;
    [self.contentStack addArrangedSubview:noteBox];

    _noteView = [[UITextView alloc] init];
    _noteView.backgroundColor = [UIColor clearColor];
    _noteView.font = [TLTheme font:16];
    _noteView.textColor = [TLTheme text];
    _noteView.text = self.editingTodo.note ?: @"";
    _noteView.delegate = self;
    _noteView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
    _noteView.translatesAutoresizingMaskIntoConstraints = NO;
    [noteBox addSubview:_noteView];
    [_noteView.topAnchor constraintEqualToAnchor:noteBox.topAnchor].active = YES;
    [_noteView.bottomAnchor constraintEqualToAnchor:noteBox.bottomAnchor].active = YES;
    [_noteView.leadingAnchor constraintEqualToAnchor:noteBox.leadingAnchor constant:4].active = YES;
    [_noteView.trailingAnchor constraintEqualToAnchor:noteBox.trailingAnchor constant:-4].active = YES;

    _notePlaceholder = TLLabel(@"补充说明（可选）", 16, UIFontWeightRegular, [TLTheme colorWithHex:0xB0B0B6]);
    _notePlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    _notePlaceholder.hidden = (_noteView.text.length > 0);
    [noteBox addSubview:_notePlaceholder];
    [_notePlaceholder.leadingAnchor constraintEqualToAnchor:noteBox.leadingAnchor constant:17].active = YES;
    [_notePlaceholder.topAnchor constraintEqualToAnchor:noteBox.topAnchor constant:12].active = YES;

    // 截止日期
    [self.contentStack setCustomSpacing:18 afterView:noteBox];
    [self.contentStack addArrangedSubview:[self sectionTitle:@"截止日期"]];
    [self.contentStack setCustomSpacing:10 afterView:self.contentStack.arrangedSubviews.lastObject];

    UIScrollView *chipScroll = [[UIScrollView alloc] init];
    chipScroll.showsHorizontalScrollIndicator = NO;
    chipScroll.translatesAutoresizingMaskIntoConstraints = NO;
    [chipScroll.heightAnchor constraintEqualToConstant:36].active = YES;
    [self.contentStack addArrangedSubview:chipScroll];

    UIStackView *chipStack = [[UIStackView alloc] init];
    chipStack.axis = UILayoutConstraintAxisHorizontal;
    chipStack.spacing = 8;
    chipStack.translatesAutoresizingMaskIntoConstraints = NO;
    [chipScroll addSubview:chipStack];
    [chipStack.topAnchor constraintEqualToAnchor:chipScroll.contentLayoutGuide.topAnchor].active = YES;
    [chipStack.bottomAnchor constraintEqualToAnchor:chipScroll.contentLayoutGuide.bottomAnchor].active = YES;
    [chipStack.leadingAnchor constraintEqualToAnchor:chipScroll.contentLayoutGuide.leadingAnchor].active = YES;
    [chipStack.trailingAnchor constraintEqualToAnchor:chipScroll.contentLayoutGuide.trailingAnchor].active = YES;
    [chipStack.heightAnchor constraintEqualToAnchor:chipScroll.frameLayoutGuide.heightAnchor].active = YES;

    NSString *weekend = [TLDue weekendText];
    NSMutableArray<NSDictionary *> *chips = [NSMutableArray array];
    [chips addObject:@{@"title": @"无截止", @"value": @""}];
    [chips addObject:@{@"title": @"今天", @"value": @"今天"}];
    [chips addObject:@{@"title": @"明天", @"value": @"明天"}];
    [chips addObject:@{@"title": @"本周末", @"value": weekend}];

    NSArray<NSString *> *presetValues = @[@"", @"今天", @"明天", weekend];
    NSString *customTitle = @"自定义";
    if (self.due.length > 0 && ![presetValues containsObject:self.due]) {
        customTitle = self.due;
    }
    [chips addObject:@{@"title": customTitle, @"value": @"__custom__"}];

    for (NSDictionary *info in chips) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:info[@"title"] forState:UIControlStateNormal];
        button.titleLabel.font = [TLTheme font:15 weight:UIFontWeightMedium];
        button.contentEdgeInsets = UIEdgeInsetsMake(8, 14, 8, 14);
        button.layer.cornerRadius = 18;
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button.heightAnchor constraintEqualToConstant:36].active = YES;
        [button addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            [self chipTapped:info[@"value"]];
        }] forControlEvents:UIControlEventTouchUpInside];
        [chipStack addArrangedSubview:button];
        [self.dueChips addObject:button];
    }
    [self refreshChips];

    // 日历
    _calendarContainer = [[UIView alloc] init];
    _calendarContainer.clipsToBounds = YES;
    _calendarContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _calendarHeight = [_calendarContainer.heightAnchor constraintEqualToConstant:0];
    _calendarHeight.active = YES;
    [self.contentStack addArrangedSubview:_calendarContainer];
    [self.contentStack setCustomSpacing:16 afterView:_calendarContainer];

    _datePicker = [[UIDatePicker alloc] init];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    _datePicker.preferredDatePickerStyle = UIDatePickerStyleInline;
    _datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    _datePicker.tintColor = [TLTheme accent];
    _datePicker.translatesAutoresizingMaskIntoConstraints = NO;
    [_datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    [_calendarContainer addSubview:_datePicker];
    [_datePicker.topAnchor constraintEqualToAnchor:_calendarContainer.topAnchor].active = YES;
    [_datePicker.leadingAnchor constraintEqualToAnchor:_calendarContainer.leadingAnchor].active = YES;
    [_datePicker.trailingAnchor constraintEqualToAnchor:_calendarContainer.trailingAnchor].active = YES;
    [_datePicker.heightAnchor constraintEqualToConstant:340].active = YES;

    NSDate *initial = [TLDue startOfDayForText:self.due] ?: [NSDate date];
    _datePicker.date = initial;

    // 保存
    [self.contentStack setCustomSpacing:26 afterView:_calendarContainer];
    _saveButton = [[TLPillButton alloc] initWithTitle:@"保存"];
    _saveButton.pillEnabled = (_titleField.text.length > 0);
    [_saveButton addTarget:self action:@selector(saveTapped) forControlEvents:UIControlEventTouchUpInside];
    [_saveButton.heightAnchor constraintEqualToConstant:52].active = YES;
    [self.contentStack addArrangedSubview:_saveButton];

    // 删除
    [self.contentStack setCustomSpacing:12 afterView:_saveButton];
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_deleteButton setTitle:@"删除这条待办" forState:UIControlStateNormal];
    _deleteButton.titleLabel.font = [TLTheme font:17 weight:UIFontWeightSemibold];
    [_deleteButton setTitleColor:[TLTheme red] forState:UIControlStateNormal];
    _deleteButton.backgroundColor = [[TLTheme red] colorWithAlphaComponent:0.12];
    _deleteButton.layer.cornerRadius = 26;
    _deleteButton.layer.cornerCurve = kCACornerCurveContinuous;
    _deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_deleteButton.heightAnchor constraintEqualToConstant:52].active = YES;
    [_deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    _deleteButton.hidden = (self.editingTodo == nil);
    [self.contentStack addArrangedSubview:_deleteButton];

    [_titleField becomeFirstResponder];
}

- (void)buildActions {
    // 保存按钮已在 contentStack 内
}

#pragma mark 交互

- (void)closeTapped {
    [self.view endEditing:YES];
    if (self.onFinished != nil) self.onFinished(@"");
}

- (void)chipTapped:(NSString *)value {
    if ([value isEqualToString:@"__custom__"]) {
        CGFloat newHeight = (self.calendarHeight.constant > 0) ? 0 : 340;
        self.calendarHeight.constant = newHeight;
        [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
        return;
    }
    self.due = value;
    self.calendarHeight.constant = 0;
    [self refreshChips];
}

- (void)refreshChips {
    NSString *weekend = [TLDue weekendText];
    NSArray<NSString *> *presetValues = @[@"", @"今天", @"明天", weekend];
    NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithArray:@[@"无截止", @"今天", @"明天", @"本周末"]];
    NSString *customTitle = @"自定义";
    BOOL customSelected = NO;
    if (self.due.length > 0 && ![presetValues containsObject:self.due]) {
        customTitle = self.due;
        customSelected = YES;
    }
    [titles addObject:customTitle];

    UIColor *accent = [TLTheme accent];
    for (NSInteger i = 0; i < (NSInteger)self.dueChips.count; i++) {
        UIButton *button = self.dueChips[(NSUInteger)i];
        [button setTitle:titles[(NSUInteger)i] forState:UIControlStateNormal];
        BOOL selected = NO;
        if (i == 0) selected = (self.due.length == 0);
        else if (i == 1) selected = [self.due isEqualToString:@"今天"];
        else if (i == 2) selected = [self.due isEqualToString:@"明天"];
        else if (i == 3) selected = [self.due isEqualToString:weekend];
        else if (i == 4) selected = customSelected;
        button.backgroundColor = selected ? accent : [TLTheme chipBg];
        [button setTitleColor:selected ? [UIColor whiteColor] : [TLTheme text] forState:UIControlStateNormal];
    }
    if (self.saveButton != nil) {
        self.saveButton.pillEnabled = (self.titleField.text.length > 0);
    }
}

- (void)dateChanged {
    self.due = [TLDue textForDate:self.datePicker.date];
    [self refreshChips];
    self.calendarHeight.constant = 0;
    [UIView animateWithDuration:0.26 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)saveTapped {
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length == 0) return;
    NSString *note = self.noteView.text ?: @"";
    TLTodoStore *store = [TLTodoStore shared];
    if (self.editingTodo != nil) {
        [store updateTodo:self.editingTodo title:title note:note due:self.due];
        if (self.onFinished != nil) self.onFinished(@"已保存修改");
    } else {
        [store addWithTitle:title note:note due:self.due];
        if (self.onFinished != nil) self.onFinished([NSString stringWithFormat:@"已添加：%@", title]);
    }
}

- (void)deleteTapped {
    if (!self.deleting) {
        self.deleting = YES;
        [self.deleteButton setTitle:@"再次点击确认删除" forState:UIControlStateNormal];
        self.deleteButton.backgroundColor = [TLTheme red];
        [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.deleteResetTimer invalidate];
        self.deleteResetTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(resetDeleteState) userInfo:nil repeats:NO];
        return;
    }
    [self.deleteResetTimer invalidate];
    if (self.editingTodo != nil) {
        [[TLTodoStore shared] removeTodo:self.editingTodo];
    }
    if (self.onFinished != nil) self.onFinished(@"已删除");
}

- (void)resetDeleteState {
    self.deleting = NO;
    [self.deleteButton setTitle:@"删除这条待办" forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[TLTheme red] forState:UIControlStateNormal];
    self.deleteButton.backgroundColor = [[TLTheme red] colorWithAlphaComponent:0.12];
}

#pragma mark 文本限制

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *next = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (next.length > 60) return NO;
    NSString *trimmed = [next stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.saveButton.pillEnabled = (trimmed.length > 0);
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *trimmed = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.saveButton.pillEnabled = (trimmed.length > 0);
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *next = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return next.length <= 300;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.notePlaceholder.hidden = (textView.text.length > 0);
}

#pragma mark 键盘

- (void)keyboardWillChange:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect endFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat overlap = MAX(0, self.view.bounds.size.height - endFrame.origin.y);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, overlap, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
}

@end
