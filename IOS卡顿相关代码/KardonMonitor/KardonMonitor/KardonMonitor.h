//
//  KardonMonitor.h
//  KardonMonitor
//
//  Created by ma qianli on 2018/9/6.
//  Copyright © 2018年 ma qianli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KardonMonitor : NSObject

/**
 获取卡顿监测器单例
 @return 卡顿监测器单例
 */
+(instancetype)kardonMonitor;

/**
 启动卡顿监测
 */
-(void)startKardonMonitor;

/**
 停止卡顿监测
 */
-(void)stopKardonMonitor;

@end
