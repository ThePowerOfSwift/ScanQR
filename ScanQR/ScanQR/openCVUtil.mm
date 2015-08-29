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
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace,  kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false,  kCGRenderingIntentDefault);
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

-(cv::Mat) ifftshift:(cv::Mat) src
{
    cv::Mat dst;
    src.copyTo(dst);
    int cx = dst.cols/2;
    int cy = dst.rows/2;
    
    cv::Mat q0(dst, cv::Rect(0, 0, cx, cy));   // Top-Left - Create a ROI per quadrant
    cv::Mat q1(dst, cv::Rect(cx, 0, cx, cy));  // Top-Right
    cv::Mat q2(dst, cv::Rect(0, cy, cx, cy));  // Bottom-Left
    cv::Mat q3(dst, cv::Rect(cx, cy, cx, cy)); // Bottom-Right
    
    cv::Mat tmp;                           // swap quadrants (Top-Left with Bottom-Right)
    q0.copyTo(tmp);
    q3.copyTo(q0);
    tmp.copyTo(q3);
    
    q1.copyTo(tmp);                    // swap quadrant (Top-Right with Bottom-Left)
    q2.copyTo(q1);
    tmp.copyTo(q2);
    return dst;
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
    cvtColor(originImage, originImage, CV_BGR2GRAY);
    cv::Mat resultImage;
    int type = originImage.type();
    // Yemin's codes begin
    
    //The original image is uint image whose gray scale
    //is in the range of [0,255];
    //Then we change the type to float
    //so as we can perform fft on it.
    //Note: the intensity level do not change.
    //That is to say, the original intensity, say 200,
    //will become 200.0 after the convertion
    originImage.convertTo(originImage, CV_32F);
    originImage += 1;
    
    //    showFloatImg(originImage,"Ori");
    
    
    cv::Mat logImg;
    
    log(originImage, logImg);
    //The log image will be totall black since log(255) is only 5,
    //a small number
    //    showFloatImg(logImg,"Log");
    
    cv::Mat padded;                            //expand input image to optimal size
    int m = cv::getOptimalDFTSize( originImage.rows );
    int n = cv::getOptimalDFTSize( originImage.cols ); // on the border add zero values
    int orgWidth = originImage.cols;
    int orgHeight = originImage.rows;
    copyMakeBorder(logImg, padded, 0, m - originImage.rows, 0, n - originImage.cols, cv::BORDER_CONSTANT, cv::Scalar::all(0));
    int cx = originImage.cols/2;
    int cy = originImage.rows/2;
    
    //first shift the image before fft2
    padded = [self ifftshift:padded];
    
    cv::Mat planes[] = {cv::Mat_<float>(padded), cv::Mat::zeros(padded.size(), CV_32F)};
    cv::Mat complexI;
    merge(planes, 2, complexI);         // Add to the expanded another plane with zeros
    
    dft(complexI, complexI);            // this way the result may fit in the source matrix
    
    
    split(complexI, planes);                   // planes[0] = Re(DFT(I), planes[1] = Im(DFT(I))
    //magnitude(planes[0], planes[1], planes[0]);// planes[0] = magnitude
    
    //ifftshift after fft2
    complexI = [self ifftshift:complexI];
    
    
    
    //Generate the Gaussian HPF
    cv::Mat GHPF(complexI.size(), CV_32F, 255);
    
    float tempVal = float((-1.0)/float(pow(float(D0_GHPF),2)));
    for (int i=0; i < GHPF.rows; i++) {
        for (int j=0; j < GHPF.cols; j++) {
            float dummy2 = float(pow(float(i - cy), 2) + pow(float(j - cx), 2));
            dummy2 = (2.0 - 0.25) * (1.0 - float(exp(float(dummy2 * tempVal)))) + 0.25;
            GHPF.at<float>(i,j) = 255 * dummy2;
        }
    }
    
    normalize(GHPF, GHPF, 0, 1, CV_MINMAX);
    GHPF.convertTo(GHPF, complexI.type());
    
    //    imshow("GHPF", GHPF);
    //    waitKey(0);
    
    // Applying GHPF filter
    // The filter should be applied to both Im and Re part of the fft result
    // of the original image
    
    cv::Mat GHPF_result_Re(complexI.size(), GHPF.type());
    cv::Mat GHPF_result_Im(complexI.size(), GHPF.type());
    multiply(planes[0], GHPF, GHPF_result_Re);
    multiply(planes[1], GHPF, GHPF_result_Im);
    cv::Mat GHPF_Result_List[] = {GHPF_result_Re, GHPF_result_Im};
    cv::Mat GHPF_Result;
    // merge the two channel to one Mat
    merge(GHPF_Result_List, 2, GHPF_Result);
    
    
    
    
    cv::Mat inverseTransform;
    
    // ifftshift before ifft2
    
    GHPF_Result = [self ifftshift:GHPF_Result];
    dft(GHPF_Result, inverseTransform, cv::DFT_INVERSE|cv::DFT_REAL_OUTPUT);
    split(inverseTransform, planes);
    magnitude(planes[0], planes[1], planes[0]);
    cv::Mat ifftResult = planes[0];
    ifftResult.convertTo(ifftResult, CV_32F);
    ifftResult = [self ifftshift:ifftResult];
    
    // before exp, re-range the image so that the exp(intensity) would
    // not exceed the limit
    normalize(ifftResult, ifftResult, 0, 2, CV_MINMAX);
    // then exp
    
    exp(ifftResult, ifftResult);
    
    // after that, re-range the image
    normalize(ifftResult, ifftResult, 0, 1, CV_MINMAX);
//    cv::Rect myROI(n-orgWidth, m - orgHeight, orgWidth, orgHeight);
    cv::Rect myROI(0,0, orgWidth, orgHeight);
    cv::Mat croppedImage = ifftResult(myROI);
    resultImage = croppedImage;
    normalize(resultImage, resultImage, 0, 255, CV_MINMAX);
    resultImage.convertTo(resultImage, CV_8U);
    
    
    
    
    return [self UIImageFromCVMat:resultImage];
}
@end
