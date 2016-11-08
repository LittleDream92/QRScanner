//
//  QRScannerView.m
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import "QRScannerView.h"
#import <AVFoundation/AVFoundation.h>

@interface QRScannerView ()<AVCaptureMetadataOutputObjectsDelegate>
{
    //用来作为上下左右的“背景”
    UIView *_topView;
    UIView *_downView;
    UIView *_leftView;
    UIView *_rightView;
}

//采集设备
@property (nonatomic, strong) AVCaptureDevice *device;
//输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
//输出数据
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
//会话
@property (nonatomic, strong) AVCaptureSession *session;


/** 扫描框的背景图片 */
@property (nonatomic, strong) UIImage *backgroundImage;
/** 扫描线图片 */
@property (nonatomic, strong) UIImage *scrollImage;
/** 扫描线扫描一次的时间 */
@property (nonatomic, assign) CGFloat scrollImageAnimateDuration;

//中间扫描区域的边长
@property (nonatomic, assign) CGFloat slideLength;

//摄像头采集到的画面展示
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
//自定义线程 来处理耗时操作——开始采集
@property (nonatomic, strong) dispatch_queue_t sessionQueue;

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *scrollImageView;
@property (nonatomic, copy) QRScannerFinishHandler handler;

@end



@implementation QRScannerView

-(void)dealloc {
    //移除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}


-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}


#pragma mark -
//初始化
- (void)commonInit {
    _slideLength = 200;
    _scrollImageAnimateDuration = 2.f;
    
    //监听状态栏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fitOrientation) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    //使用SERIAL 保证FIFO
    self.sessionQueue = dispatch_queue_create("ZJCameraViewSession", DISPATCH_QUEUE_SERIAL);
    //开始编辑输入和输出设备
    [self.session beginConfiguration];
    //添加前一定要先判断是否能够添加这种类型的设备，否则会crash
    if ([self.session canAddInput:self.deviceInput]) {
        //添加输入设备
        [self.session addInput:self.deviceInput];
    }
    
    if ([self.session canAddOutput:self.metadataOutput]) {
        //添加输出数据
        [self.session addOutput:self.metadataOutput];
    }
    
    //设备添加和删除完成，提交
    [self.session commitConfiguration];
    //要先添加了设备，才能设置metadataObjectTypes
    //设置支持识别的码的类型，系统支持很多种，我们在这里设置QR
    NSArray *supportType = [_metadataOutput availableMetadataObjectTypes];
    if ([supportType containsObject:AVMetadataObjectTypeQRCode]) {
        [_metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    }
    
    //设置子控件
    [self setUpViews];
}

- (void)setUpViews {
    //初始化四周的View
    UIColor *bgColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    _topView = [UIView new];
    _downView = [UIView new];
    _leftView = [UIView new];
    _rightView = [UIView new];
    
    _topView.backgroundColor = bgColor;
    _downView.backgroundColor = bgColor;
    _leftView.backgroundColor = bgColor;
    _rightView.backgroundColor = bgColor;
    
    [self addSubview:_topView];
    [self addSubview:_downView];
    [self addSubview:_leftView];
    [self addSubview:_rightView];
    
    //添加滚动线和扫描区域的背景Image View
    [self addSubview:self.scrollImageView];
    [self addSubview:self.backgroundImageView];
    
    //默认图片
    self.backgroundImage = [UIImage imageNamed:@"scanBackground"];
    self.scrollImage = [UIImage imageNamed:@"scanLine"];
}

#pragma mark - lazyloading
-(AVCaptureSession *)session {
    if (!_session) {
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        if ([session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
// 设置为这个模式, 可以快速精确的扫描到较小的二维码
//            session.sessionPreset = AVCaptureSessionPreset1920x1080;
        }
        _session = session;
    }
    return _session;
}

-(AVCaptureDevice *)device {
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

-(AVCaptureDeviceInput *)deviceInput {
    if (!_deviceInput) {
        NSError *error;
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        if (error) {
            return nil;
        }
    }
    return _deviceInput;
}

-(AVCaptureMetadataOutput *)metadataOutput {
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        //设置代理，通过代理方法可以获取到扫描的数据
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    }
    return _metadataOutput;
}

-(AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        // 缩放方式
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        // 添加到self.layer
        [self.layer insertSublayer:_previewLayer atIndex:0];
    }
    return _previewLayer;
}

-(UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
        _backgroundImageView.contentMode = UIViewContentModeCenter;
    }
    return _backgroundImageView;
}

-(UIImageView *)scrollImageView {
    if (!_scrollImageView) {
        _scrollImageView = [UIImageView new];
        _scrollImageView.contentMode = UIViewContentModeCenter;
    }
    return _scrollImageView;
}


-(void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImage = backgroundImage;
    _backgroundImageView.image = backgroundImage;
    [self setNeedsLayout];
}

-(void)setScrollImage:(UIImage *)scrollImage {
    _scrollImage = scrollImage;
    _scrollImageView.image = scrollImage;
    [self setNeedsLayout];
}


#pragma mark - action
- (void)fitOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait: {
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown: {
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
            break;
        default:
            break;
    }
}

- (void)addAnimation {
    static NSString *const kpositionYKey = @"positionY";
    
    if ([self.scrollImageView.layer animationForKey:kpositionYKey]) {
        //移除之前，可以适配旋转
        [self.scrollImageView.layer removeAnimationForKey:kpositionYKey];
    }
    
    //改变Y值
    CABasicAnimation *scrollAnimation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    
    scrollAnimation.toValue = [NSNumber numberWithFloat:CGRectGetMaxY(self.scrollImageView.frame)-self.scrollImageView.bounds.size.height];
    
    //时间函数
    [scrollAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    //自动反向
    scrollAnimation.autoreverses = YES;
    //无限
    scrollAnimation.repeatCount = MAXFLOAT;
    scrollAnimation.duration = _scrollImageAnimateDuration;
    [self.scrollImageView.layer addAnimation:scrollAnimation forKey:kpositionYKey];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //停止扫描，不然会继续扫描
    [self stopScanning];
    
    AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
    //block方法
    if (_handler) {
        self.handler(self, metadataObject.stringValue);
    }
    
    //代理方法
    if (_delegate && [_delegate respondsToSelector:@selector(qrScanner:didFinishScannerWithResult:)]) {
        [_delegate qrScanner:self didFinishScannerWithResult:metadataObject.stringValue];
    }
}

#pragma mark - 
-(void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.backgroundImage) {
        _slideLength = self.backgroundImage.size.width;
    }
    
    self.previewLayer.frame = self.bounds;
    
    CGFloat selfWidth = self.bounds.size.width;
    CGFloat selfHeight = self.bounds.size.height;
    CGFloat bgImageViewX = (selfWidth-_slideLength)/2;
    CGFloat bgImageViewY = (selfHeight-_slideLength)/2;
    
    //设置frame
    self.backgroundImageView.frame = CGRectMake(bgImageViewX, bgImageViewY, _slideLength, _slideLength);
    _topView.frame = CGRectMake(0.f, 0.f, selfWidth, bgImageViewY);
    _leftView.frame = CGRectMake(0.f, bgImageViewY, bgImageViewX, _slideLength);
    _rightView.frame = CGRectMake(CGRectGetMaxX(self.backgroundImageView.frame), bgImageViewY, bgImageViewX, _slideLength);
    _downView.frame = CGRectMake(0.f, CGRectGetMaxY(self.backgroundImageView.frame), selfWidth, bgImageViewY);
    
    CGFloat scrollImageHeight = 1.0f;
    if (self.scrollImage) {
        scrollImageHeight = self.scrollImage.size.height;
    }
    
    self.scrollImageView.frame = CGRectMake(bgImageViewX, bgImageViewY, _slideLength, scrollImageHeight);
    /**
     *  设置扫描的有效区域
     *  这里需要注意 , rectOfInterest的 x, y, width, height的范围都是 0---1
     *  默认为(0,0,1,1) 代表 x和y都为0, 宽高都为previewLayer的宽高
     *  如果设置为 (0.5,0.5,0.5,0.5) 则表示居中显示, 宽高均为previewLayer的一半
     *  所以设置的时候, 需要和相应的 宽高求比例
     *  另外注意的是, 可以理解为系统处理图片的时候都是横着的, 当iPhone的屏幕确是竖着的
     *  时候应该 x = y/height;  y = x/height ...
     */
    if (self.bounds.size.width < self.bounds.size.height) { // 竖屏的时候
        self.metadataOutput.rectOfInterest = CGRectMake(bgImageViewY/selfHeight, bgImageViewX/selfWidth, _slideLength/selfHeight, _slideLength/selfWidth);
    }else {
        self.metadataOutput.rectOfInterest = CGRectMake(bgImageViewX/selfWidth, bgImageViewY/selfHeight, _slideLength/selfWidth, _slideLength/selfHeight);
    }
    if (self.bounds.size.width != 0) {// 有frame的时候添加动画和适应屏幕方向
        
        [self addAnimation];
// 处理旋转 --- 也可以通过添加通知监听状态栏的方向来处理
//        [self fitOrientation];
    }
}


#pragma mark - public
//block方法
- (void)setScannerFinishHandler:(QRScannerFinishHandler)handler {
    _handler = [handler copy];
}

/** 开始扫描 */
- (void)startScanning {
    //耗时操作 另开线程
    dispatch_async(self.sessionQueue, ^{
        //获取授权
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                [self.session startRunning];
            }else {
                NSLog(@"用户未授权访问摄像头");
            }
        }];
    });
}

/** 停止扫描 */
- (void)stopScanning {
    [self.session stopRunning];
}



@end
