//
//  YNVideoChatViewController.h
//  RNNeteaseIm
//
//  Created by ctrip on 2018/11/27.
//  Copyright © 2018 Dowin. All rights reserved.
//
#if __has_include("RCTViewManager.h")
#import "RCTViewManager.h"
#else
#import <React/RCTViewManager.h>
#endif

#import "NTESNetChatViewController.h"

@class NTESNetCallChatInfo;
@class NTESVideoChatNetStatusView;

NS_ASSUME_NONNULL_BEGIN

@interface YNVideoChatViewController : NTESNetChatViewController

//通话过程中，从语音聊天切到视频聊天
- (instancetype)initWithCallInfo:(NTESNetCallChatInfo *)callInfo;

@property (strong, nonatomic) UIImageView *bigVideoView;


@property (strong, nonatomic) UIView *smallVideoView;

@property (nonatomic,strong) UIButton *hungUpBtn;   //挂断按钮

@property (nonatomic,strong) UIButton *acceptBtn; //接通按钮

@property (nonatomic,strong) UIButton *refuseBtn;   //拒接按钮

@property (nonatomic,strong) UILabel  *durationLabel;//通话时长

@property (nonatomic,strong) UIButton *muteBtn;     //静音按钮

@property (nonatomic,strong) UIButton *switchModelBtn; //模式转换按钮

@property (nonatomic,strong) UIButton *switchCameraBtn; //切换前后摄像头

@property (nonatomic,strong) UIButton *disableCameraBtn; //禁用摄像头按钮

@property (strong, nonatomic) UIButton *localRecordBtn; //录制

@property (nonatomic,strong) UILabel  *connectingLabel;  //等待对方接听

@property (nonatomic,strong) NTESVideoChatNetStatusView *netStatusView;//网络状况

@property (strong, nonatomic) UIView *localRecordingView;

@property (strong, nonatomic) UIView *localRecordingRedPoint;

@property (strong, nonatomic) UIView *lowMemoryView;

@property (strong, nonatomic) UIView *lowMemoryRedPoint;

@end

NS_ASSUME_NONNULL_END
