//
//  processViewController.m
//  ScanQR
//
//  Created by MengHua on 8/23/15.
//  Copyright (c) 2015 menghua.cn. All rights reserved.
//

#import "processViewController.h"

@interface processViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *croppedImageView;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;


@end

@implementation processViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 在这里处理:do processing here... the image is 'croppedImage'
    NSLog(@"what is croppedImage ,%@ ...",self.croppedImage);
    self.croppedImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.croppedImageView setImage:self.croppedImage];
    [self.resultTextView setText:[self recognize: self.croppedImage] ];
    
    
}
- (IBAction)backToView:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)recognize: (UIImage *) image
{
    
    // Languages are used for recognition (e.g. eng, ita, etc.). Tesseract engine
    // will search for the .traineddata language file in the tessdata directory.
    // For example, specifying "eng+ita" will search for "eng.traineddata" and
    // "ita.traineddata". Cube engine will search for "eng.cube.*" files.
    // See https://code.google.com/p/tesseract-ocr/downloads/list.
    
    // Create your G8Tesseract object using the initWithLanguage method:
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    
    // Optionaly: You could specify engine to recognize with.
    // G8OCREngineModeTesseractOnly by default. It provides more features and faster
    // than Cube engine. See G8Constants.h for more information.
    //tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    // Set up the delegate to receive Tesseract's callbacks.
    // self should respond to TesseractDelegate and implement a
    // "- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract"
    // method to receive a callback to decide whether or not to interrupt
    // Tesseract before it finishes a recognition.
    tesseract.delegate = self;
    
    // Optional: Limit the character set Tesseract should try to recognize from
    // tesseract.charWhitelist = @"0123456789";
    
    // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
    // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
    // See G8TesseractParameters.h for a complete list of Tesseract variables
    
    // Optional: Limit the character set Tesseract should not try to recognize from
    //tesseract.charBlacklist = @"OoZzBbSs";
    
    // Specify the image Tesseract should recognize on
    tesseract.image = [image g8_blackAndWhite];
    
    // Optional: Limit the area of the image Tesseract should recognize on to a rectangle
    //tesseract.rect = CGRectMake(20, 20, 100, 100);
    
    // Optional: Limit recognition time with a few seconds
    //tesseract.maximumRecognitionTime = 2.0;
    
    tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOSD;
    
    // Start the recognition
    [tesseract recognize];
    
//    G8PageIteratorLevelBlock,
//    G8PageIteratorLevelParagraph,
//    G8PageIteratorLevelTextline,
//    G8PageIteratorLevelWord,
//    G8PageIteratorLevelSymbol
    CGSize imageSize = image.size;
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef viewContext = UIGraphicsGetCurrentContext();
    [image drawAtPoint: CGPointMake(0,0)];
    
    NSArray *  recognizedBlocks1 = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelBlock];
    
    [[UIColor blueColor] setStroke];
    
    for (G8RecognizedBlock* recognizedBlock in recognizedBlocks1) {
        CGRect blockRect = [recognizedBlock boundingBoxAtImageOfSize: imageSize];
        NSLog(@"G8PageIteratorLevelBlock:");
        NSLog(@"BoundingBox: %@",NSStringFromCGRect(blockRect));
        NSLog(@"Confidence: %f",recognizedBlock.confidence);
        
        CGContextStrokeRect(viewContext, blockRect);
    }
    
 
    
    NSArray *  recognizedBlocks2 = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
    
    [[UIColor greenColor] setStroke];
    
    for (G8RecognizedBlock* recognizedBlock in recognizedBlocks2) {
        CGRect blockRect = [recognizedBlock boundingBoxAtImageOfSize: imageSize];
        NSLog(@"G8PageIteratorLevelParagraph:");
        NSLog(@"BoundingBox: %@",NSStringFromCGRect(blockRect));
        NSLog(@"Confidence: %f",recognizedBlock.confidence);
        
        CGContextStrokeRect(viewContext, blockRect);
    }
    
    
    
    NSArray *  recognizedBlocks3 = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelTextline];
    
    [[UIColor redColor] setStroke];
    
    for (G8RecognizedBlock* recognizedBlock in recognizedBlocks3) {
        CGRect blockRect = [recognizedBlock boundingBoxAtImageOfSize: imageSize];
        NSLog(@"G8PageIteratorLevelTextline:");
        NSLog(@"BoundingBox: %@",NSStringFromCGRect([recognizedBlock boundingBoxAtImageOfSize: imageSize]));
        NSLog(@"Confidence: %f",recognizedBlock.confidence);
        
        CGContextStrokeRect(viewContext, blockRect);
    }
//
//    NSArray *  recognizedBlocks4 = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelWord];
//    
//    for (G8RecognizedBlock* recognizedBlock in recognizedBlocks4) {
//        NSLog(@"G8PageIteratorLevelWord:");
//        NSLog(@"BoundingBox: %@",NSStringFromCGRect([recognizedBlock boundingBoxAtImageOfSize: imageSize]));
//        NSLog(@"Confidence: %f",recognizedBlock.confidence);
//    }
//    
//    NSArray *  recognizedBlocks5 = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
//    
//    for (G8RecognizedBlock* recognizedBlock in recognizedBlocks5) {
//        NSLog(@"G8PageIteratorLevelSymbol:");
//        NSLog(@"BoundingBox: %@",NSStringFromCGRect([recognizedBlock boundingBoxAtImageOfSize: imageSize]));
//        NSLog(@"Confidence: %f",recognizedBlock.confidence);
//    }
    
    image=UIGraphicsGetImageFromCurrentImageContext();
    [self.croppedImageView setImage:image];
    UIGraphicsEndImageContext();
    CGContextRelease(viewContext);
    
    NSString *returnString = [tesseract recognizedText];
    
    // Retrieve the recognized text
    // NSLog(@"Result: %@", returnString);
    
    // You could retrieve more information about recognized text with that methods:
//    NSArray *characterBoxes = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelSymbol];
//    NSArray *paragraphs = [tesseract recognizedBlocksByIteratorLevel:G8PageIteratorLevelParagraph];
//    NSArray *characterChoices = tesseract.characterChoices;
//    UIImage *imageWithBlocks = [tesseract imageWithBlocks:characterBoxes drawText:YES thresholded:NO];
    
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
