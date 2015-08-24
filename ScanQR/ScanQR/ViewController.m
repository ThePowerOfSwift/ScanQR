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
    
    [_session startRunning];
}

- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    NSLog(@"Already Tapped...");
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"processIdentifier"]) {
        processViewController *v = (processViewController *)segue.destinationViewController;
        if (self.croppedImage) {
            v.croppedImage = self.croppedImage;
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
    
    [self.view.layer setContents:(__bridge id)(newImage)];
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    
    CGSize imageSize = CGSizeMake(image.size.width, image.size.height);
    CGRect croppedImageSize = CGRectMake(image.size.width/2, image.size.height/2, 250, 250);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, croppedImageSize);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, croppedImageSize, croppedImageRef);
    self.croppedImage = [UIImage imageWithCGImage:croppedImageRef];
    UIGraphicsEndImageContext();
    
    /*We relase the CGImageRef*/
    CGContextRelease(context);
    CGImageRelease(newImage);

    CGImageRelease(croppedImageRef);

}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to interrupt tesseract before it finishes
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
