#import <UIKit/UIKit.h>
#import "TLTodoStore.h"

NS_ASSUME_NONNULL_BEGIN

/// 底部胶囊标签栏（供「我的」二级页复用）
@interface TLTabBarView : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy, nullable) void (^onSelect)(NSInteger index);
- (void)refreshColors;
@end

@interface TLMainViewController : UIViewController

- (void)selectTabIndex:(NSInteger)index;
- (void)refreshInterface;

- (void)showToastMessage:(NSString *)message;
- (void)showToastMessage:(NSString *)message
             actionTitle:(nullable NSString *)actionTitle
                 handler:(nullable void (^)(void))handler;

- (void)openEditorForTodo:(nullable TLTodo *)todo;

@end

NS_ASSUME_NONNULL_END
