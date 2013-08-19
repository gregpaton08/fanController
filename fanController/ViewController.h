//
//  ViewController.h
//  fanController
//
//  Created by Greg Paton on 8/19/13.
//  Copyright (c) 2013 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSStreamDelegate> {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}
@property (weak, nonatomic) IBOutlet UIButton *bt_onOff;

@end
