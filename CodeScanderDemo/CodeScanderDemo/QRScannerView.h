//
//  QRScannerView.h
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class QRScannerView;
@protocol QRScannerDelegate <NSObject>

/**
 *  扫描成功的代理回调方法 ----- 可以直接使用提供的设置block方法替代 代理
 *  @param scannerView  scanner
 *  @param result       扫描结果－－字符串
 */
- (void)qrScanner:(QRScannerView *)scannerView didFinishScannerWithResult:(NSString *)result;

@end


typedef void(^QRScannerFinishHandler)(QRScannerView *scannerView, NSString *resultString);

@interface QRScannerView : UIView

//代理方法
/** 代理 */
@property (nonatomic, weak) id<QRScannerDelegate> delegate;


//block方法
- (void)setScannerFinishHandler:(QRScannerFinishHandler)handler;

/** 开始扫描 */
- (void)startScanning;
/** 停止扫描 */
- (void)stopScanning;

@end
