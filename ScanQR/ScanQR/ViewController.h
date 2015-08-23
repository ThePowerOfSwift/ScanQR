//
//  ViewController.h
//  ScanQR
//
//  Created by MengHua on 8/16/15.
//  Copyright (c) 2015 menghua.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>

@interface ViewController : UIViewController <G8TesseractDelegate>

- (NSString *)recognize: (UIImage *) image;
@end

