//
//  processViewController.h
//  ScanQR
//
//  Created by MengHua on 8/23/15.
//  Copyright (c) 2015 menghua.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>

@interface processViewController : UIViewController <G8TesseractDelegate>

@property (weak, nonatomic) UIImage *croppedImage;

@end
