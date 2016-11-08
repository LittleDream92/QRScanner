//
//  QRScanerHelper.m
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import "QRScanerHelper.h"

@implementation QRScanerHelper

/**
 *  生成一个二维码图片 默认图片边长 300
 *  @param string 二维码内容
 *  @return  生成二维码图片
 */
+ (UIImage *)createQRCodeWithString:(NSString *)string {
    return [self createQRCodeWithString:string withSideLength:300.f];
}

/**
 *  生成一个二维码图片 需指定图片的边长
 *  @param string  二维码内容
 *  @param sideLength  图片的边长
 *  @return 生成的二维码图片
 */
+ (UIImage *)createQRCodeWithString:(NSString *)string withSideLength:(CGFloat)sideLength {
    //滤镜 be set to default values
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //将字符串转换为NSData
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //设置输出数据
    [filter setValue:data forKey:@"inputMessage"];
    //设置纠错登记越高；即识别内容越容易，值可设置为:L(Low)|M(Medium)| Q| H(High)
    //因为有容错率 所以可以在中间添加图片，仍然能够被识别
    [filter setValue:@"Q" forKey:@"inputCorrectionLevel"];
    
    //获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    
    //需要绘制高清图
    UIImage *image = [self scaleImage:outputImage withSideLength:sideLength];
    return image;
}

/**
 *  从图片中识别二维码
 *  @param image  二维码图片
 *  @return  返回识别出的字符串
 */
+ (NSString *)recognizeQRCodeFromImage:(UIImage *)image {
    /*  这两种方式用来生成CIImage不是很好，因为当传进来的image是基于CIImage的就会返回为nil
     * 同样的 可能返回的CGImage也为nil
     CIImage *ciImage = image.CIImage;
     CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
     */
    NSData *imageData = UIImagePNGRepresentation(image);
    CIImage *ciImage = [CIImage imageWithData:imageData];
    if (!ciImage) {
        return nil;
    }
    //Apple 提供的强大的识别功能，可以支持多种类型的识别，比如人脸识别
    CIDetector *qrDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode
                                                context:[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}] options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    //CIFeature 返回的数组按照识别出的可信任度排序，所以使用第一个是最精确的
    NSArray *resultArr = [qrDetector featuresInImage:ciImage];
    //没有识别到
    if (resultArr.count == 0) {
        return nil;
    }
    
    //第一个是最精准的
    CIQRCodeFeature *feature = resultArr[0];
    return feature.messageString;
    
}

/**
 *  添加一张图片到二维码上（头像）
 *  @param codeImage   二维码图片
 *  @param image  要添加的图片
 *  @param sideLength  要添加的图片的边长尺寸
 *  @return 返回合成的图片
 */
+ (UIImage *)composeQRCodeImage:(UIImage *)codeImage withImage:(UIImage *)image withImageSideLength:(CGFloat)sideLength {
    UIGraphicsBeginImageContextWithOptions(codeImage.size, NO, 0.0f);
    
    CGFloat codeImageWidth = codeImage.size.width;
    CGFloat codeImageHeight = codeImage.size.height;
    
    //绘制原来的codeImage
    [codeImage drawInRect:CGRectMake(0, 0, codeImageWidth, codeImageHeight)];
    //绘制image到codeimage中心
    [image drawInRect:CGRectMake((codeImageWidth-sideLength)/2, (codeImageHeight-sideLength)/2,
                                 sideLength, sideLength)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return img;
}

#pragma mark - 
//绘制高清图
+ (UIImage *)scaleImage:(CIImage *)ciImage withSideLength:(CGFloat)sideLength {
    //开启图形上下文
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(sideLength, sideLength), NO, 0.0f);
    
    UIImage *temp = [UIImage imageWithCIImage:ciImage];
    CGSize originalSize = temp.size;
    CGFloat scale = MIN(sideLength/originalSize.width, sideLength/originalSize.height);
    //计算按比例缩放之后的宽高
    size_t scaledWidth = originalSize.width * scale;
    size_t scaledHeight = originalSize.height * scale;
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    //清晰
    CGContextSetInterpolationQuality(contextRef, kCGInterpolationNone);
    //绘制缩放后的图片
    [temp drawInRect:CGRectMake(0, 0, scaledWidth, scaledHeight)];
    //取得缩放后的图片
    UIImage *scaleImage = UIGraphicsGetImageFromCurrentImageContext();
    //结束绘制
    UIGraphicsEndImageContext();
    
    return scaleImage;
}



@end
