//
//  QRScannerView.m
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import "QRScannerView.h"
#import <AVFoundation/AVFoundation.h>

@interface QRScannerView ()

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

//自定义线程 来处理耗时操作——开始采集
@property (nonatomic, strong) dispatch_queue_t sessionQueue;

@property (nonatomic, copy) QRScannerFinishHandler handler;

@end



@implementation QRScannerView

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


#pragma mark - action
- (void)fitOrientation {
    
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
