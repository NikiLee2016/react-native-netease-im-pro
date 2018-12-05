//
//  YNAudioChatViewController.m
//  RNNeteaseIm
//
//  Created by cookiej on 2018/11/26.
//  Copyright © 2018 Dowin. All rights reserved.
//

#import "YNAudioChatViewController.h"
#import "NTESTimerHolder.h"
#import "NTESNetCallChatInfo.h"
#import "NTESSessionUtil.h"
#import "UIView+Toast.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESVideoChatNetStatusView.h"
#import "NTESRecordSelectView.h"
#import "UIView+NTES.h"
#import "YNVideoChatViewController.h"

#define SCREEN_W [UIScreen mainScreen].bounds.size.width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height

@interface YNAudioChatViewController ()

@end

@implementation YNAudioChatViewController

- (instancetype)initWithCallInfo:(NTESNetCallChatInfo *)callInfo{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.callInfo = callInfo;
        self.callInfo.isMute = NO;
        self.callInfo.disableCammera = NO;
        self.callInfo.useSpeaker = NO;
        [[NIMAVChatSDK sharedSDK].netCallManager switchType:NIMNetCallMediaTypeAudio];
        
        
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeAudio;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addSubviews];
    [self initUI];
}

- (void)initUI {
    self.localRecordingView.layer.cornerRadius = 10.0;
    self.localRecordingRedPoint.layer.cornerRadius = 4.0;
    self.lowMemoryView.layer.cornerRadius = 10.0;
    self.lowMemoryRedPoint.layer.cornerRadius = 4.0;
    self.refuseBtn.exclusiveTouch = YES;
    self.acceptBtn.exclusiveTouch = YES;
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
    [self audioCallingInterface];
}

- (void)waitForConnectiong{
    [super onCalling];
    [self connectingInterface];
}

#pragma mark - Interface
//正在接听中界面
- (void)startInterface{
    self.hangUpBtn.hidden  = NO;
    self.muteBtn.hidden    = YES;
    self.speakerBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.durationLabel.hidden   = YES;
    self.switchVideoBtn.hidden  = YES;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text   = @"正在呼叫，请稍候...";
    self.refuseBtn.hidden = YES;
    self.acceptBtn.hidden = YES;
}

//选择是否接听界面
- (void)waitToCallInterface{
    self.hangUpBtn.hidden  = YES;
    self.muteBtn.hidden    = YES;
    self.speakerBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.durationLabel.hidden   = YES;
    self.switchVideoBtn.hidden  = YES;
    self.connectingLabel.hidden = NO;
    NSString *nick = [NTESSessionUtil showNick:self.callInfo.caller inSession:nil];
    self.connectingLabel.text = [nick stringByAppendingString:@"的来电"];
    self.refuseBtn.hidden = NO;
    self.acceptBtn.hidden = NO;
}

//连接对方界面
- (void)connectingInterface{
    self.hangUpBtn.hidden  = NO;
    self.muteBtn.hidden    = YES;
    self.speakerBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.durationLabel.hidden   = YES;
    self.switchVideoBtn.hidden  = YES;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text   = @"正在连接对方...请稍后...";
    self.refuseBtn.hidden = YES;
    self.acceptBtn.hidden = YES;
}

//接听中界面(音频)
- (void)audioCallingInterface{
    
    NSString *peerUid = ([self.callInfo.caller isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) ? self.callInfo.callee : self.callInfo.caller;
    
    NIMNetCallNetStatus status = [[NIMAVChatSDK sharedSDK].netCallManager netStatus:peerUid];
    [self.netStatusView refreshWithNetState:status];
    self.hangUpBtn.hidden  = NO;
    self.muteBtn.hidden    = NO;
    self.localRecordBtn.hidden = NO;
    self.speakerBtn.hidden = NO;
    self.durationLabel.hidden   = NO;
    self.switchVideoBtn.hidden  = NO;
    self.connectingLabel.hidden = YES;
    self.refuseBtn.hidden = YES;
    self.acceptBtn.hidden = YES;
    self.muteBtn.selected    = self.callInfo.isMute;
    self.speakerBtn.selected = self.callInfo.useSpeaker;
    self.localRecordBtn.selected =![self allRecordsStopped];
    self.localRecordingView.hidden = [self allRecordsStopped];
    self.lowMemoryView.hidden = YES;
}

//切换接听中界面(视频)
- (void)videoCallingInterface{
//    NTESVideoChatViewController *vc = [[NTESVideoChatViewController alloc] initWithCallInfo:self.callInfo];
//        [UIView  beginAnimations:nil context:NULL];
//        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//        [UIView setAnimationDuration:0.75];
//    [self.navigationController pushViewController:vc animated:NO];
//        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
//        [UIView commitAnimations];
//    NSMutableArray * vcs = [self.navigationController.viewControllers mutableCopy];
//    [vcs removeObject:self];
//    self.navigationController.viewControllers = vcs;
    // 暴力解决，无转场动画
    UIViewController *rootVC = RCTPresentedViewController();
    YNVideoChatViewController *vc = [[YNVideoChatViewController alloc] initWithCallInfo:self.callInfo];
    [rootVC presentViewController:vc animated:NO completion:nil];
}

- (void)udpateLowSpaceWarning:(BOOL)show {
    self.lowMemoryView.hidden = !show;
    self.localRecordingView.hidden = show;
}


#pragma mark - IBAction
- (void)hangup:(id)sender{
    [self hangup];
}

- (void)acceptToCall {
    [self response:YES];
}

- (void)refuseCall {
    [self response:NO];
}

- (void)mute:(id)sender{
    self.callInfo.isMute  = !self.callInfo.isMute;
    self.muteBtn.selected = self.callInfo.isMute;
    [[NIMAVChatSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
}

- (void)userSpeaker:(id)sender{
    self.callInfo.useSpeaker = !self.callInfo.useSpeaker;
    self.speakerBtn.selected = self.callInfo.useSpeaker;
    [[NIMAVChatSDK sharedSDK].netCallManager setSpeaker:self.callInfo.useSpeaker];
}

- (void)switchToVideoMode:(id)sender {
    [self.view makeToast:@"已发送转换请求，请等待对方应答..."
                duration:2
                position:CSToastPositionCenter];
    [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeToVideo];
}

- (void)localRecord:(id)sender {
    //出现录制选择框
    if ([self allRecordsStopped]) {
        [self showRecordSelectView:NO];
    }
    //同时停止所有录制
    else
    {
        if (self.callInfo.audioConversation) {
            [self stopAudioRecording];
            if([self allRecordsStopped])
            {
                self.localRecordBtn.selected = NO;
                self.localRecordingView.hidden = YES;
                self.lowMemoryView.hidden = YES;
            }
        }
        [self stopRecordTaskWithVideo:NO];
    }
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
    [self recordWithAudioConversation:audioConversationOn myMedia:myMediaOn otherSideMedia:otherSideMediaOn video:NO];
}

#pragma mark - NIMNetCallManagerDelegate

- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    [super onControl:callID from:user type:control];
    switch (control) {
        case NIMNetCallControlTypeToVideo:
            [self onResponseVideoMode];
            break;
        case NIMNetCallControlTypeAgreeToVideo:
            [self videoCallingInterface];
            break;
        case NIMNetCallControlTypeRejectToVideo:
            [self.view makeToast:@"对方拒绝切换到视频模式"
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
    }
}


- (void)onNetStatus:(NIMNetCallNetStatus)status user:(NSString *)user
{
    if ([user isEqualToString:self.peerUid]) {
        [self.netStatusView refreshWithNetState:status];
    }
}

- (void)onRecordStarted:(UInt64)callID fileURL:(NSURL *)fileURL                          uid:(NSString *)userId;
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
    if (self.callInfo.callID == callID && !self.callInfo.localRecording&&!self.callInfo.otherSideRecording) {
        self.localRecordBtn.selected = NO;
        self.localRecordingView.hidden = YES;
        self.lowMemoryView.hidden = YES;
    }
}

- (void)onRecordStopped:(UInt64)callID
                fileURL:(NSURL *)fileURL
                    uid:(NSString *)userId;
{
    [super onRecordStopped:callID fileURL:fileURL uid:userId];
    if (self.callInfo.callID == callID&&!self.callInfo.localRecording&& !self.callInfo.otherSideRecording) {
        self.localRecordBtn.selected = NO;
        self.localRecordingView.hidden = YES;
        self.lowMemoryView.hidden = YES;
    }
}


#pragma mark - M80TimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder{
    [super onNTESTimerFired:holder];
    self.durationLabel.text = self.durationDesc;
}

#pragma mark -  Misc
- (NSString*)durationDesc{
    if (!self.callInfo.startTime) {
        return @"";
    }
    NSTimeInterval time = [NSDate date].timeIntervalSince1970;
    NSTimeInterval duration = time - self.callInfo.startTime;
    return [NSString stringWithFormat:@"%02d:%02d",(int)duration/60,(int)duration%60];
}


- (void)onResponseVideoMode{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"对方请求切换为视频模式" delegate:nil cancelButtonTitle:@"拒绝" otherButtonTitles:@"接受", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger idx) {
        switch (idx) {
            case 0:
                [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeRejectToVideo];
                [self.view makeToast:@"已拒绝"
                            duration:2
                            position:CSToastPositionCenter];
                break;
            case 1:
                [[NIMAVChatSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeAgreeToVideo];
                [self videoCallingInterface];
                break;
            default:
                break;
        }
    }];
}

- (void)addSubviews {
    UIImageView *bgImage = [[UIImageView alloc] init];
    bgImage.image = [UIImage imageNamed:@"netcall_bkg"];
    bgImage.frame = CGRectMake(0, 0, SCREEN_W, SCREEN_H);
    [self.view addSubview:bgImage];
    
    [self.view addSubview:self.switchVideoBtn];
    [self.view addSubview:self.muteBtn];
    [self.view addSubview:self.hangUpBtn];
    [self.view addSubview:self.durationLabel];
    [self.view addSubview:self.speakerBtn];
    [self.view addSubview:self.connectingLabel];
    [self.view addSubview:self.acceptBtn];
    [self.view addSubview:self.refuseBtn];
    [self.view addSubview:self.netStatusView];
    [self.view addSubview:self.localRecordBtn];
    [self.view addSubview:self.localRecordingView];
    [self.view addSubview:self.lowMemoryView];
    [self.localRecordingView addSubview:self.localRecordingRedPoint];
    [self.lowMemoryView addSubview:self.lowMemoryRedPoint];
}

#pragma mark - Getter
- (UIButton *)switchVideoBtn {
    if (!_switchVideoBtn) {
        _switchVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _switchVideoBtn.frame = CGRectMake(15, 30, 92, 34);
        [_switchVideoBtn setTitle:@"视频模式" forState:UIControlStateNormal];
        [_switchVideoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _switchVideoBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_switchVideoBtn setImage:[UIImage imageNamed:@"ic_switch_video"] forState:UIControlStateNormal];
        [_switchVideoBtn setBackgroundImage:[UIImage imageNamed:@"btn_switch_av"] forState:UIControlStateNormal];
        [_switchVideoBtn addTarget:self action:@selector(switchToVideoMode:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchVideoBtn;
}

- (UIButton *)muteBtn {
    if (!_muteBtn) {
        _muteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _muteBtn.frame = CGRectMake((SCREEN_W - 268)/2, SCREEN_H - 188, 50, 50);
        [_muteBtn setImage:[UIImage imageNamed:@"btn_mute_normal"] forState:UIControlStateNormal];
        [_muteBtn setImage:[UIImage imageNamed:@"btn_mute_pressed"] forState:UIControlStateSelected];
        [_muteBtn addTarget:self action:@selector(mute:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteBtn;
}

- (UIButton *)hangUpBtn {
    if (!_hangUpBtn) {
        _hangUpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_hangUpBtn setTitle:@"挂断" forState:UIControlStateNormal];
        [_hangUpBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _hangUpBtn.frame = CGRectMake((SCREEN_W - 268)/2, SCREEN_H - 80, 268, 45);
        [_hangUpBtn setBackgroundImage:[UIImage imageNamed:@"btn_bg_video_normal"] forState:UIControlStateNormal];
        _hangUpBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [_hangUpBtn addTarget:self action:@selector(hangup:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangUpBtn;
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

- (UIButton *)speakerBtn {
    if (!_speakerBtn) {
        _speakerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _speakerBtn.frame = CGRectMake((SCREEN_W - 268)/2 + 106, SCREEN_H - 188, 50, 50);
        [_speakerBtn setImage:[UIImage imageNamed:@"btn_speaker_normal"] forState:UIControlStateNormal];
        [_speakerBtn setImage:[UIImage imageNamed:@"btn_speaker_pressed"] forState:UIControlStateSelected];
        [_speakerBtn addTarget:self action:@selector(userSpeaker:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _speakerBtn;
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

- (UIButton *)localRecordBtn {
    if (!_localRecordBtn) {
        _localRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _localRecordBtn.frame = CGRectMake((SCREEN_W - 268)/2 + 214, SCREEN_H - 188, 50, 50);
        [_localRecordBtn setImage:[UIImage imageNamed:@"btn_record_normal"] forState:UIControlStateNormal];
        [_localRecordBtn setImage:[UIImage imageNamed:@"btn_record_pressed"] forState:UIControlStateSelected];
        [_localRecordBtn addTarget:self action:@selector(localRecord:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _localRecordBtn;
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
