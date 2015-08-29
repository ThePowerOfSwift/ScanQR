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
@property (retain) OpenCVUtil *opencv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.opencv = [[OpenCVUtil alloc] init];
    
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
    
    NSLog(@"start Running");
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

int count = 0;
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    count++;
//    if(count != 10){
//        return;
//    }else{
//        count = 0;
//    }
    /* *** */
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
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef rawImage = CGBitmapContextCreateImage(context);
    
//    UIImage *image= [UIImage imageWithCGImage:rawImage scale:1.0 orientation:UIImageOrientationRight];
    UIImage *image= [UIImage imageWithCGImage:rawImage scale:1.0 orientation:UIImageOrientationUp];
    
    /*We release some components*/
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(rawImage);
    /* *** */
//    NSLog(@"get Raw Image");
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    double labelWidth = self.frameLabel.frame.size.width;
    double labelHeight = self.frameLabel.frame.size.height;
    double viewWidth = self.view.frame.size.width;
    double viewHeight = self.view.frame.size.height;
    
    double widthRatio = labelWidth / viewWidth;
    double heightRatio = labelHeight / viewHeight;
    
    double imageWidth = image.size.height;
    double imageHeight = image.size.width;
    
    double cropWidth = widthRatio * imageWidth;
    double cropHeight = heightRatio * imageHeight;
//    double cropWidth = widthRatio * image.size.height;
//    double cropHeight = heightRatio * image.size.width;
    
    
    CGSize imageSize = CGSizeMake(cropWidth, cropHeight);
    
    CGRect croppedImageSize = CGRectMake((imageHeight-cropHeight)/2, (imageWidth-cropWidth)/2, cropWidth, cropHeight);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, croppedImageSize);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    
    // image processing part start
//    UIImage *processedImage = [self.opencv myHomomorphicFilter:croppedImage];
    UIImage* processedImage = [self.opencv myGray:croppedImage];
//        UIImage *temp_image= [UIImage imageWithCGImage:processedImage scale:1.0 orientation:UIImageOrientationRight];
    // image processing part end
    UIGraphicsBeginImageContext(CGSizeMake(imageHeight,imageWidth));
    CGContextRef viewContext = UIGraphicsGetCurrentContext();
    [image drawAtPoint: CGPointMake(0,0)];
//    [processedImage drawAtPoint:CGPointMake((imageHeight-cropWidth)/2,(imageWidth-cropHeight)/2)];
    [processedImage drawInRect:CGRectMake((imageHeight-cropWidth)/2,(imageWidth-cropHeight)/2, cropWidth,cropHeight)];
    image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGContextRelease(viewContext);
    image = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRight];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.cameraViewLayer setContents:(__bridge id)(image.CGImage)];
        //        [self.cameraViewLayer setContents:(__bridge id)(newImage)];
    });
    
//    NSLog(@"get Processed Image");
    
    croppedImage = processedImage;
    UIGraphicsBeginImageContext(imageSize);
    context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGFloat size = MIN(croppedImage.size.width, croppedImage.size.height);
    CGContextTranslateCTM(context, size / 2, size / 2);
    CGContextRotateCTM (context, M_PI/2);
    CGContextTranslateCTM(context, -size / 2, -size / 2);
    [croppedImage drawAtPoint:CGPointMake(0,0)];
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    self.croppedImage = img;
    UIGraphicsEndImageContext();
    CGContextRelease(context);
    
//    NSLog(@"get Cropped Image");
    
    
    /*We relase the CGImageRef*/
    CGImageRelease(croppedImageRef);
//    CGImageRelease(processedImage);

    
//    NSLog(@"end Image");
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to interrupt tesseract before it finishes
}


@end
