//
//  ViewController.m
//  KardonMonitor
//
//  Created by ma qianli on 2018/9/6.
//  Copyright © 2018年 ma qianli. All rights reserved.
//

#import "ViewController.h"
#import "KardonMonitor.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[KardonMonitor kardonMonitor]startKardonMonitor];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    long temp = 0;
    for (long i = 0; i < 1000000; i++) {
        temp = i;
    }
    
    for (long j = 0; j < 1000000; j++) {
        temp = j;
    }
    
    {
        for (long i = 0; i < 1000000; i++) {
            temp = i;
        }
        
        for (long j = 0; j < 1000000; j++) {
            temp = j;
        }
    }
}

- (IBAction)start:(id)sender {
    [[KardonMonitor kardonMonitor]startKardonMonitor];
}
- (IBAction)stop:(id)sender {
    [[KardonMonitor kardonMonitor]stopKardonMonitor];
}


@end
