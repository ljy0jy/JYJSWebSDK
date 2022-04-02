//
//  JYJSWebViewController.h
//  JYJSWebSDK
//
//  Created by new on 2022/4/1.
//

#import <UIKit/UIKit.h>
#import "SKJavaScriptBridge/WebViewJavascriptBridge.h"
NS_ASSUME_NONNULL_BEGIN
@class WKWebView,WebViewJavascriptBridge,LOTAnimationView;

typedef NS_ENUM(NSInteger, LoadingType) {
    LoadingTypeSVDefault = 0, //用svprogress默认菊花加载
    LoadingTypeSVProgress = 1, //用svprogress百分比进度加载
    LoadingTypeAnimation = 2,  //用动画加载 需要自定义动画
};
typedef void (^JsonResponseCallback)(id responseData);

@interface JYJSWebViewController : UIViewController

@property (nonatomic,strong) NSString *urlString;
@property (nonatomic,strong) NSString *jsonString;
@property (nonatomic,strong) NSArray *jsonUrlWords;
@property (nonatomic,strong) WKWebView *webView;
@property (nonatomic,strong) id channelCode;
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
//图片保存
@property (nonatomic, strong) WVJBResponseCallback imageResponseCallback;
//上传头像 - 图片 + 摄像
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) WVJBResponseCallback uploadAvatarResponseCallback;


@property (nonatomic,assign) LoadingType loadingType;
//动画view
@property (nonatomic,strong) LOTAnimationView *animationView;
@property (nonatomic,strong) NSString *animationFile;

@property (nonatomic,assign) BOOL isHidden; //每次更新版本，需要累积叠加


- (void)loadJsonString:(NSString *)jsonString callback:(JsonResponseCallback)callback;

-(instancetype)initWithJson:(NSString *)jsonString jsonUrlWord:(NSArray *)jsonUrlWords;

@end

NS_ASSUME_NONNULL_END
