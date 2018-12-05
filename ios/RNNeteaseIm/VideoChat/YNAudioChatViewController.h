//
//  TestViewController.h
//  RNNeteaseIm
//
//  Created by cookiej on 2018/11/26.
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

@interface YNAudioChatViewController : NTESNetChatViewController

- (instancetype)initWithCallInfo:(NTESNetCallChatInfo *)callInfo;

@property (nonatomic,strong) UILabel *durationLabel;

@property (nonatomic,strong) UIButton *switchVideoBtn;

@property (nonatomic,strong) UIButton *muteBtn;

@property (nonatomic,strong) UIButton *speakerBtn;

@property (nonatomic,strong) UIButton *hangUpBtn;

@property (nonatomic,strong) UILabel  *connectingLabel;

@property (nonatomic,strong) UIButton *refuseBtn;

@property (nonatomic,strong) UIButton *acceptBtn;

@property (nonatomic,strong) NTESVideoChatNetStatusView *netStatusView;

@property (strong, nonatomic) UIButton *localRecordBtn;


@property (strong, nonatomic) UIView *localRecordingView;

@property (strong, nonatomic) UIView *localRecordingRedPoint;

@property (strong, nonatomic) UIView *lowMemoryView;

@property (strong, nonatomic) UIView *lowMemoryRedPoint;

@end

NS_ASSUME_NONNULL_END
