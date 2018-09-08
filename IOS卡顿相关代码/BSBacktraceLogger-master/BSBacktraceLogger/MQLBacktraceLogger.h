//
//  MQLBacktraceLogger.h
//  MQLBacktraceLogger
//
//  Created by 张星宇 on 16/8/27.
//  Copyright © 2016年 bestswifter. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MQLLOG NSLog(@"%@",[MQLBacktraceLogger MQL_backtraceOfCurrentThread]);
#define MQLLOG_MAIN NSLog(@"%@",[MQLBacktraceLogger MQL_backtraceOfMainThread]);
#define MQLLOG_ALL NSLog(@"%@",[MQLBacktraceLogger MQL_backtraceOfAllThread]);

@interface MQLBacktraceLogger : NSObject

+ (NSString *)MQL_backtraceOfAllThread;
+ (NSString *)MQL_backtraceOfCurrentThread;
+ (NSString *)MQL_backtraceOfMainThread;
+ (NSString *)MQL_backtraceOfNSThread:(NSThread *)thread;

@end
