#import <UIKit/UIKit.h>
#import "TLTodoStore.h"

NS_ASSUME_NONNULL_BEGIN

@interface TLEditorViewController : UIViewController

@property (nonatomic, copy, nullable) void (^onFinished)(NSString *message);

- (instancetype)initWithTodo:(nullable TLTodo *)todo;

@end

NS_ASSUME_NONNULL_END
