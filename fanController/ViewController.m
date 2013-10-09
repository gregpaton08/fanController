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
//    [self initNetworkCommunication];
//    [self getWeather];
//    [self updateWeather];
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
    // Check if streams are already open
    // Note: this check assumes the streams will NOT be called from other threads
    //       doesn't check if streams are reading/writing
    if ([inputStream streamStatus] == NSStreamStatusOpen &&
        [outputStream streamStatus] == NSStreamStatusOpen)
        return TRUE;
    
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
    
    if ([inputStream streamStatus] != 2 ||
        [outputStream streamStatus] != 2)
        return FALSE;
    
    return TRUE;
}

- (void)sendString:(NSString*)str {
    NSData *data = [[NSData alloc] initWithData:[str dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

#pragma mark - IBAction

- (IBAction)turnOnOff:(id)sender {
    [_ai_refresh startAnimating];
    if (FALSE == [self initNetworkCommunication]) {
        [_ai_refresh stopAnimating];
        return;
    }
    if ([[sender titleForState:UIControlStateNormal] isEqualToString:@"Turn On"]) {
        // Send command to turn on
        NSString *response  = [NSString stringWithFormat:@"1"];
        NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[data bytes] maxLength:[data length]];
        
        // Check if confirmation has been sent back
        uint8_t recvdata[64];
        [inputStream read:recvdata maxLength:64];
        NSString *str = [NSString stringWithUTF8String:(char*)recvdata];
        if (str == NULL) {
            [_ai_refresh stopAnimating];
            return;
        }
        NSLog(@"%@\n", str);
        if ([str isEqualToString:@"1"])
            [sender setTitle:@"Turn Off" forState:UIControlStateNormal];
    }
    else {
        // Send command to turn off
        NSString *response  = [NSString stringWithFormat:@"2"];
        NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[data bytes] maxLength:[data length]];
        
        // Check if confirmation has been sent back
        uint8_t recvdata[64];
        [inputStream read:recvdata maxLength:64];
        NSString *str = [NSString stringWithUTF8String:(char*)recvdata];
        if (str == NULL) {
            [_ai_refresh stopAnimating];
            return;
        }
        NSLog(@"%@\n", str);
        if ([str isEqualToString:@"2"])
        [sender setTitle:@"Turn On" forState:UIControlStateNormal];
    }
    [_ai_refresh stopAnimating];
}

- (IBAction)refresh:(id)sender {
    [self clearWeather];
    updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(update) object:nil];
    [updateThread start];
    [_ai_refresh startAnimating];
//    [self getWeather];
//    [self updateWeather];
}

- (void)updateWeather {
    [_lb_in setEnabled:true];
    [_lb_out setEnabled:true];
    [_lb_weather setText:weather];
    [_lb_weather setEnabled:true];
    [_lb_outTemp setText:[NSString stringWithFormat:@"%@\u00B0F", outTemp]];
    [_lb_outTemp setEnabled:true];
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

- (void)getWeather {
    [self initNetworkCommunication];
    [self sendString:@"4"];
    uint8_t data[64];
    [inputStream read:data maxLength:64];
    NSString *str = [NSString stringWithUTF8String:(char*)data];
    if (str == NULL)
        return;
    
    NSRange otRange = [str rangeOfString:@"OT="];
    NSRange itRange = [str rangeOfString:@"IT="];
    if (otRange.location == NSNotFound || itRange.location == NSNotFound)
        return;
    
    [weather setString:[str substringWithRange:NSMakeRange(0, otRange.location)]];
    [outTemp setString:[str substringWithRange:NSMakeRange(otRange.location + 3, 4)]];
    [inTemp setString:[str substringWithRange:NSMakeRange(itRange.location + 3, 4)]];
}

#pragma mark - Threading

- (void)update {
    [self getWeather];
    [self updateWeather];
    [_ai_refresh stopAnimating];
}

- (void)toggleOnOff {
    
}

@end
