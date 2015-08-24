//
//  ViewController.m
//  ScanQR
//
//  Created by MengHua on 8/16/15.
//  Copyright (c) 2015 menghua.cn. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UILabel *frameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *myImageView;

@property (retain) AVCaptureDevice *devices;
@property (retain) AVCaptureSession *session;

@property (retain) AVCaptureDeviceInput *camera;
@property (retain) AVCaptureVideoDataOutput *video;

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.frameLabel.layer setBorderWidth:1.0f];
    [self.frameLabel.layer setBorderColor:[UIColor redColor].CGColor];
    
    [self.messageLabel setText:@"This is a Message Label"];
    
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
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    [_previewLayer setFrame:self.view.bounds];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    
    [_session startRunning];
}

int x=0;
- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
    x++;
    [self.messageLabel setText:[NSString stringWithFormat:@"Tap %d times.",x]];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    
//    NSLog(@"Just a test category");
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    /*We display the result on the custom layer*/
    /*self.customLayer.contents = (id) newImage;*/
    
    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    
    //crop ->uiimage 
    
    
    if (x==1){
        x++;
        NSString * resultString = [self recognize:image];
        NSLog(@"result: %@",resultString);
        [_messageLabel setText:[NSString stringWithFormat:@"%@", resultString]];
        [_messageLabel setNeedsDisplay];
        self.myImageView.image = image;
    }
    
//    NSLog(@"Just a test category");
    
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    //[_messageLabel setText:[NSString stringWithFormat:@"%d", x]];

}

- (NSString *)recognize: (UIImage *) image
{
//    
//    // Languages are used for recognition (e.g. eng, ita, etc.). Tesseract engine
//    // will search for the .traineddata language file in the tessdata directory.
//    // For example, specifying "eng+ita" will search for "eng.traineddata" and
//    // "ita.traineddata". Cube engine will search for "eng.cube.*" files.
//    // See https://code.google.com/p/tesseract-ocr/downloads/list.
//    
//    // Create your G8Tesseract object using the initWithLanguage method:
//    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
//    
//    // Optionaly: You could specify engine to recognize with.
//    // G8OCREngineModeTesseractOnly by default. It provides more features and faster
//    // than Cube engine. See G8Constants.h for more information.
//    //tesseract.engineMode = G8OCREngineModeTesseractOnly;
//    
//    // Set up the delegate to receive Tesseract's callbacks.
//    // self should respond to TesseractDelegate and implement a
//    // "- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract"
//    // method to receive a callback to decide whether or not to interrupt
//    // Tesseract before it finishes a recognition.
//    tesseract.delegate = self;
//    
//    // Optional: Limit the character set Tesseract should try to recognize from
//    // tesseract.charWhitelist = @"0123456789";
//    
//    // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
//    // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
//    // See G8TesseractParameters.h for a complete list of Tesseract variables
//    
//    // Optional: Limit the character set Tesseract should not try to recognize from
//    //tesseract.charBlacklist = @"OoZzBbSs";
//    
//    // Specify the image Tesseract should recognize on
//    tesseract.image = [image g8_blackAndWhite];
//    
//    // Optional: Limit the area of the image Tesseract should recognize on to a rectangle
//    //tesseract.rect = CGRectMake(20, 20, 100, 100);
//    
//    // Optional: Limit recognition time with a few seconds
//    //tesseract.maximumRecognitionTime = 2.0;
//    
//    // Start the recognition
//    [tesseract recognize];
//    
//    NSString *returnString = [tesseract recognizedText];
//    
//    // Retrieve the recognized text
//    // NSLog(@"Result: %@", returnString);
//    
//    // You could retrieve more information about recognized text with that methods:
//    NSArray *characterBoxes = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
//    NSArray *paragraphs = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
//    NSArray *characterChoices = tesseract.characterChoices;
//    UIImage *imageWithBlocks = [tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:NO];
//    
//    return returnString;
    
    
    NSString  *returnString;
    // Create RecognitionOperation
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] initWithLanguage: @"eng"];
    
    // Configure inner G8Tesseract object as described before
    operation.tesseract.language = @"eng";
    //operation.tesseract.charWhitelist = @"01234567890";
    operation.tesseract.image = [image g8_blackAndWhite];
    
    // Setup the recognitionCompleteBlock to receive the Tesseract object
    // after text recognition. It will hold the recognized text.
    operation.recognitionCompleteBlock = ^(G8Tesseract *recognizedTesseract) {
        // Retrieve the recognized text upon completion
        NSString* returnString = [recognizedTesseract recognizedText];
        NSLog(@"%@", returnString);
        
    };
    
    // Add operation to queue
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
    return returnString;
}

- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
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
