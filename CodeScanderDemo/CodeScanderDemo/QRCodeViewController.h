//
//  QRCodeViewController.h
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRCodeViewController : UIViewController

- (void)startScanner;

- (void)createCodeWithQRString:(NSString *)qrstring andLogoImage:(UIImage *)logo;

- (void)recognizedQRImage:(UIImage *)qrImage;

@end
