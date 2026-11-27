#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TLMainViewController;

@interface TLProfileViewController : UIViewController

@property (nonatomic, weak, nullable) TLMainViewController *host;

- (void)refreshContent;

@end

NS_ASSUME_NONNULL_END
