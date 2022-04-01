#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>//原生二维码扫描必须导入这个框架
NS_ASSUME_NONNULL_BEGIN

@interface ScanViewController : UIViewController

@property (copy) void (^block)(NSString *);
@end

NS_ASSUME_NONNULL_END
