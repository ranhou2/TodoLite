#import <UIKit/UIKit.h>
#import "TLTodoStore.h"

NS_ASSUME_NONNULL_BEGIN

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
