#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 截止前提醒的可选提前量（分钟），0 表示不提醒
NSArray<NSNumber *> *TLReminderLeadOptions(void);
NSString *TLReminderLabelForMinutes(NSInteger minutes);

NSInteger TLReminderLeadMinutes(void);
void TLReminderSetLeadMinutes(NSInteger minutes);

/// 首次启动请求通知权限
void TLRemindersRequestAuthorization(void);

/// 按最新数据与设置重排全部本地通知
void TLRemindersReschedule(void);

NS_ASSUME_NONNULL_END
