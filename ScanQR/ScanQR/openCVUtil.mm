//
//  openCVUtil.m
//  ScanQR
//
//  Created by 刘畅 on 2015-08-25.
//  Copyright © 2015 menghua.cn. All rights reserved.
//

#import "openCVUtil.h"

@implementation OpenCVUtil

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast |kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
//    int bytesPerRow = cvMat.step[0];
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows,                                 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace,  kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false,  kCGRenderingIntentDefault);
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}



-(UIImage *)myGray:(UIImage *)image
{
    cv::Mat originImage = [self cvMatFromUIImage:image];
    cv::Mat resultImage;
    cvtColor(originImage, resultImage, CV_BGR2GRAY);
    
    return [self UIImageFromCVMat:resultImage];
}

-(UIImage *)myHomomorphicFilter:(UIImage *) image
{
    // Variables ========================================================================================
    int D0_GHPF = 80; // Gaussian HPF cut-off deviation
    // ==================================================================================================
    // Getting the frequency and magnitude of image =====================================================
    
    cv::Mat originImage = [self cvMatFromUIImage:image];
    cv::Mat resultImage;
    
    originImage.convertTo(originImage, CV_32F);
    originImage += 1;
//    log(originImage,originImage);
    cv::Mat padded1;
    int m1 = cv::getOptimalDFTSize( originImage.rows );
    int n1 = cv::getOptimalDFTSize( originImage.cols );
    cv::copyMakeBorder(originImage, padded1, 0, m1 - originImage.rows, 0, n1 - originImage.cols, cv::BORDER_CONSTANT, cv::Scalar::all(0));
    
    cv::Mat image_planes[] = {cv::Mat_<float>(padded1), cv::Mat::zeros(padded1.size(), CV_32F)};
    cv::Mat image_complex;
    cv::merge(image_planes, 2, image_complex);
    
    cv::dft(image_complex, image_complex);
    cv::split(image_complex, image_planes);
    
    // starting with this part we have the real part of the image in planes[0] and the imaginary in planes[1]
    cv::Mat image_phase;
    cv::phase(image_planes[0], image_planes[1], image_phase);
    cv::Mat image_mag;
    cv::magnitude(image_planes[0], image_planes[1], image_mag);
    
    // Shifting the DFT
    image_mag = image_mag(cv::Rect(0, 0, image_mag.cols & -2, image_mag.rows & -2));
    int cx = image_mag.cols/2;
    int cy = image_mag.rows/2;
    
    
    cv::Mat q0(image_mag, cv::Rect(0, 0, cx, cy));
    cv::Mat q1(image_mag, cv::Rect(cx, 0, cx, cy));
    cv::Mat q2(image_mag, cv::Rect(0, cy, cx, cy));
    cv::Mat q3(image_mag, cv::Rect(cx, cy, cx, cy));
    
    cv::Mat tmp;
    q0.copyTo(tmp);
    q3.copyTo(q0);
    tmp.copyTo(q3);
    
    q1.copyTo(tmp);
    q2.copyTo(q1);
    tmp.copyTo(q2);
    
    // Creating GHPF ====================================================================================
    cv::Mat GHPF(image_mag.size(), CV_32F, 255);
    
    float tempVal = float((-1.0)/float(pow(float(D0_GHPF),2)));
    for (int i=0; i < GHPF.rows; i++)
        for (int j=0; j < GHPF.cols; j++)
        {
            float dummy2 = float(pow(float(i - cy), 2) + pow(float(j - cx), 2));
            dummy2 = (2.0 - 0.25) * (1.0 - float(exp(float(dummy2 * tempVal)))) + 0.25;
            GHPF.at<float>(i,j) = 255 * dummy2;
        }
    cv::normalize(GHPF, GHPF, 0, 1, CV_MINMAX);
//    cv::imshow("test", GHPF);
    cv::waitKey(0);
    // Applying GHPF filter ==================================================================================
    cv::Mat GHPF_result(image_mag.size(), CV_32F);
    cv::multiply(image_mag, GHPF, GHPF_result);
    
    // reversing the shift ==============================================================================
    cv::Mat q0_GHPF(GHPF_result, cv::Rect(0, 0, cx, cy));
    cv::Mat q1_GHPF(GHPF_result, cv::Rect(cx, 0, cx, cy));
    cv::Mat q2_GHPF(GHPF_result, cv::Rect(0, cy, cx, cy));
    cv::Mat q3_GHPF(GHPF_result, cv::Rect(cx, cy, cx, cy));
    
    cv::Mat tmp_GHPF;
    q0_GHPF.copyTo(tmp_GHPF);
    q3_GHPF.copyTo(q0_GHPF);
    tmp_GHPF.copyTo(q3_GHPF);
    
    q1_GHPF.copyTo(tmp_GHPF);
    q2_GHPF.copyTo(q1_GHPF);
    tmp_GHPF.copyTo(q2_GHPF);
    
    // Reconstructing the image with new GHPF filter ====================================================
    cv::Mat GHPFresult_planes[2];
    cv::polarToCart(GHPF_result, image_phase,GHPFresult_planes[0], GHPFresult_planes[1]);
    
    cv::Mat GHPFresult_complex;
    cv::merge(GHPFresult_planes,2,GHPFresult_complex);
    
    //calculating the iDFT for GHPF
    cv::Mat GHPF_inverseTransform;
    cv::dft(GHPFresult_complex, GHPF_inverseTransform, cv::DFT_INVERSE|cv::DFT_REAL_OUTPUT);
    
    exp(GHPF_inverseTransform,GHPF_inverseTransform);
    cv::normalize(GHPF_inverseTransform, GHPF_inverseTransform, 0, 1, CV_MINMAX);
//    cv::imshow("GHPF Reconstructed", GHPF_inverseTransform);
    cv::waitKey(0);
    return [self UIImageFromCVMat:resultImage];
}
@end
