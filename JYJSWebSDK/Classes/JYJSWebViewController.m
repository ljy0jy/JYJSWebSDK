//
//  JYJSWebViewController.m
//  JYJSWebSDK
//
//  Created by new on 2022/4/1.
//

#import "JYJSWebViewController.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import <WebKit/WebKit.h>
#import "sys/utsname.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import "ScanViewController.h"
#import "IMProSizeManager.h"
#import <Photos/Photos.h>
#import <Lottie/Lottie.h>
#import "appSize.h"
#import <AppsFlyerLib/AppsFlyerLib.h>

#define WeakSelf __weak typeof(self) weakSelf = self

@interface JYJSWebViewController ()<WKNavigationDelegate, WKUIDelegate, AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic,assign) NSInteger recontime;


@end

@implementation JYJSWebViewController

- (instancetype)initWithJson:(NSString *)jsonString jsonUrlWord:(NSArray *)jsonUrlWords{
    if (self = [super init]) {
        self.jsonString = jsonString;
        self.jsonUrlWords = jsonUrlWords;
        [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:60];
    }
    return self;
}


- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
    NSLog(@"load urlString=%@", urlString);
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recontime = 0;
    [self initWebView];
    if (self.urlString) {
       
    }else if(self.jsonString) {
        [self loadUrlFromJsonString:self.jsonString jsonUrlWord:self.jsonUrlWords];
    }
}

- (void)initWebView {
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];// 添加属性监听
    if (_loadingType == LoadingTypeSVProgress) {
        [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    }

    if(!_bridge){
              _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView
              showJSconsole:YES
              enableLogging:YES];
       }
    // 解决iphoneX系列webview下面的黑边问题
    if (@available(iOS 11.0, *)) {
        _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.webView.opaque = NO;//设置背景色
    [self.view addSubview:_webView];
 
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;//因为用了WKWebViewJavascriptBridge，setWebViewDelegate不走代理
    _webView.scrollView.bounces = false;
    
    [self registerHandler];

}


- (void)registerHandler {
    WeakSelf;
    [_bridge registerHandler:@"deviceInfo" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSMutableDictionary *infoDic = [NSMutableDictionary dictionary];
        [infoDic setValue:[self getiPhoneType] forKey:@"deviceType"];
        NSNumber *boolNumber = [NSNumber numberWithBool:[IMProSizeManager isiPhoneX]];
        [infoDic setObject:boolNumber forKey:@"isiPhoneX"];

        NSNumber *hiddenNumber = [NSNumber numberWithBool:self.isHidden];
        [infoDic setObject:hiddenNumber forKey:@"isHidden"];
        responseCallback(infoDic);
    }];
    
    [_bridge registerHandler:@"openSafaiWeb" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString * urlStr = data;
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr] options:nil completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }
    }];
    
    [_bridge registerHandler:@"scanQRCode" handler:^(id data, WVJBResponseCallback responseCallback) {
        AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied){
            [self showNoPermissionAlertWithTitle:NSLocalizedString(@"BF_CameraTip1", nil) message:NSLocalizedString(@"BF_CameraTip2", nil)];
        }else{
            ScanViewController *scanVC = [[ScanViewController alloc]init];
            scanVC.block = ^(NSString * str) {
                NSLog(@"☀️☀️☀️☀️%@",str);
                responseCallback(str);
            };
            scanVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:scanVC animated:true completion:nil];
        }
    }];

    [_bridge registerHandler:@"savePicture" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString * base64Str = data;
        NSString *signStr = @"data:image/png;base64,";
        if ([base64Str containsString:signStr]) {
            base64Str = [base64Str substringFromIndex:signStr.length];
        }
        NSData * showData = [[NSData alloc]initWithBase64EncodedString:base64Str options:NSDataBase64DecodingIgnoreUnknownCharacters];
        UIImage *image = [UIImage imageWithData:showData];
        self.imageResponseCallback = responseCallback;
        [self saveImageToPhotoAlbum:image];
    }];
   
    [_bridge registerHandler:@"InviteCode" handler:^(id data, WVJBResponseCallback responseCallback) {
        responseCallback(weakSelf.channelCode);
    }];
    
    //上传头像
    [_bridge registerHandler:@"UploadAvatarCamera" handler:^(id data, WVJBResponseCallback responseCallback) {
        self.uploadAvatarResponseCallback = responseCallback;
        [self checkCameraPermission];
    }];
    [_bridge registerHandler:@"UploadAvatarPhoto" handler:^(id data, WVJBResponseCallback responseCallback) {
        self.uploadAvatarResponseCallback = responseCallback;
        [self checkPhotoPermission];
    }];
    
    [_bridge registerHandler:@"AFLogEvent" handler:^(id data, WVJBResponseCallback responseCallback) {
        if (data) {
            if ([data isKindOfClass:[NSDictionary class]]) {
                if ([data[@"test"] isEqualToString:@"1"]) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&error];
                    if(!error) {
                        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        [SVProgressHUD showInfoWithStatus:json];
                    }else {
                        [SVProgressHUD showInfoWithStatus:@"json解析错误"];
                    }
                }
                [[AppsFlyerLib shared] logEvent:data[@"eventName"] withValues:data];
            }
        }
    }];
    
   
}

- (void)loadJsonString:(NSString *)jsonString callback:(JsonResponseCallback)callback {
    if (_loadingType == LoadingTypeAnimation) {
        [[UIApplication sharedApplication].keyWindow addSubview:self.animationView];
        [self.animationView play];
    }else {
        [SVProgressHUD show];
    }
    NSURL *jsonUrl = [NSURL URLWithString:jsonString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:jsonUrl];
    request.HTTPMethod = @"GET";
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self loadJsonString:jsonString callback:callback];
                });
                
            }else{
                 NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                callback(dic);
                if (self.loadingType == LoadingTypeAnimation) {
                    [self.animationView removeFromSuperview];
                }else {
                    [SVProgressHUD dismiss];
                }
            }
            
        });
    }];
    [dataTask resume];
}

- (void)loadUrlFromJsonString:(NSString *)jsonString jsonUrlWord:(NSArray *)jsonUrlWords {
    NSURL *jsonUrl = [NSURL URLWithString:jsonString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:jsonUrl];
    request.HTTPMethod = @"GET";
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (self.recontime == 6) {
                    [SVProgressHUD showErrorWithStatus:@"请求失败"];
                    return;
                }
                dispatch_after(1.0*NSEC_PER_SEC, dispatch_get_main_queue(), ^{
                    [self loadUrlFromJsonString:jsonString jsonUrlWord:jsonUrlWords];
                    self.recontime++;
                });
                
            }
             NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            id url = dic;
            for (int i = 0; i<jsonUrlWords.count; i++) {
                 url = url[jsonUrlWords[i]];
            }
            self.urlString = url;
             NSLog(@"JYJSWebViewController: jsonUrl=%@",url);
            [SVProgressHUD dismiss];
        });
    }];
    [dataTask resume];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"change == %@",change);
        [SVProgressHUD showProgress:[change[NSKeyValueChangeNewKey] floatValue] status:[NSString stringWithFormat:@"%.f%%",[change[NSKeyValueChangeNewKey] floatValue]*100]];
        
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setLoadingType:(LoadingType)loadingType {
    _loadingType = loadingType;
    switch (loadingType) {
        case LoadingTypeAnimation:
            self.animationView = [LOTAnimationView animationNamed:self.animationFile];
            self.animationView.backgroundColor = [UIColor clearColor];
            self.animationView.contentMode = UIViewContentModeScaleAspectFit;
            self.animationView.frame = CGRectMake((QQZScreenWidth-QQZScaleWidth(60))/2, (QQZScreenHeight-QQZScaleWidth(60)-100)/2, QQZScaleWidth(60), QQZScaleWidth(60));
            self.animationView.loopAnimation = YES;
            self. animationView.animationProgress = 0;
            [self.view addSubview:self.animationView];
            self.animationView = self.animationView;
            break;
            
        default:
            break;
    }
}



- (void)dealloc {
    if (_loadingType == LoadingTypeSVProgress) {
        [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
    
}
#pragma mark -  webviewDelegate
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if (_loadingType == LoadingTypeSVDefault) {
        [SVProgressHUD show];
    }else if (_loadingType == LoadingTypeAnimation) {
        [self.view addSubview:self.animationView];
        [self.animationView play];
    }
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
    if (_loadingType == LoadingTypeAnimation) {
        [self.animationView removeFromSuperview];
    }else {
        [SVProgressHUD dismiss];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if (_loadingType == LoadingTypeAnimation) {
        [self.animationView removeFromSuperview];
    }else {
        [SVProgressHUD dismiss];
    }
}


#pragma mark -  获得设备型号
- (NSString *)getiPhoneType{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    if ([platform isEqualToString:@"i386"])      return @"iPhone Simulator";
    if ([platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    //TODO:iPhone
    //2021年10月14日，新款iPhone 12 mini、12、12 Pro、12 Pro Max发布
    if ([platform isEqualToString:@"iPhone13,1"])  return  @"iPhone 12 mini";
    if ([platform isEqualToString:@"iPhone13,2"])  return  @"iPhone 12";
    if ([platform isEqualToString:@"iPhone13,3"])  return  @"iPhone 12 Pro";
    if ([platform isEqualToString:@"iPhone13,4"])  return  @"iPhone 12 Pro Max";

    //2021年4月15日，新款iPhone SE发布
    if ([platform isEqualToString:@"iPhone12,8"])  return  @"iPhone SE 2021";

    //2019年9月11日，第十四代iPhone 11，iPhone 11 Pro，iPhone 11 Pro Max发布
    if ([platform isEqualToString:@"iPhone12,1"])  return  @"iPhone 11";
    if ([platform isEqualToString:@"iPhone12,3"])  return  @"iPhone 11 Pro";
    if ([platform isEqualToString:@"iPhone12,5"])  return  @"iPhone 11 Pro Max";
    //2018年9月13日，第十三代iPhone XS，iPhone XS Max，iPhone XR发布
    if([platform  isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
    if([platform  isEqualToString:@"iPhone11,2"]) return @"iPhone XS";
    if([platform  isEqualToString:@"iPhone11,4"]) return @"iPhone XS Max";
    if([platform  isEqualToString:@"iPhone11,6"]) return @"iPhone XS Max";
    //2017年9月13日，第十二代iPhone 8，iPhone 8 Plus，iPhone X发布
    if ([platform isEqualToString:@"iPhone10,1"])return @"iPhone 8";
    if ([platform isEqualToString:@"iPhone10,4"])return @"iPhone 8";
    if ([platform isEqualToString:@"iPhone10,2"])return @"iPhone 8 Plus";
    if ([platform isEqualToString:@"iPhone10,5"])return @"iPhone 8 Plus";
    if ([platform isEqualToString:@"iPhone10,3"])return @"iPhone X";
    if ([platform isEqualToString:@"iPhone10,6"])return @"iPhone X";
    //2016年9月8日，第十一代iPhone 7及iPhone 7 Plus发布
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone 7";
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";
    //2016年3月21日，第十代iPhone SE发布
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhone SE";
    //2015年9月10日，第九代iPhone 6S及iPhone 6S Plus发布
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";
    //2014年9月10日，第八代iPhone 6及iPhone 6 Plus发布
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone 6";
    /*
    2007年1月9日，第一代iPhone 2G发布；
    2008年6月10日，第二代iPhone 3G发布 [1]  ；
    2009年6月9日，第三代iPhone 3GS发布 [2]  ；
    2010年6月8日，第四代iPhone 4发布；
    2011年10月4日，第五代iPhone 4S发布；
    2012年9月13日，第六代iPhone 5发布；
    2013年9月10日，第七代iPhone 5C及iPhone 5S发布；*/
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone 5c";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone 5s";
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone 5s";
    
    //TODO:iPod
    if ([platform isEqualToString:@"iPod1,1"])  return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])  return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])  return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])  return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])  return @"iPod Touch (5 Gen)";
    if ([platform isEqualToString:@"iPod7,1"])  return @"iPod touch (6th generation)";
    //2019年5月发布，更新一种机型：iPod touch (7th generation)
    if ([platform isEqualToString:@"iPod9,1"])  return @"iPod touch (7th generation)";

    //TODO:iPad
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad 1G";
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini 1G";
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad 4";
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2G";
    if ([platform isEqualToString:@"iPad4,7"])   return @"iPad Mini 3";
    if ([platform isEqualToString:@"iPad4,8"])   return @"iPad Mini 3";
    if ([platform isEqualToString:@"iPad4,9"])   return @"iPad Mini 3";
    if ([platform isEqualToString:@"iPad5,1"])   return @"iPad Mini 4";
    if ([platform isEqualToString:@"iPad5,2"])   return @"iPad Mini 4";
    if ([platform isEqualToString:@"iPad5,3"])   return @"iPad Air 2";
    if ([platform isEqualToString:@"iPad5,4"])   return @"iPad Air 2";
    if ([platform isEqualToString:@"iPad6,3"])   return @"iPad Pro 9.7";
    if ([platform isEqualToString:@"iPad6,4"])   return @"iPad Pro 9.7";
    if ([platform isEqualToString:@"iPad6,7"])   return @"iPad Pro 12.9";
    if ([platform isEqualToString:@"iPad6,8"])   return @"iPad Pro 12.9";
    if ([platform isEqualToString:@"iPad6,11"])  return @"iPad 5 (WiFi)";
    if ([platform isEqualToString:@"iPad6,12"])  return @"iPad 5 (Cellular)";
    if ([platform isEqualToString:@"iPad7,1"])   return @"iPad Pro 12.9 inch 2nd gen (WiFi)";
    if ([platform isEqualToString:@"iPad7,2"])   return @"iPad Pro 12.9 inch 2nd gen (Cellular)";
    if ([platform isEqualToString:@"iPad7,3"])   return @"iPad Pro 10.5 inch (WiFi)";
    if ([platform isEqualToString:@"iPad7,4"])   return @"iPad Pro 10.5 inch (Cellular)";
    //2019年3月发布，更新二种机型：iPad mini、iPad Air
    if ([platform isEqualToString:@"iPad11,1"])  return @"iPad mini (5th generation)";
    if ([platform isEqualToString:@"iPad11,2"])  return @"iPad mini (5th generation)";
    if ([platform isEqualToString:@"iPad11,3"])  return @"iPad Air (3rd generation)";
    if ([platform isEqualToString:@"iPad11,4"])  return @"iPad Air (3rd generation)";
    
    return platform;
}


#pragma mark - 图片保存
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted ||
        status == PHAuthorizationStatusDenied) {
        [self showNoPermissionAlertWithTitle:NSLocalizedString(@"BF_AlbumTip1", nil) message:NSLocalizedString(@"BF_AlbumTip2", nil)];
    }else{
        UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }
    
}

- (void)image: (UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
//    if (image == nil) {
//        return;
//    }
    BOOL isSuc = YES;
    if(error != NULL){
        isSuc = NO;
    }
    NSLog(@"🌹🌹🌹🌹%d",isSuc);
    
    if (self.imageResponseCallback) {
        NSNumber *sucNum = [NSNumber numberWithBool:isSuc];
        self.imageResponseCallback(sucNum);
    }
}

#pragma mark - 上传头像 Camera & Photo
- (UIImagePickerController *)imagePickerController{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
        _imagePickerController.allowsEditing = YES;
    }
    return _imagePickerController;
}

- (void)showNoPermissionAlertWithTitle:(NSString *)title message:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:NSLocalizedString(@"BF_OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

//相机
- (void)checkCameraPermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [self takePhoto];
                }
            });
        }];
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        [self showNoPermissionAlertWithTitle:NSLocalizedString(@"BF_CameraTip1", nil) message:NSLocalizedString(@"BF_CameraTip2", nil)];
    } else {
        [self takePhoto];
    }
}

- (void)takePhoto {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:^{
        }];
    }
}

#pragma mark - Photo
- (void)checkPhotoPermission {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self selectAlbum];
                }
            });
        }];
    } else if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        [self showNoPermissionAlertWithTitle:NSLocalizedString(@"BF_AlbumTip1", nil) message:NSLocalizedString(@"BF_AlbumTip2", nil)];
    } else {
        [self selectAlbum];
    }
}

- (void)selectAlbum {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:^{

        }];
    }
}

#pragma mark Appsflyer

- (void)setAppId:(NSString *)appId {
    _appId = appId;
    if (_appId) {
        [[AppsFlyerLib shared] setAppleAppID:_appId];
        
    }
}

- (void)setAppsflyerKey:(NSString *)appsflyerKey {
    _appsflyerKey = appsflyerKey;
    if (_appsflyerKey) {
        [[AppsFlyerLib shared] setAppsFlyerDevKey:_appsflyerKey];
     
    }
}

-(void)setAppsflyerDebug:(BOOL)appsflyerDebug {
    _appsflyerDebug = appsflyerDebug;
    [AppsFlyerLib shared].isDebug = appsflyerDebug;
}

- (void)appsflyerStart {
    if (@available(iOS 14, *) ){
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
          NSLog(@"Status: %lu", (unsigned long)status);
        }];
    }
    [[AppsFlyerLib shared] start];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info valueForKey:UIImagePickerControllerEditedImage];
    
    NSData *imgData = UIImageJPEGRepresentation(image, 0.5);
    NSString *encodedImageStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSString *imgStr = [NSString stringWithFormat:@"data:image/jpeg;base64,%@",encodedImageStr];
    if (self.uploadAvatarResponseCallback) {
        self.uploadAvatarResponseCallback(imgStr);
    }
}
@end
