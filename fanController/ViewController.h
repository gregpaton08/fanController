//
//  ViewController.h
//  fanController
//
//  Created by Greg Paton on 8/19/13.
//  Copyright (c) 2013 Greg Paton. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSStreamDelegate> {
    NSString *host;
    UInt32 port;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    NSThread *updateThread;
    NSThread *turnOnOffThread;
    
    CATransition *labelAnimation;
}
@property (weak, nonatomic) IBOutlet UIButton *bt_onOff;
@property (weak, nonatomic) IBOutlet UIButton *bt_refresh;
@property (weak, nonatomic) IBOutlet UILabel *lb_weather;
@property (weak, nonatomic) IBOutlet UILabel *lb_inTemp;
@property (weak, nonatomic) IBOutlet UILabel *lb_in;
@property (weak, nonatomic) IBOutlet UILabel *lb_outTemp;
@property (weak, nonatomic) IBOutlet UILabel *lb_out;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai_refresh;
@property (nonatomic, retain) NSMutableString *weather;
@property (nonatomic, retain) NSMutableString *inTemp;
@property (nonatomic, retain) NSMutableString *outTemp;

@end
