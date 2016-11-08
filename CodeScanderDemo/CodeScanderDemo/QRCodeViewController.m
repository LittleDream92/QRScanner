//
//  QRCodeViewController.m
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import "QRCodeViewController.h"
#import "QRScanerHelper.h"
#import "ZJProgressHUD.h"

@interface QRCodeViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *qrImage;

@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark -
-(void)setQrImage:(UIImage *)qrImage {
    _imageView = [[UIImageView alloc] initWithImage:qrImage];
    _imageView.center = self.view.center;
    [self.view addSubview:_imageView];
}


#pragma mark - publick
//扫描二维码
- (void)startScanner {
    [ZJProgressHUD showStatus:@"需要真机测试" andAutoHideAfterTime:1.0];
    
}

//生成二维码图片
- (void)createCodeWithQRString:(NSString *)qrstring andLogoImage:(UIImage *)logo {
    UIImage *qrImage = [QRScanerHelper createQRCodeWithString:qrstring withSideLength:200.f];
    
    if (logo) {
        qrImage = [QRScanerHelper composeQRCodeImage:qrImage withImage:logo withImageSideLength:40.f];
    }
    self.qrImage = qrImage;
}

//识别二维码
- (void)recognizedQRImage:(UIImage *)qrImage {
    NSString *result = [QRScanerHelper recognizeQRCodeFromImage:qrImage];
    NSLog(@"二维码内容：%@", result);
    [ZJProgressHUD showStatus:[NSString stringWithFormat:@"二维码内容：%@", result] andAutoHideAfterTime:2.0];
}



#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
