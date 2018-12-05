//
//  YNVideoChatViewController.m
//  RNNeteaseIm
//
//  Created by cookiej on 2018/11/26.
//  Copyright © 2018 Dowin. All rights reserved.
//

#import "YNVideoChatViewController.h"
#import "UIView+Toast.h"
#import "NTESTimerHolder.h"
#import "NTESNetCallChatInfo.h"
#import "NTESSessionUtil.h"
#import "NTESVideoChatNetStatusView.h"
#import "NTESBundleSetting.h"
#import "NTESRecordSelectView.h"
#import "UIView+NTES.h"
#import "YNAudioChatViewController.h"
#import "NTESGLView.h"

#define NTESUseGLView
#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height

@interface YNVideoChatViewController ()
@property (nonatomic,assign) NIMNetCallCamera cameraType;

@property (nonatomic,strong) CALayer *localVideoLayer;

@property (nonatomic,assign) BOOL oppositeCloseVideo;

#if defined (NTESUseGLView)
@property (nonatomic, strong) NTESGLView *remoteGLView;
#endif

@property (nonatomic,weak) UIView   *localView;

@property (nonatomic,weak) UIView   *localPreView;


@property (nonatomic, assign) BOOL calleeBasy;

@end

@implementation YNVideoChatViewController

- (instancetype)initWithCallInfo:(NTESNetCallChatInfo *)callInfo
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.callInfo = callInfo;
        self.callInfo.isMute = NO;
        self.callInfo.useSpeaker = NO;
        self.callInfo.disableCammera = NO;
        if (!self.localPreView) {
            //没有的话，尝试去取一把预览层（从视频切到语音再切回来的情况下是会有的）
            self.localPreView = [NIMAVChatSDK sharedSDK].netCallManager.localPreview;
        }
        [[NIMAVChatSDK sharedSDK].netCallManager switchType:NIMNetCallMediaTypeVideo];
    }
    return self;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeVideo;
        _cameraType = [[NTESBundleSetting sharedConfig] startWithBackCamera] ? NIMNetCallCameraBack :NIMNetCallCameraFront;
    }
    return self;
}

- (void)viewDidLoad {
    self.localView = self.smallVideoView;
    [super viewDidLoad];
    
    if (self.localPreView) {
        self.localPreView.frame = self.localView.bounds;
        [self.localView addSubview:self.localPreView];
    }
    [self addSubviews];
    [self initUI];
}

- (void)addSubviews {
    UIImageView *bgImage = [[UIImageView alloc] init];
    bgImage.image = [UIImage imageNamed:@"netcall_bkg"];
    bgImage.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    _bigVideoView = bgImage;
    [self.view addSubview:bgImage];
    
    [self.view addSubview:self.smallVideoView];
    [self.view addSubview:self.hungUpBtn];
    [self.view addSubview:self.acceptBtn];
    [self.view addSubview:self.durationLabel];
    [self.view addSubview:self.muteBtn];
    [self.view addSubview:self.switchCameraBtn];
    [self.view addSubview:self.connectingLabel];
    [self.view addSubview:self.localRecordBtn];
    [self.view addSubview:self.disableCameraBtn];
    [self.view addSubview:self.switchModelBtn];
    [self.view addSubview:self.refuseBtn];
    [self.view addSubview:self.localRecordingView];
    [self.view addSubview:self.lowMemoryView];
    [self.view addSubview:self.netStatusView];
    [self.localRecordingView addSubview:self.localRecordingRedPoint];
    [self.lowMemoryView addSubview:self.lowMemoryRedPoint];
}

- (void)initUI
{
    self.localRecordingView.layer.cornerRadius = 10.0;
    self.localRecordingRedPoint.layer.cornerRadius = 4.0;
    self.lowMemoryView.layer.cornerRadius = 10.0;
    self.lowMemoryRedPoint.layer.cornerRadius = 4.0;
    self.refuseBtn.exclusiveTouch = YES;
    self.acceptBtn.exclusiveTouch = YES;
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self initRemoteGLView];
    }
}

- (void)initRemoteGLView {
#if defined (NTESUseGLView)
    _remoteGLView = [[NTESGLView alloc] initWithFrame:_bigVideoView.bounds];
    [_remoteGLView setContentMode:[[NTESBundleSetting sharedConfig] videochatRemoteVideoContentMode]];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_bigVideoView addSubview:_remoteGLView];
#endif
}


#pragma mark - Call Life
- (void)startByCaller{
    [super startByCaller];
    [self startInterface];
}

- (void)startByCallee{
    [super startByCallee];
    [self waitToCallInterface];
}
- (void)onCalling{
    [super onCalling];
    [self videoCallingInterface];
}

- (void)waitForConnectiong{
    [super waitForConnectiong];
    [self connectingInterface];
}

- (void)onCalleeBusy
{
    _calleeBasy = YES;
    if (_localPreView)
    {
        [_localPreView removeFromSuperview];
    }
}

#pragma mark - Interface
//正在接听中界面
- (void)startInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在呼叫，请稍候...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = NO;
    self.muteBtn.hidden = NO;
    self.disableCameraBtn.hidden = NO;
    self.localRecordBtn.hidden = NO;
    self.muteBtn.enabled = NO;
    self.disableCameraBtn.enabled = NO;
    self.localRecordBtn.enabled = NO;
    
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hungUpCall) forControlEvents:UIControlEventTouchUpInside];
    self.localView = self.bigVideoView;
}

//选择是否接听界面
- (void)waitToCallInterface{
    self.acceptBtn.hidden = NO;
    self.refuseBtn.hidden   = NO;
    self.hungUpBtn.hidden   = YES;
    NSString *nick = [NTESSessionUtil showNick:self.callInfo.caller inSession:nil];
    self.connectingLabel.text = [nick stringByAppendingString:@"的来电"];
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.switchModelBtn.hidden = YES;
}

//连接对方界面
- (void)connectingInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在连接对方...请稍后...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hungUpCall) forControlEvents:UIControlEventTouchUpInside];
}

//接听中界面(视频)
- (void)videoCallingInterface{
    
    NIMNetCallNetStatus status = [[NIMAVChatSDK sharedSDK].netCallManager netStatus:self.peerUid];
    [self.netStatusView refreshWithNetState:status];
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = YES;
    self.muteBtn.hidden = NO;
    self.switchCameraBtn.hidden = NO;
    self.disableCameraBtn.hidden = NO;
    self.localRecordBtn.hidden = NO;
    self.switchModelBtn.hidden = NO;
    
    self.muteBtn.enabled = YES;
    self.disableCameraBtn.enabled = YES;
    self.localRecordBtn.enabled = YES;
    
    self.muteBtn.selected = self.callInfo.isMute;
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    self.localRecordBtn.selected = ![self allRecordsStopped];
    ;
    self.localRecordingView.hidden = [self allRecordsStopped];
    ;
    self.lowMemoryView.hidden = YES;
    [self.switchModelBtn setTitle:@"语音模式" forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hungUpCall) forControlEvents:UIControlEventTouchUpInside];
    //    self.localVideoLayer.hidden = NO;
    self.localPreView.hidden = NO;
}

//切换接听中界面(语音)
- (void)audioCallingInterface{
    UIViewController *rootVC = RCTPresentedViewController();
    
    YNAudioChatViewController *vc = [[YNAudioChatViewController alloc] initWithCallInfo:self.callInfo];
    //    [rootVC dismissViewControllerAnimated:NO completion:^{
    [rootVC presentViewController:vc animated:NO completion:nil];
    //    }];
    //    [UIView  beginAnimations:nil context:NULL];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    //    [UIView setAnimationDuration:0.75];
    //    [self.navigationController pushViewController:vc animated:NO];
    //    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    //    [UIView commitAnimations];
    //    NSMutableArray * vcs = [self.navigationController.viewControllers mutableCopy];
    //    [vcs removeObject:self];
    //    self.navigationController.viewControllers = vcs;
}

- (void)udpateLowSpaceWarning:(BOOL)show {
    self.lowMemoryView.hidden = !show;
    self.localRecordingView.hidden = show;
}


#pragma mark - IBAction

- (void)acceptToCall {
    //防止用户在点了接收后又点拒绝的情况
    [self response:YES];
}

- (void)refuseCall {
    [self response:NO];
}

- (void)mute:(BOOL)sender{
    self.callInfo.isMute = !self.callInfo.isMute;
    self.player.volume = !self.callInfo.isMute;
    [[NIMAVChatSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
    self.muteBtn.selected = self.callInfo.isMute;
}

- (void)switchCamera:(id)sender{
    if (self.cameraType == NIMNetCallCameraFront) {
        self.cameraType = NIMNetCallCameraBack;
    }else{
        self.cameraType = NIMNetCallCameraFront;
    }
    [[NIMAVChatSDK sharedSDK].netCallManager switchCamera:self.cameraType];
    self.switchCameraBtn.selected = (self.cameraType == NIMNetCallCameraBack);
}


- (void)disableCammera:(id)sender{
    self.callInfo.disableCammera = !self.callInfo.disableCammera;
    [[NIMAVChatSDK sharedSDK].netCallManager setCameraDisable:self.callInfo.disableCammera];
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    if (self.callInfo.disableCammera) {
        [self.localPreView removeFromSuperview];
        [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeCloseVideo];
    }else{
        [self.localView addSubview:self.localPreView];
        
        [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeOpenVideo];
    }
}

- (void)localRecord:(id)sender {
    //出现录制选择框
    if ([self allRecordsStopped]) {
        [self showRecordSelectView:YES];
    }
    //同时停止所有录制
    else
    {
        //结束语音对话
        if (self.callInfo.audioConversation) {
            [self stopAudioRecording];
            if([self allRecordsStopped])
            {
                self.localRecordBtn.selected = NO;
                self.localRecordingView.hidden = YES;
                self.lowMemoryView.hidden = YES;
            }
        }
        [self stopRecordTaskWithVideo:YES];
    }
    
}


- (void)switchCallingModel:(id)sender{
    [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeToAudio];
    [self switchToAudio];
}

- (void)hungUpCall {
    [self hangup];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        [window.rootViewController.view makeToast:@"通话结束" duration:2 position:CSToastPositionCenter];
    });
}

#pragma mark - NTESRecordSelectViewDelegate

-(void)onRecordWithAudioConversation:(BOOL)audioConversationOn myMedia:(BOOL)myMediaOn otherSideMedia:(BOOL)otherSideMediaOn
{
    if (audioConversationOn) {
        //开始语音对话
        if ([self startAudioRecording]) {
            self.callInfo.audioConversation = YES;
            self.localRecordBtn.selected = YES;
            self.localRecordingView.hidden = NO;
            self.lowMemoryView.hidden = YES;
        }
    }
    [self recordWithAudioConversation:audioConversationOn myMedia:myMediaOn otherSideMedia:otherSideMediaOn video:YES];
}


#pragma mark - NIMNetCallManagerDelegate
- (void)onLocalDisplayviewReady:(UIView *)displayView
{
    if (_calleeBasy) {
        return;
    }
    
    if (self.localPreView) {
        [self.localPreView removeFromSuperview];
    }
    
    self.localPreView = displayView;
    displayView.frame = self.localView.bounds;
    
    [self.localView addSubview:displayView];
}

#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) && !self.oppositeCloseVideo) {
        
        if (!_remoteGLView) {
            [self initRemoteGLView];
        }
        [_remoteGLView render:yuvData width:width height:height];
    }
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    if (self.oppositeCloseVideo) {
        return;
    }
    self.bigVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.bigVideoView.image = [UIImage imageWithCGImage:image];
}
#endif

- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    [super onControl:callID from:user type:control];
    switch (control) {
        case NIMNetCallControlTypeToAudio:
            [self switchToAudio];
            break;
        case NIMNetCallControlTypeCloseVideo:
            [self resetRemoteImage];
            self.oppositeCloseVideo = YES;
            [self.view makeToast:@"对方关闭了摄像头"
                        duration:2
                        position:CSToastPositionCenter];
            break;
        case NIMNetCallControlTypeOpenVideo:
            self.oppositeCloseVideo = NO;
            [self.view makeToast:@"对方开启了摄像头"
                        duration:2
                        position:CSToastPositionCenter];
            break;
        default:
            break;
    }
}


-(void)onCallEstablished:(UInt64)callID
{
    if (self.callInfo.callID == callID) {
        [super onCallEstablished:callID];
        
        self.durationLabel.hidden = NO;
        self.durationLabel.text = self.durationDesc;
        
        if (self.localView == self.bigVideoView) {
            self.localView = self.smallVideoView;
            
            if (self.localPreView) {
                [self onLocalDisplayviewReady:self.localPreView];
            }
        } else {
            // fix 自己手动发起视频聊天时，不显示小窗口的问题
            self.localView = self.smallVideoView;
            self.localPreView = [NIMAVChatSDK sharedSDK].netCallManager.localPreview;
            if (self.localPreView) {
                [self onLocalDisplayviewReady:self.localPreView];
            }
        }
    }
}

- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
{
    if ([user isEqualToString:self.peerUid]) {
        [self.netStatusView refreshWithNetState:status];
    }
}


- (void)onRecordStarted:(UInt64)callID fileURL:(NSURL *)fileURL                          uid:(NSString *)userId
{
    [super onRecordStarted:callID fileURL:fileURL uid:userId];
    if (self.callInfo.callID == callID) {
        self.localRecordBtn.selected = YES;
        self.localRecordingView.hidden = NO;
        self.lowMemoryView.hidden = YES;
    }
}


- (void)onRecordError:(NSError *)error
               callID:(UInt64)callID
                  uid:(NSString *)userId;

{
    [super onRecordError:error callID:callID uid:userId];
    if (self.callInfo.callID == callID) {
        //判断是否全部结束
        if([self allRecordsStopped])
        {
            self.localRecordBtn.selected = NO;
            self.localRecordingView.hidden = YES;
            self.lowMemoryView.hidden = YES;
        }
    }
}

- (void) onRecordStopped:(UInt64)callID
                 fileURL:(NSURL *)fileURL
                     uid:(NSString *)userId;

{
    [super onRecordStopped:callID fileURL:fileURL uid:userId];
    if (self.callInfo.callID == callID) {
        if([self allRecordsStopped])
        {
            self.localRecordBtn.selected = NO;
            self.localRecordingView.hidden = YES;
            self.lowMemoryView.hidden = YES;
        }
    }
}

#pragma mark - M80TimerHolderDelegate

- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    [super onNTESTimerFired:holder];
    self.durationLabel.text = self.durationDesc;
}

#pragma mark - Misc
- (void)switchToAudio{
    [self audioCallingInterface];
}

- (NSString*)durationDesc{
    if (!self.callInfo.startTime) {
        return @"";
    }
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSTimeInterval duration = time - self.callInfo.startTime;
    return [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
}

- (void)resetRemoteImage{
#if defined (NTESUseGLView)
    [self.remoteGLView render:nil width:0 height:0];
#endif
    self.bigVideoView.image = [UIImage imageNamed:@"netcall_bkg.png"];
}

static inline BOOL isIPhoneX() {
    BOOL iPhoneX = NO;
    /// 先判断设备是否是iPhone/iPod
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneX;
    }
    
    if (@available(iOS 11.0, *)) {
        /// 利用safeAreaInsets.bottom > 0.0来判断是否是iPhone X。
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneX = YES;
        }
    }
    
    return iPhoneX;
}

#pragma mark - Getter
- (UIButton *)switchModelBtn {
    if (!_switchModelBtn) {
        _switchModelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _switchModelBtn.frame = CGRectMake(15, 30, 92, 34);
        [_switchModelBtn setTitle:@"切换语音" forState:UIControlStateNormal];
        [_switchModelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _switchModelBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_switchModelBtn setImage:[UIImage imageNamed:@"ic_switch_voice"] forState:UIControlStateNormal];
        [_switchModelBtn setBackgroundImage:[UIImage imageNamed:@"btn_switch_av"] forState:UIControlStateNormal];
        [_switchModelBtn addTarget:self action:@selector(switchCallingModel:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchModelBtn;
}

- (UIView *)smallVideoView {
    if (!_smallVideoView) {
        _smallVideoView = [UIView new];
        _smallVideoView.frame = CGRectMake(SCREEN_W - 79, 30, 64, 98);
        [self.view addSubview:_smallVideoView];
    }
    return _smallVideoView;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 29, SCREEN_W, 35)];
        _durationLabel.font = [UIFont systemFontOfSize:22];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _durationLabel;
}

- (UILabel *)connectingLabel {
    if (!_connectingLabel) {
        _connectingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 299, SCREEN_W, 70)];
        _connectingLabel.font = [UIFont systemFontOfSize:27];
        _connectingLabel.text = @"连接中，请稍候...";
        _connectingLabel.textColor = [UIColor whiteColor];
        _connectingLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _connectingLabel;
}

- (UIButton *)acceptBtn {
    if (!_acceptBtn) {
        _acceptBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _acceptBtn.frame = CGRectMake(SCREEN_W - 151, SCREEN_H - 114, 117, 50);
        [_acceptBtn setTitle:@"接听" forState:UIControlStateNormal];
        _acceptBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_acceptBtn setBackgroundColor: [UIColor colorWithRed:10.0/255 green:187.0/255 blue:22.0/255 alpha:1]];
        [_acceptBtn addTarget:self action:@selector(acceptToCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return _acceptBtn;
}

- (UIButton *)refuseBtn {
    if (!_refuseBtn) {
        _refuseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _refuseBtn.frame = CGRectMake(SCREEN_W - 346, SCREEN_H - 114, 117, 50);
        [_refuseBtn setTitle:@"拒绝" forState:UIControlStateNormal];
        [_refuseBtn setBackgroundColor: [UIColor colorWithRed:255.0/255 green:15.0/255 blue:32.0/255 alpha:1]];
        [_refuseBtn addTarget:self action:@selector(refuseCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refuseBtn;
}

- (NTESVideoChatNetStatusView *)netStatusView {
    if (!_netStatusView) {
        _netStatusView = [[NTESVideoChatNetStatusView alloc] init];
        _netStatusView.frame = CGRectMake((SCREEN_W - 95)/2, 80, 95, 35);
    }
    return _netStatusView;
}

- (UIButton *)switchCameraBtn {
    if (!_switchCameraBtn) {
        _switchCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _switchCameraBtn.frame = CGRectMake(0, SCREEN_H - 52 - (isIPhoneX() ? 34 : 0), SCREEN_W/5, 52);
        [_switchCameraBtn setImage:[UIImage imageNamed:@"btn_turn_normal"] forState:UIControlStateNormal];
        [_switchCameraBtn setImage:[UIImage imageNamed:@"btn_turn_disabled"] forState:UIControlStateSelected];
        [_switchCameraBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_voice_normal"] forState:UIControlStateNormal];
        [_switchCameraBtn addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}

- (UIButton *)disableCameraBtn {
    if (!_disableCameraBtn) {
        _disableCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _disableCameraBtn.frame = CGRectMake(SCREEN_W/5, SCREEN_H - 52 - (isIPhoneX() ? 34 : 0), SCREEN_W/5, 52);
        [_disableCameraBtn setImage:[UIImage imageNamed:@"btn_camera_normal"] forState:UIControlStateNormal];
        [_disableCameraBtn setImage:[UIImage imageNamed:@"btn_camera_disabled"] forState:UIControlStateSelected];
        [_disableCameraBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_voice_normal"] forState:UIControlStateNormal];
        [_disableCameraBtn addTarget:self action:@selector(disableCammera:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _disableCameraBtn;
}

- (UIButton *)muteBtn {
    if (!_muteBtn) {
        _muteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _muteBtn.frame = CGRectMake(SCREEN_W/5*2, SCREEN_H - 52 - (isIPhoneX() ? 34 : 0), SCREEN_W/5, 52);
        [_muteBtn setImage:[UIImage imageNamed:@"btn_vvoice_normal"] forState:UIControlStateNormal];
        [_muteBtn setImage:[UIImage imageNamed:@"btn_voice_disable"] forState:UIControlStateSelected];
        [_muteBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_voice_normal"] forState:UIControlStateNormal];
        [_muteBtn addTarget:self action:@selector(mute:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteBtn;
}

- (UIButton *)localRecordBtn {
    if (!_localRecordBtn) {
        _localRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _localRecordBtn.frame = CGRectMake(SCREEN_W/5*3, SCREEN_H - 52 - (isIPhoneX() ? 34 : 0), SCREEN_W/5, 52);
        [_localRecordBtn setImage:[UIImage imageNamed:@"btn_vrecord_normal"] forState:UIControlStateNormal];
        [_localRecordBtn setImage:[UIImage imageNamed:@"btn_vrecord_selected"] forState:UIControlStateSelected];
        [_localRecordBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_voice_normal"] forState:UIControlStateNormal];
        [_localRecordBtn addTarget:self action:@selector(localRecord:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _localRecordBtn;
}

- (UIButton *)hungUpBtn {
    if (!_hungUpBtn) {
        _hungUpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _hungUpBtn.frame = CGRectMake(SCREEN_W/5*4, SCREEN_H - 52 - (isIPhoneX() ? 34 : 0), SCREEN_W/5, 52);
        [_hungUpBtn setImage:[UIImage imageNamed:@"btn_vcancel_normal"] forState:UIControlStateNormal];
        [_hungUpBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_video_normal"] forState:UIControlStateNormal];
        _hungUpBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [_hungUpBtn addTarget:self action:@selector(hungUpCall) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hungUpBtn;
}

- (UIView *)localRecordingView {
    if (!_localRecordingView) {
        _localRecordingView = [[UIView alloc] init];
        _localRecordingView.frame = CGRectMake(136, 421, 104, 40);
        _localRecordingView.backgroundColor = [UIColor colorWithRed:0.0/255 green:0.0/255 blue:0.0/255 alpha:0.8];
        
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(16, 6, 72, 27);
        label.text = @"录制中";
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor whiteColor];
        [_localRecordingView addSubview:label];
    }
    return _localRecordingView;
}

- (UIView *)lowMemoryView {
    if (!_lowMemoryView) {
        _lowMemoryView = [[UIView alloc] init];
        _lowMemoryView.frame = CGRectMake(100, 396, 175, 65);
        _lowMemoryView.backgroundColor = [UIColor lightGrayColor];
        
        UILabel *lowLabel = [[UILabel alloc] init];
        lowLabel.frame = CGRectMake(4, 35, 166, 21);
        lowLabel.text = @"你的手机内存已不足10M";
        lowLabel.font = [UIFont systemFontOfSize:14];
        lowLabel.textColor = [UIColor redColor];
        [_lowMemoryView addSubview:lowLabel];
        
        UILabel *recordingLabel = [[UILabel alloc] init];
        recordingLabel.frame = CGRectMake(51, 8, 73, 27);
        recordingLabel.text = @"录制中";
        recordingLabel.font = [UIFont systemFontOfSize:16];
        recordingLabel.textColor = [UIColor whiteColor];
        [_lowMemoryView addSubview:recordingLabel];
    }
    return _lowMemoryView;
}

- (UIView *)localRecordingRedPoint {
    if (!_localRecordingRedPoint) {
        _localRecordingRedPoint = [[UIView alloc] init];
        _localRecordingRedPoint.frame = CGRectMake(81, 14, 8, 8);
        _localRecordingRedPoint.backgroundColor = [UIColor redColor];
    }
    return _localRecordingRedPoint;
}

- (UIView *)lowMemoryRedPoint {
    if (!_lowMemoryRedPoint) {
        _lowMemoryRedPoint = [[UIView alloc] init];
        _lowMemoryRedPoint.frame = CGRectMake(117, 15, 8, 8);
        _lowMemoryRedPoint.backgroundColor = [UIColor redColor];
    }
    return _lowMemoryRedPoint;
}


@end

