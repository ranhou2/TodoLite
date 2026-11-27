#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "TLMainViewController.h"
#import "TLReminders.h"
#import "TLTheme.h"

@interface TLAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation TLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [TLTheme bg];
    TLMainViewController *main = [[TLMainViewController alloc] init];
    self.window.rootViewController = main;
    [self.window makeKeyAndVisible];

    [UNUserNotificationCenter currentNotificationCenter].delegate = self;

    // 稍等片刻再请求通知权限，避免和首次启动的欢迎弹窗叠在一起
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        TLRemindersRequestAuthorization();
        TLRemindersReschedule();
    });
    return YES;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([TLAppDelegate class]));
    }
}
