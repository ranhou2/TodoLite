#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const TLTodoStoreDidChangeNotification;

/// 一条待办，字段与 Android 版 JSON 备份保持一致
@interface TLTodo : NSObject

@property (nonatomic) long long todoId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *note;
@property (nonatomic, copy) NSString *due;
@property (nonatomic) BOOL done;
@property (nonatomic) long long createdAt;
@property (nonatomic) long long doneAt;

@end

/// 本地存储 + 列表排序 + 导入导出
@interface TLTodoStore : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSArray<TLTodo *> *allItems;
@property (nonatomic, readonly) NSArray<TLTodo *> *pendingItems;
@property (nonatomic, readonly) NSArray<TLTodo *> *doneItems;

- (void)addWithTitle:(NSString *)title note:(NSString *)note due:(NSString *)due;
- (void)updateTodo:(TLTodo *)todo title:(NSString *)title note:(NSString *)note due:(NSString *)due;
- (void)toggleTodo:(TLTodo *)todo;
- (void)removeTodo:(TLTodo *)todo;
- (BOOL)restoreTodo:(TLTodo *)todo;
- (void)clearDone;
- (void)clearAll;

- (NSString *)exportJSON;
- (NSInteger)importJSON:(NSString *)raw error:(NSString *__autoreleasing *)errorMessage;

@end

/// 截止日期文案的解析与展示
@interface TLDue : NSObject

+ (nullable NSDate *)startOfDayForText:(NSString *)text;
+ (nullable NSNumber *)daysUntilText:(NSString *)text;
+ (NSString *)textForDate:(NSDate *)date;
+ (NSString *)weekendText;
+ (NSString *)displayTimeForMillis:(long long)millis;

@end

NS_ASSUME_NONNULL_END
