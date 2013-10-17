//
//  ViewController.m
//  fanController
//
//  Created by Greg Paton on 8/19/13.
//  Copyright (c) 2013 Greg Paton. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize weather;
@synthesize inTemp;
@synthesize outTemp;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    weather = [[NSMutableString alloc] initWithString:@"-"];
    inTemp = [[NSMutableString alloc] initWithString:@"0"];
    outTemp = [[NSMutableString alloc] initWithString:@"0"];
    
    host = @"192.168.0.31";
    port = 12345;
    
    // Disable button until state of fan is known
    [_bt_onOff setEnabled:false];
    
    labelAnimation = [CATransition animation];
    labelAnimation.delegate = self;
    labelAnimation.duration = 1.0;
    labelAnimation.type = kCATransitionFade;
    labelAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [_ai_refresh setHidesWhenStopped:true];
    [self clearWeather];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Network 

- (BOOL)initNetworkCommunication {
    NSUInteger ret1 = [inputStream streamStatus];
    NSUInteger ret2 = [outputStream streamStatus];
    // Check if streams are already open
    // Note: this check assumes the streams will NOT be called from other threads
    //       doesn't check if streams are reading/writing
    if ([inputStream streamStatus] == NSStreamStatusOpen &&
        [outputStream streamStatus] == NSStreamStatusOpen)
        return YES;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    [outputStream open];
    
    ret1 = [inputStream streamStatus];
    ret2 = [outputStream streamStatus];
    
    if ([inputStream streamStatus] == NSStreamStatusError ||
        [outputStream streamStatus] == NSStreamStatusError)
        return NO;
    
    if ([inputStream streamStatus] == NSStreamStatusOpening)
        while ([inputStream streamStatus] != NSStreamStatusOpen);
    
    if ([outputStream streamStatus] == NSStreamStatusOpening)
        while ([outputStream streamStatus] != NSStreamStatusOpen);
    
    return YES;
}

- (void)sendString:(NSString*)str {
    NSData *data = [[NSData alloc] initWithData:[str dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

#pragma mark - IBAction

- (IBAction)turnOnOff:(id)sender {
    turnOnOffThread = [[NSThread alloc] initWithTarget:self selector:@selector(toggleOnOff) object:nil];
    [updateThread start];
}

- (IBAction)refresh:(id)sender {
    if ([updateThread isExecuting])
        return;
    
    [self clearWeather];
    updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(update) object:nil];
    [updateThread start];
    [_ai_refresh startAnimating];
}

- (void)updateWeather {
    [_lb_in setEnabled:true];
    [_lb_out setEnabled:true];
    [_lb_weather.layer addAnimation:labelAnimation forKey:@"changeTextTransition"];
    [_lb_weather setText:weather];
    [_lb_weather setEnabled:true];
    [_lb_outTemp.layer addAnimation:labelAnimation forKey:@"changeTextTransition"];
    [_lb_outTemp setText:[NSString stringWithFormat:@"%@\u00B0F", outTemp]];
    [_lb_outTemp setEnabled:true];
    [_lb_inTemp.layer addAnimation:labelAnimation forKey:@"changeTextTransition"];
    [_lb_inTemp setText:[NSString stringWithFormat:@"%@\u00B0F", inTemp]];
    [_lb_inTemp setEnabled:true];
}

- (void)clearWeather {
    [_lb_in setEnabled:false];
    [_lb_out setEnabled:false];
    [_lb_weather setEnabled:false];
    [_lb_outTemp setEnabled:false];
    [_lb_inTemp setEnabled:false];
}

- (BOOL)getWeather {
    NSDate *stime = [NSDate date];
    BOOL netRet = NO;
    
    // Allow timeout of 5 seconds
    while (NO == netRet && [stime timeIntervalSinceNow] > -5.0) {
        netRet = [self initNetworkCommunication];
    }
    
    if (NO == netRet)
        return NO;
    
    [self sendString:@"4"];
    uint8_t data[64];
    [inputStream read:data maxLength:64];
    NSString *str = [NSString stringWithUTF8String:(char*)data];
    if (str == NULL)
        return NO;
    
    NSRange otRange = [str rangeOfString:@"OT="];
    NSRange itRange = [str rangeOfString:@"IT="];
    if (otRange.location == NSNotFound || itRange.location == NSNotFound)
        return NO;
    
    [weather setString:[str substringWithRange:NSMakeRange(0, otRange.location)]];
    [outTemp setString:[str substringWithRange:NSMakeRange(otRange.location + 3, 4)]];
    [inTemp setString:[str substringWithRange:NSMakeRange(itRange.location + 3, 4)]];
    
    return YES;
}

#pragma mark - Threading

- (void)update {
    if ([self getWeather]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateWeather];
        }];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [_ai_refresh stopAnimating];
    }];
}

- (void)toggleOnOff {
    NSString *response;
    NSString *title;
    NSString *str = NULL;
    int timeout = 0;
    
    [_ai_refresh startAnimating];
    
    if (false == [self initNetworkCommunication]) {
        [_ai_refresh stopAnimating];
        return;
    }
    
    if ([[_bt_onOff titleForState:UIControlStateNormal] isEqualToString:@"Turn On"]) {
        response  = [NSString stringWithFormat:@"1"];
        title = [NSString stringWithFormat:@"Turn Off"];
    }
    else {
        response  = [NSString stringWithFormat:@"2"];
        title = [NSString stringWithFormat:@"Turn On"];
    }
    
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
    
    // Check if confirmation has been sent back
    uint8_t recvdata[64];
    while ([inputStream read:recvdata maxLength:64] < 1 &&
           timeout < 1000)
        ++timeout;
    str = [NSString stringWithUTF8String:(char*)recvdata];
    if (str != NULL && [str isEqualToString:response])
        [_bt_onOff setTitle:title forState:UIControlStateNormal];
    
    [_ai_refresh stopAnimating];
}

@end
