#import "TLReminders.h"
#import "TLTodoStore.h"
#import <UserNotifications/UserNotifications.h>

static NSString *const kLeadMinutesKey = @"tl_remind_lead_minutes";
static NSString *const kNotificationPrefix = @"todo-";

NSArray<NSNumber *> *TLReminderLeadOptions(void) {
    return @[@0, @30, @60, @360, @1440, @2880];
}

NSString *TLReminderLabelForMinutes(NSInteger minutes) {
    switch (minutes) {
        case 0: return @"不提醒";
        case 30: return @"提前 30 分钟";
        case 60: return @"提前 1 小时";
        case 360: return @"提前 6 小时";
        case 1440: return @"提前 1 天";
        case 2880: return @"提前 2 天";
        default: return [NSString stringWithFormat:@"提前 %ld 分钟", (long)minutes];
    }
}

NSInteger TLReminderLeadMinutes(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:kLeadMinutesKey] == nil) {
        [defaults setInteger:60 forKey:kLeadMinutesKey];
        [defaults synchronize];
        return 60;
    }
    NSInteger minutes = [defaults integerForKey:kLeadMinutesKey];
    for (NSNumber *option in TLReminderLeadOptions()) {
        if (option.integerValue == minutes) return minutes;
    }
    return 60;
}

void TLReminderSetLeadMinutes(NSInteger minutes) {
    [[NSUserDefaults standardUserDefaults] setInteger:minutes forKey:kLeadMinutesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void TLRemindersRequestAuthorization(void) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                TLRemindersReschedule();
            });
        }
    }];
}

void TLRemindersReschedule(void) {
    NSInteger lead = TLReminderLeadMinutes();
    TLTodoStore *store = [TLTodoStore shared];
    NSArray<TLTodo *> *todos = store.pendingItems;

    NSMutableArray<UNNotificationRequest *> *requests = [NSMutableArray array];
    if (lead > 0) {
        double now = [[NSDate date] timeIntervalSince1970];
        for (TLTodo *todo in todos) {
            NSDate *day = [TLDue startOfDayForText:todo.due];
            if (day == nil) continue;
            // 截止按当天结束（24:00）计算，再往前推提前量
            double dayEnd = [day timeIntervalSince1970] + 86400.0;
            double remindAt = dayEnd - (double)lead * 60.0;
            if (remindAt <= now + 1.0) continue;

            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = @"待办即将截止";
            content.body = [NSString stringWithFormat:@"「%@」· 截止：%@", todo.title, todo.due];
            content.sound = [UNNotificationSound defaultSound];

            UNTimeIntervalNotificationTrigger *trigger =
                [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:(remindAt - now) repeats:NO];

            NSString *identifier = [NSString stringWithFormat:@"%@%lld", kNotificationPrefix, todo.todoId];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                 content:content
                                                                                 trigger:trigger];
            [requests addObject:request];
        }
    }

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *pending) {
        for (UNNotificationRequest *request in pending) {
            if ([request.identifier hasPrefix:kNotificationPrefix]) {
                [center removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
            }
        }
        for (UNNotificationRequest *request in requests) {
            [center addNotificationRequest:request withCompletionHandler:nil];
        }
    }];
}
