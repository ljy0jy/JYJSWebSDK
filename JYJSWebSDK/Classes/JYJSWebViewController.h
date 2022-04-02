//
//  JYJSWebViewController.h
//  JYJSWebSDK
//
//  Created by new on 2022/4/1.
//

#import <UIKit/UIKit.h>
#import "SKJavaScriptBridge/WebViewJavascriptBridge.h"
NS_ASSUME_NONNULL_BEGIN
@class WKWebView,WebViewJavascriptBridge;

typedef void (^JsonResponseCallback)(id responseData);

@interface JYJSWebViewController : UIViewController

@property (nonatomic,strong) NSString *urlString;
@property (nonatomic,strong) NSString *jsonString;
@property (nonatomic,strong) NSArray *jsonUrlWords;
@property (nonatomic,strong) WKWebView *webView;
@property (nonatomic,strong) id channelCode;
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;

@property (nonatomic,assign) BOOL isHidden; //每次更新版本，需要累积叠加

//图片保存
@property (nonatomic, strong) WVJBResponseCallback imageResponseCallback;

//上传头像 - 图片 + 摄像
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) WVJBResponseCallback uploadAvatarResponseCallback;


- (void)loadJsonString:(NSString *)jsonString callback:(JsonResponseCallback)callback;

-(instancetype)initWithJson:(NSString *)jsonString jsonUrlWord:(NSArray *)jsonUrlWords;

@end

NS_ASSUME_NONNULL_END
