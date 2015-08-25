//
//  ViewController.m
//  ScanQR
//
//  Created by MengHua on 8/16/15.
//  Copyright (c) 2015 menghua.cn. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "processViewController.h"

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UILabel *frameLabel;

@property (retain) AVCaptureDevice *devices;
@property (retain) AVCaptureSession *session;

@property (retain) AVCaptureDeviceInput *camera;
@property (retain) AVCaptureVideoDataOutput *video;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) CALayer *cameraViewLayer;

@property (retain) UIImage *croppedImage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.frameLabel.layer setBorderWidth:1.0f];
    [self.frameLabel.layer setBorderColor:[UIColor redColor].CGColor];
    
    // AVfounddation related init
    NSError *error;
    _devices = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _session = [[AVCaptureSession alloc] init];
    [_session beginConfiguration];
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    [_session commitConfiguration];
    
    _camera = [AVCaptureDeviceInput deviceInputWithDevice:_devices error:&error];
    if ([_session canAddInput:_camera]) {
        [_session beginConfiguration];
        [_session addInput:_camera];
        [_session commitConfiguration];
    }
    _video = [[AVCaptureVideoDataOutput alloc] init];
    [_video setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey,nil]];
    [_video setAlwaysDiscardsLateVideoFrames:YES];
    [_video setSampleBufferDelegate:self queue:dispatch_queue_create("video queue", nil)];
    if ([_session canAddOutput:_video]) {
        [_session addOutput:_video];
    }
    
//    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//    [_previewLayer setFrame:self.view.bounds];
//    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
//    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    self.cameraViewLayer = [CALayer layer];
    [self.cameraViewLayer setBounds:CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width)];
    [self.cameraViewLayer setPosition:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2)];
    [self.cameraViewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI/2)];
    [self.cameraViewLayer setContentsGravity:kCAGravityResizeAspect];
    [self.view.layer insertSublayer:self.cameraViewLayer atIndex:0];
    
    [_session startRunning];
}

- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    NSLog(@"Already Tapped...");
    [self performSegueWithIdentifier:@"processIdentifier" sender:NULL];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"processIdentifier"]) {
        processViewController *v = (processViewController *)segue.destinationViewController;
        NSLog(@"here is segue....%@...%@...",v,self.croppedImage);
        if (self.croppedImage) {
            v.croppedImage = self.croppedImage;
            NSLog(@"set croppedImage...");
        } else
            NSLog(@"self croppedImage is NULL...");
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//    NSLog(@"%ld", (long)[UIImage imageWithCGImage:newImage].imageOrientation);
//     UIImage *image = [self imageByScalingToSize: CGSizeMake(width, height) sourceImage: [UIImage imageWithCGImage:newImage]];
    // image processing part start
    
    // do something
    
    
    // image processing part end
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.cameraViewLayer setContents:(__bridge id)(newImage)];
    });
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    double labelWidth = self.frameLabel.frame.size.width;
    double labelHeight = self.frameLabel.frame.size.height;
    double viewWidth = self.view.frame.size.width;
    double viewHeight = self.view.frame.size.height;
    
    double widthRatio = labelWidth / viewWidth;
    double heightRatio = labelHeight / viewHeight;
    
    // NSLog(@"%f, %f", labelWidth, labelHeight);
    
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    
    double cropWidth = widthRatio * image.size.width;
    double cropHeight = heightRatio * image.size.height;
    
    CGSize imageSize = CGSizeMake(cropWidth, cropHeight);
    
//    CGSize imageSize = CGSizeMake(image.size.width, image.size.height);
    CGRect croppedImageSize = CGRectMake((image.size.height-cropHeight)/2, (image.size.width-cropWidth)/2, cropWidth, cropHeight);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, croppedImageSize);
   
    
//    NSLog(@"%@", imageSize);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextRotateCTM (context, M_PI/2);
    
    
//    CGContextDrawImage(context, CGRectMake(0,0,cropWidth,cropHeight), croppedImageRef);
//    [image drawAtPoint:CGPointMake((image.size.height-cropHeight)/2, (image.size.width-cropWidth)/2)];
    [image drawAtPoint:CGPointMake(0,0)];
    //[image drawInRect:CGRectMake((image.size.height-cropHeight)/2, (image.size.width-cropWidth)/2, cropWidth, cropHeight)];
    
//    [[UIImage imageWithCGImage:croppedImageRef] drawAtPoint:CGPointMake(0,0)];
    
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    self.croppedImage = img;
//    self.croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    UIGraphicsEndImageContext();
    
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);

    CGImageRelease(croppedImageRef);

}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to interrupt tesseract before it finishes
}

static inline double radians (double degrees) {return degrees * M_PI/180;}

-(UIImage*)imageByScalingToSize:(CGSize)targetSize sourceImage: (UIImage *) image
{
    UIImage* sourceImage = image;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    }
    
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (bitmap, radians(90));
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (bitmap, radians(-90));
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, radians(-180.));
    }
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return newImage; 
}

//- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
//{
//    for (AVMetadataMachineReadableCodeObject *metadata in metadataObjects) {
//        if ([metadata.type isEqualToString: AVMetadataObjectTypeQRCode]) {
//            self.borderView.hidden = NO;
//        } else {
//            <#statements#>
//        }
//    }
//}


@end
