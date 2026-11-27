#import <UIKit/UIKit.h>
#import "TLTodoStore.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TLListMode) {
    TLListModePending = 0,
    TLListModeDone = 1
};

@class TLMainViewController;

@interface TLListViewController : UIViewController

@property (nonatomic, weak, nullable) TLMainViewController *host;
@property (nonatomic, readonly) TLListMode mode;

- (instancetype)initWithMode:(TLListMode)mode;
- (void)refreshContent;

@end

NS_ASSUME_NONNULL_END
