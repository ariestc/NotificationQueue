//
//  ViewController.m
//  NotificationQueue
//
//  Created by wangliang on 2017/12/24.
//  Copyright © 2017年 wangliang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSMachPortDelegate>

@property(nonatomic) NSMutableArray *notifications;

@property(nonatomic) NSThread *notifiThread;

@property(nonatomic) NSLock *notifiLock;

@property(nonatomic) NSMachPort *notifiPort;


@end

@implementation ViewController
#define MyNotificationName @"MyNotificationName"

-(void)notificationQueue
{
    NSLog(@"notificationQueue=%@",[NSThread currentThread]);
    
    NSDictionary *userInfo=@{
                             @"name":@"Aries",
                             @"age":@26
                             };
    NSNotification *notificate=[NSNotification notificationWithName:MyNotificationName object:nil userInfo:userInfo];
    
    
    NSNotificationQueue *notifiQueue=[NSNotificationQueue defaultQueue];
    
    NSLog(@"notifiQueue--before");
    [notifiQueue enqueueNotification:notificate postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName forModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode,UITrackingRunLoopMode, nil]];
    
    NSLog(@"notifiQueue--end");
    
    /*
     NotificationQueue[2740:373421] notifiQueue--before
     NotificationQueue[2740:373421] notifiQueue--end
     NotificationQueue[2740:373421] 我已拿到通知---NSConcreteNotification 0x60400004e8b0 {name = MyNotificationName; userInfo = {
     age = 26;
     name = Aries;
     }}

     */
    
    NSPort *port=[[NSPort alloc] init];
    
    [[NSRunLoop currentRunLoop] addPort:port forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
    NSLog(@"runLoop Over ---");
}

-(void)notificateWithRunLoop
{
    NSLog(@"notificateWithRunLoop=%@",[NSThread currentThread]);
   /*
    typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity)
    {
        kCFRunLoopEntry = (1UL << 0),
        kCFRunLoopBeforeTimers = (1UL << 1),
        kCFRunLoopBeforeSources = (1UL << 2),
        kCFRunLoopBeforeWaiting = (1UL << 5),
        kCFRunLoopAfterWaiting = (1UL << 6),
        kCFRunLoopExit = (1UL << 7),
        kCFRunLoopAllActivities = 0x0FFFFFFFU
    };

    */
   CFRunLoopObserverRef observer=CFRunLoopObserverCreateWithHandler(CFAllocatorGetDefault(),kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        
        if (activity == kCFRunLoopEntry) {
            
            NSLog(@"进入Runnloop --- ");
        }else if (activity == kCFRunLoopBeforeWaiting)
        {
            NSLog(@"进入等待状态之前 --- ");
        }else if (activity == kCFRunLoopAfterWaiting){
            NSLog(@"结束等待状态 ---");
        }
    });
    
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    CFRelease(observer);
    
    NSDictionary *userInf01=@{
                              @"name":@"jack"
                              };
    NSNotification *notif01=[NSNotification notificationWithName:MyNotificationName object:nil userInfo:userInf01];
    
    NSDictionary *userInf02=@{
                              @"name":@"sam"
                              };
    NSNotification *notif02=[NSNotification notificationWithName:MyNotificationName object:nil userInfo:userInf02];
    
    NSDictionary *userInf03=@{
                              @"name":@"dog"
                              };
    NSNotification *notif03=[NSNotification notificationWithName:MyNotificationName object:nil userInfo:userInf03];
    
  NSNotificationQueue *notifQueue= [NSNotificationQueue defaultQueue];
    
    [notifQueue enqueueNotification:notif01 postingStyle:NSPostWhenIdle coalesceMask:NSNotificationNoCoalescing forModes:@[NSDefaultRunLoopMode]];
    
     [notifQueue enqueueNotification:notif02 postingStyle:NSPostNow coalesceMask:NSNotificationNoCoalescing forModes:@[NSDefaultRunLoopMode]];
    
     [notifQueue enqueueNotification:notif03 postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:@[NSDefaultRunLoopMode]];
    
    
    NSPort *port=[[NSPort alloc] init];
    [[NSRunLoop currentRunLoop] addPort:port forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
    NSLog(@"notificateWithRunLoop Over");
    
    //NSPostNow立即执行未进入runloop
    //NSPostASAP通知快于NSPostWhenIdle通知进入runloop
    /*
     
     NotificationQueue[3433:496565] 我已拿到通知---NSConcreteNotification 0x60400025ca70 {name = MyNotificationName; userInfo = {
     name = sam;
     }}
     NotificationQueue[3433:496565] 进入Runnloop ---
     NotificationQueue[3433:496565] 我已拿到通知---NSConcreteNotification 0x60400025fb60 {name = MyNotificationName; userInfo = {
     name = dog;
     }}
     NotificationQueue[3433:496565] 进入Runnloop ---
     NotificationQueue[3433:496565] 进入Runnloop ---
     NotificationQueue[3433:496565] 进入Runnloop ---
     NotificationQueue[3433:496565] 进入等待状态之前 ---
     NotificationQueue[3433:496565] 我已拿到通知---NSConcreteNotification 0x60400025e1e0 {name = MyNotificationName; userInfo = {
     name = jack;
     }}
     NotificationQueue[3433:496565] 结束等待状态 ---
     NotificationQueue[3433:496565] 进入等待状态之前 ---
     NotificationQueue[3433:496565] 结束等待状态 ---
     NotificationQueue[3433:496565] 进入Runnloop ---
     NotificationQueue[3433:496565] 进入等待状态之前 ---
     NotificationQueue[3433:496565] 结束等待状态 ---
     */
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor=[UIColor redColor];
    
    [self setupThreadingSupport];
    
    [self registerObserver];
   
}


-(void)setupThreadingSupport
{
    if (self.notifications) {

        return;
    }
    
    //初始化
    self.notifications=[[NSMutableArray alloc] init];
    self.notifiLock=[[NSLock alloc] init];
    self.notifiThread=[NSThread currentThread];
    self.notifiPort=[[NSMachPort alloc] init];
    
    self.notifiPort.delegate=self;
    
    [[NSRunLoop currentRunLoop] addPort:self.notifiPort forMode:(__bridge NSString *)kCFRunLoopCommonModes];
}

#pragma mark -- NSMachPortDelegate
-(void)handleMachMessage:(void *)msg
{
    [self.notifiLock lock];
    
    while (self.notifications.count) {
        
        NSNotification *notification=[self.notifications objectAtIndex:0];
        [self.notifications removeObjectAtIndex:0];
        [self.notifiLock unlock];
        
        [self processNotification:notification];
        [self.notifiLock lock];
    }
    
    [self.notifiLock unlock];
}

-(void)processNotification:(NSNotification *)notificate
{
    if ([NSThread currentThread] != _notifiThread) {
        
        [self.notifiLock lock];
        [self.notifications addObject:notificate];
        [self.notifiLock unlock];
        
       // 线程间通信: 基于端口的输入源(基于端口的通信)
        [self.notifiPort sendBeforeDate:[NSDate date] components:nil from:nil reserved:0];
        
    }else
    {
        NSLog(@"processNotification=%@",[NSThread currentThread]);
        NSLog(@"我已拿到通知---%@",notificate);
        
        /*
         processNotification=<NSThread: 0x60000006bc00>{number = 1, name = main}
         2017-12-24 14:30:05.914930+0800 NotificationQueue[4189:634353] 我已拿到通知---NSConcreteNotification 0x604000443000 {name = MyNotificationName; userInfo = {
         age = 26;
         name = Aries;
         }}
         */
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //异步通知
//    [self notificationQueue];
    
    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        
        [self notificationQueue];
        //notificationQueue=<NSThread: 0x604000466700>{number = 3, name = (null)}
        //handelNotificate=<NSThread: 0x604000466700>{number = 3, name = (null)}
    });

    //同步通知
    //    [self syncPostNotificate];
    
//    [self notificateWithRunLoop];
}

-(void)registerObserver
{
//     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handelNotificate:) name:MyNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:MyNotificationName object:nil];
}

-(void)handelNotificate:(NSNotification *)notificate
{
    NSLog(@"handelNotificate=%@",[NSThread currentThread]);
    NSLog(@"我已拿到通知---%@",notificate);
}



-(void)syncPostNotificate
{
    NSDictionary *userInfo=@{
                             @"name":@"tom",
                             @"height":@18
                             };
    NSLog(@"syncPostNotificate--begin");
    [[NSNotificationCenter defaultCenter] postNotificationName:MyNotificationName object:nil userInfo:userInfo];
    NSLog(@"syncPostNotificate--end");
    
    /*
     NotificationQueue[2695:368630] syncPostNotificate--begin
     NotificationQueue[2695:368630] 我已拿到通知---NSConcreteNotification 0x60400025e5d0 {name = MyNotificationName; userInfo = {
     height = 18;
     name = tom;
     }}
     NotificationQueue[2695:368630] syncPostNotificate--end
     */
}

@end
