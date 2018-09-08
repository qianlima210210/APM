//
//  KardonMonitor.m
//  KardonMonitor
//
//  Created by ma qianli on 2018/9/6.
//  Copyright © 2018年 ma qianli. All rights reserved.
//

#import "KardonMonitor.h"
#import "MQLBacktraceLogger.h"

@interface KardonMonitor ()

@property(assign, nonatomic) CFRunLoopObserverRef observer; //主线程runLoop观察者
@property(strong, nonatomic) NSDate *startDate;             //开始执行的时间，即进入kCFRunLoopBeforeSources状态时的时间
@property(assign, nonatomic) BOOL excuting;                 //是否正在执行

@property(strong, nonatomic) NSThread *monitorThread;       //监控线程
@property(strong, nonatomic) NSPort *port;                  //网络端口，目的是保证runloop不退出
@property(assign, nonatomic) CFRunLoopTimerRef timer;       //监控线程中的定时器
@property(assign, nonatomic) NSTimeInterval interval;       //定时器间隔时间
@property(assign, nonatomic) NSTimeInterval fault;          //判断是否卡顿的阙值

-(void)handleStackInfo;

@end

static void mainThreadRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    KardonMonitor *monitor = (__bridge KardonMonitor*)info;
    //NSLog(@"MainRunLoop---%@",[NSThread currentThread]);
    switch (activity) {
        case kCFRunLoopEntry:
            //NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            //NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources:
            //NSLog(@"kCFRunLoopBeforeSources");
            monitor.startDate = [NSDate date];
            monitor.excuting = YES;
            break;
        case kCFRunLoopBeforeWaiting:
            //NSLog(@"kCFRunLoopBeforeWaiting");
            monitor.excuting = NO;
            break;
        case kCFRunLoopAfterWaiting:
            //NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit:
            //NSLog(@"kCFRunLoopExit");
            break;
        default:
            break;
    }
}

static void runLoopTimerCallBack(CFRunLoopTimerRef timer, void *info)
{
    KardonMonitor *monitor = (__bridge KardonMonitor*)info;
    if (!monitor.excuting) {
        return;
    }
    
    // 如果主线程正在执行任务，并且这一次loop 执行到 现在还没执行完，那就需要计算时间差
    NSTimeInterval excuteTime = [[NSDate date] timeIntervalSinceDate:monitor.startDate];
    NSLog(@"定时器---%@",[NSThread currentThread]);
    NSLog(@"主线程执行了---%f秒",excuteTime);
    
    if (excuteTime >= monitor.fault) {
        NSLog(@"线程卡顿了%f秒",excuteTime);
        //FIXME: 稍后处理
        [monitor handleStackInfo];
    }
}

@implementation KardonMonitor

/**
 获取卡顿监测器单例
 @return 卡顿监测器单例
 */
+(instancetype)kardonMonitor{
    static KardonMonitor *kardonMonitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kardonMonitor = [[super allocWithZone:nil]init];
    });
    return kardonMonitor;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        _interval = 0.00001;
        _fault = 0.001;
    }
    return self;
}

+(id)allocWithZone:(NSZone *)zone{
    return [self kardonMonitor];
}

-(id)copyWithZone:(NSZone *)zone{
    return self;
}

-(id)mutableCopyWithZone:(NSZone *)zone{
    return self;
}

/**
 启动卡顿监测
 */
-(void)startKardonMonitor{
    
    //1、添加主线程runLoop观察者
    [self addMainThreadRunLoopObserver];
    
    //2、创建和配置监听线程
    [self createAndConfigMonitorThread];
}

/**
 停止卡顿监测
 */
-(void)stopKardonMonitor{
    //1、从主线程移除观察者
    [self removeMainThreadRunLoopObserver];
    
}

//MARK: --私有方法

/**
 添加主线程runLoop观察者
 */
-(void)addMainThreadRunLoopObserver{
    if (_observer) {
        return;
    }
    
    // 1.创建observer
    CFRunLoopObserverContext context = {0,(__bridge void*)self, NULL, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &mainThreadRunLoopObserverCallBack,
                                        &context);
    // 2.将observer添加到主线程的RunLoop中
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
}


/**
 从主线程移除观察者
 */
-(void)removeMainThreadRunLoopObserver{
    if (_observer) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = NULL;
        _excuting = NO;
    }
}

/**
 创建和配置监听线程
 */
-(void)createAndConfigMonitorThread{
    if (_port) {
        return;
    }
    
    _monitorThread = [[NSThread alloc]initWithTarget:self selector:@selector(monitorThreadMainOperation) object:nil];
    [_monitorThread start];
}

-(void)monitorThreadMainOperation{
    @autoreleasepool {
        
        [[NSThread currentThread] setName:@"KardonMonitor"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        //添加一个端口
        _port = [NSMachPort port];
        [runLoop addPort:_port forMode:NSDefaultRunLoopMode];
        
        // 添加定时器到监控线程
        [self addTimerToMonitorThread];
        
        //跑起来吧
        [runLoop run];
        
    }
}

/**
 添加定时器到监控线程
 */
-(void)addTimerToMonitorThread{
    if (_timer) {
        return;
    }
    // 创建一个timer
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopTimerContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
    _timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, _interval, 0, 0,
                                  &runLoopTimerCallBack, &context);
    // 添加到子线程的RunLoop中
    CFRunLoopAddTimer(currentRunLoop, _timer, kCFRunLoopCommonModes);
}

-(void)handleStackInfo{

    NSLog(@"---------------------------");
    NSLog(@"%@", [MQLBacktraceLogger MQL_backtraceOfMainThread]);
    NSLog(@"---------------------------");
    
    
}



















@end
