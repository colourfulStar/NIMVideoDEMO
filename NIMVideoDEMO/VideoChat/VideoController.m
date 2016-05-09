//
//  VideoController.m
//  NIMVideoDEMO
//
//  Created by 张茜倩 on 16/5/3.
//  Copyright © 2016年 Xiqian Zhang. All rights reserved.
//

#import "VideoController.h"
#import <AVFoundation/AVFoundation.h>
#import "GLView.h"

@interface VideoController ()<NIMNetCallManagerDelegate>

@property (nonatomic,strong) NSMutableArray *chatRoom;

@property(nonatomic,strong)UIImageView *remoteView;//对方的视屏窗口

@property (nonatomic,strong) UIView *localView;//本地自己的窗口

@property (nonatomic,strong) CALayer *localVideoLayer;

@end

@implementation VideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置视屏屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //创建UI
    [self createUI];
    
    [[NIMSDK sharedSDK].netCallManager addDelegate:self];
    
    //callInfo初始化赋值
    self.callInfo = [[NetCallChatInfo alloc] init];
    NSString *currentCaller = [[NIMSDK sharedSDK].loginManager currentAccount];
    self.callInfo.caller = currentCaller;
    self.callInfo.callee = kAccount2;
}


- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallType)type message:(NSString *)extendMessage{
    
    self.callInfo.callID = callID;
    
    if ([NIMSDK sharedSDK].netCallManager.currentCallID > 0)
    {
        [[NIMSDK sharedSDK].netCallManager control:callID type:NIMNetCallControlTypeBusyLine];
        return;
    };
    switch (type)
    {
        case NIMNetCallTypeVideo:
        {
            //检查设备可用性，进行视频
            __weak typeof(self) wself = self;
            [self checkServiceEnable:^(BOOL result) {
                if (result) {
                    [wself afterCheckService];
                }else{
                    [wself dismiss:nil];
                }
            }];
        }    
    }
}


- (void)afterCheckService{
    if (self.callInfo.isStart)
    {
        [self onCalling];
    }
    else if (self.callInfo.callID)
    {
        [self alerttWithTitle:@"请接收视频"];
        [self startByCallee];
    }
    else
    {

    }
}

#pragma mark - alert
-(void)alerttWithTitle:(NSString *)tipsTitle
{
    UIAlertController *alertViewCtrl = [UIAlertController
                                        alertControllerWithTitle:tipsTitle
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self response:YES];
    }];
    
    [alertViewCtrl addAction:action2];
    [self presentViewController:alertViewCtrl animated:YES completion:NULL];
}


- (void)onCalling
{
    
}

- (void)startByCallee{
    self.callInfo.isStart = YES;
    
    NSMutableArray *room = [[NSMutableArray alloc] init];
    [room addObject:self.callInfo.caller];
    self.chatRoom = room;
    
    [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeFeedabck];
}

- (void)startByCaller{
    __weak typeof(self) wself = self;
    if (!wself)
    {
        return;
    }
    wself.callInfo.isStart = YES;
    
    //默认是kAccount1发送视频请求到kAccount2。在此处更改
    NSString *callee = kAccount2;
    NSArray *callees = @[callee];
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    option.apnsContent = [NSString stringWithFormat:@"%@请求", wself.callInfo.callType == NIMNetCallTypeAudio ? @"网络通话" : @"视频聊天"];
    option.extendMessage = @"音视频请求扩展信息";
    option.preferredVideoQuality = NIMNetCallVideoQualityLow;
    
    [[NIMSDK sharedSDK].netCallManager start:callees type:wself.callInfo.callType option:option completion:^(NSError *error, UInt64 callID) {
        if (!error && wself) {
            //发起成功，给一个callID
            wself.callInfo.callID = callID;
            wself.chatRoom = [[NSMutableArray alloc]init];
  
            //十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入聊天室
            NSTimeInterval delayTime = 10;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself onControl:callID from:wself.callInfo.callee type:NIMNetCallControlTypeFeedabck];
            });
            
        }else{
            if (error) {
                NSLog(@"%@",error);
                
            }else{
                //说明在start的过程中把页面关了
                [[NIMSDK sharedSDK].netCallManager hangup:callID];
                [wself dismiss:nil];
            }
        }
    }];
}

- (void)dismiss:(void (^)(void))completion{
    //只要页面消失，就挂断
    if (self.callInfo.callID != 0) {
        [[NIMSDK sharedSDK].netCallManager hangup:self.callInfo.callID];
        
        self.chatRoom = nil;
    }
}

- (void)response:(BOOL)accept{
    __weak typeof(self) wself = self;
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    
    [[NIMSDK sharedSDK].netCallManager response:self.callInfo.callID accept:accept option:option completion:^(NSError *error, UInt64 callID) {
        if (!error) {
            [wself onCalling];
            [wself.chatRoom addObject:wself.callInfo.callee];
            NSTimeInterval delay = 10.f; //10秒后判断下聊天室
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (wself.chatRoom.count == 1) {
                   
                    [wself dismiss:nil];
                }
            });
        }else{
            wself.chatRoom = nil;
            [wself dismiss:nil];
        }
    }];
    //dismiss需要放在self后面，否在ios7下会有野指针
    if (accept) {

    }else{
        [self dismiss:nil];
    }
}


#pragma mark - UI
-(void)createUI
{
    //对方视屏窗口
    self.remoteView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, KScreenWidth, kScreenHeight)];
    self.remoteView.backgroundColor = [UIColor blackColor];
    self.remoteView.userInteractionEnabled = YES;
    
    //本地自己窗口
    self.localView = [[UIView alloc]initWithFrame:CGRectMake(KScreenWidth*.6, 20, KScreenWidth*.32, 100)];
    self.localView.backgroundColor = [UIColor grayColor];
    self.localView.layer.borderWidth = 1;
    self.localView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.remoteView addSubview:self.localView];
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 100, 30)];
    [btn setTitle:@"开始视频" forState:UIControlStateNormal];
    btn.titleLabel.textColor = [UIColor blackColor];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor orangeColor];
    [self.remoteView addSubview:btn];

    [self.view addSubview:self.remoteView];
}

-(void)btnAction:(id)sender
{
    [self startByCaller];
}

#pragma mark - NIMNetCallManagerDelegate
- (void)setLocalVideoLayer:(CALayer *)localVideoLayer{
    if (_localVideoLayer != localVideoLayer) {
        _localVideoLayer = localVideoLayer;
    }
}

- (void)onLocalPreviewReady:(CALayer *)layer{
    if (self.localVideoLayer) {
        [self.localVideoLayer removeFromSuperlayer];
    }
    self.localVideoLayer = layer;
    layer.frame = self.localView.bounds;
    [self.localView.layer addSublayer:layer];
}



#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
{
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) && !self.oppositeCloseVideo) {
        
        if (!_remoteGLView) {
            [self initRemoteGLView];
        }
        [_remoteGLView render:yuvData width:width height:height];
        
        //把本地view设置在对方的view之上
        [self.remoteGLView addSubview:self.localView];
        [self.remoteGLView addSubview:dismissBtn];
    }
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    
    self.remoteView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteView.image = [UIImage imageWithCGImage:image];
}
#endif


- (void)initRemoteGLView {
#if defined (NTESUseGLView)
    _remoteGLView = [[GLView alloc] initWithFrame:_remoteView.bounds];
    
    [_remoteGLView setContentMode:UIViewContentModeCenter];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_remoteView addSubview:_remoteGLView];
    
#endif
}



#pragma mark - NIMNetCallManagerDelegate
- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    switch (control) {
        case NIMNetCallControlTypeFeedabck:{
            NSMutableArray *room = self.chatRoom;
            if (room && !room.count) {
                
                if (!self.callInfo.caller) {
                    return;
                }
                [room addObject:self.callInfo.caller];
                
                //40秒之后查看一下聊天室状态，如果聊天室还在一个人的话，就播放铃声超时
                __weak typeof(self) wself = self;
                uint64_t callId = self.callInfo.callID;
                NSTimeInterval delayTime = 30;//超时时间
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSMutableArray *room = wself.chatRoom;
                    if (wself && room && room.count == 1)
                    {
                        //如果超时后，也没有响应，房间存在，就挂断本次通话callID
                        [[NIMSDK sharedSDK].netCallManager hangup:callId];
                        wself.chatRoom = nil;
                        [self dismiss:nil];
                    }
                });
            }
            break;
        }
            
        case NIMNetCallControlTypeBusyLine:
            NSLog(@"占线");
        
            break;
        default:
            break;
    }
}

- (void)onResponse:(UInt64)callID from:(NSString *)callee accepted:(BOOL)accepted{
    
    if (self.callInfo.callID == callID) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!accepted) {
                self.chatRoom = nil;
                [self dismiss:nil];
            }else{
                [self onCalling];
                [self.chatRoom addObject:callee];
            }
        });
        
    }
}


#pragma mark - Misc
//检查设备可用性
- (void)checkServiceEnable:(void(^)(BOOL))result{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async_main_safe(^{
                if (granted) {
                    NSString *mediaType = AVMediaTypeVideo;
                    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:@"相机权限受限,无法视频聊天"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                        [alert show];
                        
                    }else{
                        //成功，相机麦克风都可用
                        if (result) {
                            result(YES);
                        }
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"麦克风权限受限,无法聊天"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
                
            });
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
