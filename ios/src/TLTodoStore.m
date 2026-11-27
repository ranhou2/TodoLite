#import "TLTodoStore.h"

NSNotificationName const TLTodoStoreDidChangeNotification = @"TLTodoStoreDidChangeNotification";
static NSString *const kItemsKey = @"tl_items_v1";

#pragma mark - TLTodo

@implementation TLTodo
@end

#pragma mark - TLDue

@implementation TLDue

+ (NSCalendar *)calendar {
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    cal.timeZone = [NSTimeZone localTimeZone];
    return cal;
}

+ (NSDate *)startOfToday {
    NSCalendar *cal = [self calendar];
    return [cal startOfDayForDate:[NSDate date]];
}

+ (NSDate *)startOfDayForText:(NSString *)text {
    NSString *value = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (value.length == 0) return nil;

    NSCalendar *cal = [self calendar];
    NSDate *base = [self startOfToday];

    if ([value isEqualToString:@"今天"]) {
        return base;
    }
    if ([value isEqualToString:@"明天"]) {
        return [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:base options:0];
    }
    if ([value isEqualToString:@"后天"]) {
        return [cal dateByAddingUnit:NSCalendarUnitDay value:2 toDate:base options:0];
    }

    // 解析「11月29日」
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\d{1,2})月(\\d{1,2})日"
                                                                          options:0
                                                                            error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:value options:0 range:NSMakeRange(0, value.length)];
    if (match == nil) return nil;

    NSInteger month = [[value substringWithRange:[match rangeAtIndex:1]] integerValue];
    NSInteger day = [[value substringWithRange:[match rangeAtIndex:2]] integerValue];
    if (month < 1 || month > 12 || day < 1 || day > 31) return nil;

    NSDateComponents *nowComponents = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:base];
    NSDateComponents *target = [[NSDateComponents alloc] init];
    target.year = nowComponents.year;
    target.month = month;
    target.day = day;
    target.hour = 0;
    target.minute = 0;
    target.second = 0;

    NSDate *date = [cal dateFromComponents:target];
    if (date == nil) return nil;

    // 校验 2 月 30 日这类非法日期
    NSDateComponents *roundTrip = [cal components:(NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    if (roundTrip.month != month || roundTrip.day != day) return nil;

    // 年底写「1月3日」时按明年计算
    NSDate *halfYearAgo = [cal dateByAddingUnit:NSCalendarUnitDay value:-180 toDate:base options:0];
    if ([date compare:halfYearAgo] == NSOrderedAscending) {
        target.year = nowComponents.year + 1;
        date = [cal dateFromComponents:target];
    }
    return date;
}

+ (NSNumber *)daysUntilText:(NSString *)text {
    NSDate *day = [self startOfDayForText:text];
    if (day == nil) return nil;
    NSCalendar *cal = [self calendar];
    NSDateComponents *diff = [cal components:NSCalendarUnitDay fromDate:[self startOfToday] toDate:day options:0];
    return @(diff.day);
}

+ (NSString *)textForDate:(NSDate *)date {
    NSCalendar *cal = [self calendar];
    NSDateComponents *c = [cal components:(NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [NSString stringWithFormat:@"%ld月%ld日", (long)c.month, (long)c.day];
}

+ (NSString *)weekendText {
    NSCalendar *cal = [self calendar];
    NSDate *base = [self startOfToday];
    NSInteger weekday = [cal component:NSCalendarUnitWeekday fromDate:base]; // 1=周日
    NSInteger days = (weekday == 1) ? 0 : (8 - weekday);
    NSDate *target = [cal dateByAddingUnit:NSCalendarUnitDay value:days toDate:base options:0];
    return [self textForDate:target];
}

+ (NSString *)displayTimeForMillis:(long long)millis {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(double)millis / 1000.0];
    return [self textForDate:date];
}

@end

#pragma mark - TLTodoStore

@interface TLTodoStore ()
@property (nonatomic, strong) NSMutableArray<TLTodo *> *items;
@end

@implementation TLTodoStore

@synthesize items = _items;

+ (instancetype)shared {
    static TLTodoStore *store = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        store = [[TLTodoStore alloc] init];
    });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        [self loadFromDisk];
    }
    return self;
}

#pragma mark 读写磁盘

- (void)loadFromDisk {
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kItemsKey];
    if (raw.length == 0) return;
    NSArray *array = [NSJSONSerialization JSONObjectWithData:[raw dataUsingEncoding:NSUTF8StringEncoding]
                                                     options:0
                                                       error:nil];
    if (![array isKindOfClass:[NSArray class]]) return;
    for (id obj in (NSArray *)array) {
        if (![obj isKindOfClass:[NSDictionary class]]) continue;
        TLTodo *todo = [self todoFromDictionary:(NSDictionary *)obj];
        if (todo.todoId > 0) [_items addObject:todo];
    }
}

- (TLTodo *)todoFromDictionary:(NSDictionary *)dict {
    TLTodo *todo = [[TLTodo alloc] init];
    todo.todoId = [dict[@"id"] longLongValue];
    todo.title = [self stringValue:dict[@"title"]];
    todo.note = [self stringValue:dict[@"note"]];
    todo.due = [self stringValue:dict[@"due"]];
    todo.done = [dict[@"done"] boolValue];
    todo.createdAt = [dict[@"createdAt"] longLongValue];
    todo.doneAt = [dict[@"doneAt"] longLongValue];
    return todo;
}

- (NSString *)stringValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) return (NSString *)value;
    return @"";
}

- (NSDictionary *)dictionaryFromTodo:(TLTodo *)todo {
    return @{
        @"id": @(todo.todoId),
        @"title": todo.title ?: @"",
        @"note": todo.note ?: @"",
        @"due": todo.due ?: @"",
        @"done": @(todo.done),
        @"createdAt": @(todo.createdAt),
        @"doneAt": @(todo.doneAt)
    };
}

- (void)saveToDisk {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self dictionaryList] options:0 error:&error];
    if (data == nil) return;
    NSString *raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[NSUserDefaults standardUserDefaults] setObject:raw forKey:kItemsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray<NSDictionary *> *)dictionaryList {
    NSMutableArray *list = [NSMutableArray array];
    for (TLTodo *todo in _items) {
        [list addObject:[self dictionaryFromTodo:todo]];
    }
    return list;
}

#pragma mark 查询

- (NSArray<TLTodo *> *)allItems {
    return [_items copy];
}

- (NSArray<TLTodo *> *)pendingItems {
    NSArray *pending = [_items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TLTodo *todo, NSDictionary *bindings) {
        return !todo.done;
    }]];
    return [pending sortedArrayUsingComparator:^NSComparisonResult(TLTodo *a, TLTodo *b) {
        NSNumber *daysA = [TLDue daysUntilText:a.due];
        NSNumber *daysB = [TLDue daysUntilText:b.due];
        NSInteger valueA = daysA ? daysA.integerValue : NSIntegerMax;
        NSInteger valueB = daysB ? daysB.integerValue : NSIntegerMax;
        if (valueA != valueB) {
            return valueA < valueB ? NSOrderedAscending : NSOrderedDescending;
        }
        if (a.createdAt != b.createdAt) {
            return a.createdAt > b.createdAt ? NSOrderedAscending : NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
}

- (NSArray<TLTodo *> *)doneItems {
    NSArray *done = [_items filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TLTodo *todo, NSDictionary *bindings) {
        return todo.done;
    }]];
    return [done sortedArrayUsingComparator:^NSComparisonResult(TLTodo *a, TLTodo *b) {
        if (a.doneAt != b.doneAt) return a.doneAt > b.doneAt ? NSOrderedAscending : NSOrderedDescending;
        return NSOrderedSame;
    }];
}

#pragma mark 修改

- (void)commitChange {
    [self saveToDisk];
    [[NSNotificationCenter defaultCenter] postNotificationName:TLTodoStoreDidChangeNotification object:self];
}

- (void)addWithTitle:(NSString *)title note:(NSString *)note due:(NSString *)due {
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    TLTodo *todo = [[TLTodo alloc] init];
    todo.todoId = now;
    todo.title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    todo.note = [note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    todo.due = due ?: @"";
    todo.createdAt = now;
    // 保证 id 唯一
    while ([self itemWithId:todo.todoId] != nil) {
        todo.todoId += 1;
    }
    [_items addObject:todo];
    [self commitChange];
}

- (TLTodo *)itemWithId:(long long)todoId {
    for (TLTodo *todo in _items) {
        if (todo.todoId == todoId) return todo;
    }
    return nil;
}

- (void)updateTodo:(TLTodo *)todo title:(NSString *)title note:(NSString *)note due:(NSString *)due {
    TLTodo *target = [self itemWithId:todo.todoId];
    if (target == nil) return;
    target.title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    target.note = [note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    target.due = due ?: @"";
    [self commitChange];
}

- (void)toggleTodo:(TLTodo *)todo {
    TLTodo *target = [self itemWithId:todo.todoId];
    if (target == nil) return;
    target.done = !target.done;
    target.doneAt = target.done ? (long long)([[NSDate date] timeIntervalSince1970] * 1000.0) : 0;
    [self commitChange];
}

- (void)removeTodo:(TLTodo *)todo {
    TLTodo *target = [self itemWithId:todo.todoId];
    if (target == nil) return;
    [_items removeObject:target];
    [self commitChange];
}

- (BOOL)restoreTodo:(TLTodo *)todo {
    if (todo == nil) return NO;
    if ([self itemWithId:todo.todoId] != nil) return NO;
    [_items addObject:todo];
    [self commitChange];
    return YES;
}

- (void)clearDone {
    NSMutableArray *keep = [NSMutableArray array];
    for (TLTodo *todo in _items) {
        if (!todo.done) [keep addObject:todo];
    }
    _items = keep;
    [self commitChange];
}

- (void)clearAll {
    [_items removeAllObjects];
    [self commitChange];
}

#pragma mark 导入导出

- (NSString *)exportJSON {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self dictionaryList]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if (data == nil) return @"[]";
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"[]";
}

- (NSInteger)importJSON:(NSString *)raw error:(NSString *__autoreleasing *)errorMessage {
    if (raw.length == 0) {
        if (errorMessage) *errorMessage = @"文件为空";
        return -1;
    }
    NSData *data = [raw dataUsingEncoding:NSUTF8StringEncoding];
    id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![root isKindOfClass:[NSArray class]]) {
        if (errorMessage) *errorMessage = @"文件格式不正确";
        return -1;
    }

    NSMutableArray<TLTodo *> *incoming = [NSMutableArray array];
    for (id obj in (NSArray *)root) {
        if (![obj isKindOfClass:[NSDictionary class]]) {
            if (errorMessage) *errorMessage = @"文件格式不正确";
            return -1;
        }
        TLTodo *todo = [self todoFromDictionary:(NSDictionary *)obj];
        if (todo.todoId <= 0) {
            if (errorMessage) *errorMessage = @"缺少有效的 id";
            return -1;
        }
        [incoming addObject:todo];
    }

    NSMutableDictionary<NSNumber *, TLTodo *> *merged = [NSMutableDictionary dictionary];
    for (TLTodo *todo in _items) merged[@(todo.todoId)] = todo;
    NSInteger added = 0;
    for (TLTodo *todo in incoming) {
        NSNumber *key = @(todo.todoId);
        if (merged[key] == nil) {
            merged[key] = todo;
            added += 1;
        }
    }
    if (added > 0) {
        _items = [[merged.allValues sortedArrayUsingComparator:^NSComparisonResult(TLTodo *a, TLTodo *b) {
            if (a.createdAt != b.createdAt) return a.createdAt > b.createdAt ? NSOrderedAscending : NSOrderedDescending;
            return NSOrderedSame;
        }] mutableCopy];
        [self commitChange];
    }
    return added;
}

@end
