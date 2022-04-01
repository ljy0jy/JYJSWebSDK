#import "ScanViewController.h"
#import "IMProSizeManager.h"
#import "appSize.h"
@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) UIImageView *scanLineView;
@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupMaskView];//设置扫描区域之外的阴影视图
    [self setupScanWindowView];//设置扫描二维码区域的视图
    [self beginScanning];//开始扫二维码
}

- (void)setupMaskView{
    //设置统一的视图颜色和视图的透明度
    UIColor *color = [UIColor blackColor];
    float alpha = 0.7;
    //设置扫描区域外部上部的视图
    UIView *topView = [[UIView alloc]init];
    topView.frame = CGRectMake(0, 0, QQZScreenWidth, (QQZScreenHeight-QRCodeWidth)/2.0 - QQZScaleHeight(IMProSizeManager.IMProTabbarTopY));
    topView.backgroundColor = color;
    topView.alpha = alpha;
    
    //20211231 —— 返回+相册按钮
    CGFloat btnH = IMProSizeManager.IMProNavgationHei - IMProSizeManager.IMProStatusHei;
    CGFloat btnY = IMProSizeManager.IMProNavgationHei-btnH;
    UIButton *leftBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, btnY, 60, btnH)];
    [leftBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [topView addSubview:leftBtn];
    [leftBtn addTarget:self action:@selector(goBackAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *rightBtn = [[UIButton alloc]initWithFrame:CGRectMake(QQZScreenWidth-60 , btnY, 60, btnH)];
    [rightBtn setImage:[UIImage imageNamed:@"pic"] forState:UIControlStateNormal];
    [topView addSubview:rightBtn];
    [rightBtn addTarget:self action:@selector(openPhotoLibrary) forControlEvents:UIControlEventTouchUpInside];
    
    //设置扫描区域外部左边的视图
    UIView *leftView = [[UIView alloc]init];
    leftView.frame = CGRectMake(0, topView.frame.size.height, (QQZScreenWidth-QRCodeWidth)/2.0,QRCodeWidth);
    leftView.backgroundColor = color;
    leftView.alpha = alpha;
    //设置扫描区域外部右边的视图
    UIView *rightView = [[UIView alloc]init];
    rightView.frame = CGRectMake((QQZScreenWidth-QRCodeWidth)/2.0+QRCodeWidth,topView.frame.size.height, (QQZScreenWidth-QRCodeWidth)/2.0,QRCodeWidth);
    rightView.backgroundColor = color;
    rightView.alpha = alpha;
    //设置扫描区域外部底部的视图
    UIView *botView = [[UIView alloc]init];
    botView.frame = CGRectMake(0, QRCodeWidth+topView.frame.size.height,QQZScreenWidth,QQZScreenHeight-QRCodeWidth-topView.frame.size.height);
    botView.backgroundColor = color;
    botView.alpha = alpha;
    //将设置好的扫描二维码区域之外的视图添加到视图图层上
    [self.view addSubview:topView];
    [self.view addSubview:leftView];
    [self.view addSubview:rightView];
    [self.view addSubview:botView];
}

- (void)setupScanWindowView
{
    UIView *scanWindow = [[UIView alloc]initWithFrame:CGRectMake((QQZScreenWidth-QRCodeWidth)/2.0,(QQZScreenHeight-QRCodeWidth)/2.0 - QQZScaleHeight(IMProSizeManager.IMProTabbarTopY),QRCodeWidth,QRCodeWidth)];
    scanWindow.clipsToBounds = YES;
    [self.view addSubview:scanWindow];
    //设置扫描区域的四个角的边框
    UIImageView *bgImgView = [[UIImageView alloc]initWithFrame:scanWindow.bounds];
    bgImgView.image = [UIImage imageNamed:@"scanFrame"];
    bgImgView.contentMode = UIViewContentModeScaleToFill;
    [scanWindow addSubview:bgImgView];
    
    //扫描横
    _scanLineView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, QRCodeWidth, 62)];
    _scanLineView.image = [UIImage imageNamed:@"scanLine"];
    _scanLineView.contentMode = UIViewContentModeScaleToFill;
    [scanWindow addSubview:_scanLineView];
    [self addAction];
}

- (void)beginScanning{
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //特别注意的地方：有效的扫描区域，定位是以设置的右顶点为原点。屏幕宽所在的那条线为y轴，屏幕高所在的线为x轴
    CGFloat x = ((QQZScreenHeight-QRCodeWidth)/2.0-QQZScaleHeight(IMProSizeManager.IMProTabbarTopY))/QQZScreenHeight;
    CGFloat y = ((QQZScreenWidth-QRCodeWidth)/2.0)/QQZScreenWidth;
    CGFloat width = QRCodeWidth/QQZScreenHeight;
    CGFloat height = QRCodeWidth/QQZScreenWidth;
    output.rectOfInterest = CGRectMake(x, y, width, height);
    //设置代理在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    [_session addInput:input];
    [_session addOutput:output];
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code];
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [_session startRunning];
}


-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        [_session stopRunning];
        //得到二维码上的所有数据
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex :0 ];
        NSString *str = metadataObject.stringValue;
        
        self.block(str);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - click
-(void)goBackAction{
    [self dismissViewControllerAnimated:YES completion:nil];
}
//打开相册扫描二维码
- (void)openPhotoLibrary{
    //不需要权限，只有在写操作才需要权限
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc]init];
    imgPicker.delegate = self;
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imgPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info{
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    CIImage *ciImg = [[CIImage alloc]initWithImage:img];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
    NSArray *feature = [detector featuresInImage:ciImg];
    
    for (CIQRCodeFeature *result in feature) {
        NSString *str = result.messageString;
        NSLog(@"%@",str);
        self.block(str);
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - 扫描动画
-(void)addAction{
    CGFloat fromY = -62;
    CGFloat toY = QRCodeWidth - 62;
    CABasicAnimation *animation = [self moveYTime:3 fromY:[NSNumber numberWithFloat:fromY] toY:[NSNumber numberWithFloat:toY] rep:OPEN_MAX];
    [_scanLineView.layer addAnimation:animation forKey:@"animation"];
}
-(CABasicAnimation *)moveYTime:(float)time fromY:(NSNumber *)fromY toY:(NSNumber *)toY rep:(int)rep{
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:fromY];
    [animationMove setToValue:toY];
    animationMove.duration = time;
    animationMove.repeatCount  = rep;
    //在动画结束后会回归动画开始前的状态
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    //动画的速度变化,kCAMediaTimingFunctionEaseInEaseOut:淡入淡出
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return animationMove;
}
@end
