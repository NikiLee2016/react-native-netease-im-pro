//
//  RNNotificationCenter.m
//  RNNeteaseIm
//
//  Created by Dowin on 2017/5/24.
//  Copyright © 2017年 Dowin. All rights reserved.
//

#import "RNNotificationCenter.h"
#import <AVFoundation/AVFoundation.h>
#import "NSDictionary+NTESJson.h"
#import "NIMMessageMaker.h"
#import "NIMModel.h"
#import "ConversationViewController.h"
#import "YNAudioChatViewController.h"
#import "YNVideoChatViewController.h"
#import "NTESAVNotifier.h"
#import "UIView+Toast.h"
@interface RNNotificationCenter () <NIMSystemNotificationManagerDelegate,NIMChatManagerDelegate, NIMNetCallManagerDelegate>
@property (nonatomic,strong) AVAudioPlayer *player; //播放提示音
@property (nonatomic,strong) NTESAVNotifier *notifier;
@end

@implementation RNNotificationCenter

+ (instancetype)sharedCenter
{
    static RNNotificationCenter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RNNotificationCenter alloc] init];
    });
    return instance;
}
- (void)start
{
    DDLogInfo(@"Notification Center Setup");
}
- (instancetype)init {
    self = [super init];
    if(self) {
      
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"message" withExtension:@"wav"];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        _notifier = [[NTESAVNotifier alloc] init];
        [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
      
        [[NIMSDK sharedSDK].chatManager addDelegate:self];
        [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    }
    return self;
}
- (void)dealloc{
    [[NIMSDK sharedSDK].systemNotificationManager removeDelegate:self];
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}
#pragma mark - NIMChatManagerDelegate
- (void)onRecvMessages:(NSArray *)messages//接收到新消息
{
    static BOOL isPlaying = NO;
    if (isPlaying) {
        return;
    }
    isPlaying = YES;
    [self playMessageAudioTip];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isPlaying = NO;
    });
    [self checkTranferMessage:messages];
}

- (void)playMessageAudioTip
{
//    UINavigationController *nav = [NTESMainTabController instance].selectedViewController;
//    BOOL needPlay = YES;
//    for (UIViewController *vc in nav.viewControllers) {
//        if ([vc isKindOfClass:[NIMSessionViewController class]] ||  [vc isKindOfClass:[NTESLiveViewController class]] || [vc isKindOfClass:[NTESNetChatViewController class]])
//        {
//            needPlay = NO;
//            break;
//        }
//    }
//    if (needPlay) {
//        [self.player stop];
//        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error:nil];
//        [self.player play];
//    }
}
//检测是不是消息助手发来的转账消息提醒
- (void)checkTranferMessage:(NSArray *)messages{
    for (NIMMessage *message in messages) {
        if ([message.from isEqualToString:@"10000"] && (message.messageType == NIMMessageTypeCustom)) {
            NIMCustomObject *customObject = message.messageObject;
            DWCustomAttachment *obj = customObject.attachment;
            if (obj && (obj.custType == CustomMessgeTypeAccountNotice)) {
//                NSLog(@"dataDict:%@",obj.dataDict);
                NIMModel *mode = [NIMModel initShareMD];
                mode.accountNoticeDict = obj.dataDict;
                
            }
        }
    }
   
}

#pragma mark -- NIMChatManagerDelegate
- (void)onRecvRevokeMessageNotification:(NIMRevokeMessageNotification *)notification
{
    NSString * tip = [[ConversationViewController initWithConversationViewController] tipOnMessageRevoked:notification];
    NIMMessage *tipMessage = [[ConversationViewController initWithConversationViewController] msgWithTip:tip];
    tipMessage.timestamp = notification.timestamp;
    NIMMessage *deleMess = notification.message;
    if (deleMess) {
        NSDictionary *deleteDict = @{@"msgId":deleMess.messageId};
        [NIMModel initShareMD].deleteMessDict = deleteDict;
    }

    // saveMessage 方法执行成功后会触发 onRecvMessages: 回调，但是这个回调上来的 NIMMessage 时间为服务器时间，和界面上的时间有一定出入，所以要提前先在界面上插入一个和被删消息的界面时间相符的 Tip, 当触发 onRecvMessages: 回调时，组件判断这条消息已经被插入过了，就会忽略掉。
    [[NIMSDK sharedSDK].conversationManager saveMessage:tipMessage
                                             forSession:notification.session
                                             completion:nil];
}
#pragma mark - NIMSystemNotificationManagerDelegate
- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification{//接收自定义通知
//    NSString *content = notification.content;
    NSDictionary *notiDict = [self jsonDictWithString:notification.content];
    NSTimeInterval timestamp = notification.timestamp;
    if (notiDict){
        NSInteger notiType = [[notiDict objectForKey:@"type"] integerValue];
        switch (notiType) {
            case 1://加好友
                
                break;
            case 2://拆红包消息
            {
                [self saveTheRedPacketOpenMsg:[notiDict objectForKey:@"data"] andTime:timestamp];
            }
                break;
                
            default:
                break;
        }
    }
}
//保存拆红包消息到本地
- (void)saveTheRedPacketOpenMsg:(NSDictionary *)dict andTime:(NSTimeInterval)times{
    NSDictionary *datatDict = [dict objectForKey:@"dict"];
    NSTimeInterval timestamp = times;
    NSString *sessionId = [dict objectForKey:@"sessionId"];
    NSInteger sessionType = [[dict objectForKey:@"sessionType"] integerValue];
    NIMSession *session = [NIMSession session:sessionId type:sessionType];
    NIMMessage *message;
    DWCustomAttachment *obj = [[DWCustomAttachment alloc]init];
    obj.custType = CustomMessgeTypeRedPacketOpenMessage;
    obj.dataDict = datatDict;
    message = [NIMMessageMaker msgWithCustomAttachment:obj andeSession:session];
    message.timestamp = timestamp;
    [[NIMSDK sharedSDK].conversationManager saveMessage:message forSession:session completion:nil];
}

// json字符串转dict字典
- (NSDictionary *)jsonDictWithString:(NSString *)string
{
    if (string && 0 != string.length)
    {
        NSError *error;
        NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (error)
        {
            NSLog(@"json解析失败：%@", error);
            return nil;
        }
        return jsonDict;
    }
    return nil;
}

# pragma - NIMNetCallManagerDelegate
- (void)onHangup:(UInt64)callID by:(NSString *)user {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        [window.rootViewController.view makeToast:@"通话结束" duration:2 position:CSToastPositionCenter];
    });
    [_notifier stop];
}

- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallMediaType)type message:(NSString *)extendMessage {
    
    if ([self shouldFireNotification:caller]) {
        NSString *text = [self textByCaller:caller
                                       type:type];
        [_notifier start:text];
    }
    
    UIViewController *vc;
    switch (type) {
        case NIMNetCallTypeVideo:{
            vc = [[YNVideoChatViewController alloc] initWithCaller:caller callId:callID];
        }
            break;
        case NIMNetCallTypeAudio:{
            vc = [[YNAudioChatViewController alloc] initWithCaller:caller callId:callID];
        }
            break;
        default:
            break;
    }
    UIViewController *rootViewController = RCTPresentedViewController();
    [rootViewController presentViewController:vc animated:YES completion:nil];
}

- (BOOL)shouldFireNotification:(NSString *)callerId
{
    //退后台后 APP 存活，然后收到通知
    BOOL should = YES;
    
    //消息不提醒
    id<NIMUserManager> userManager = [[NIMSDK sharedSDK] userManager];
    if (![userManager notifyForNewMsg:callerId])
    {
        should = NO;
    }
    
    //当前在正处于免打扰
    id<NIMApnsManager> apnsManager = [[NIMSDK sharedSDK] apnsManager];
    NIMPushNotificationSetting *setting = [apnsManager currentSetting];
    if (setting.noDisturbing)
    {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        NSInteger now = components.hour * 60 + components.minute;
        NSInteger start = setting.noDisturbingStartH * 60 + setting.noDisturbingStartM;
        NSInteger end = setting.noDisturbingEndH * 60 + setting.noDisturbingEndM;
        
        //当天区间
        if (end > start && end >= now && now >= start)
        {
            should = NO;
        }
        //隔天区间
        else if(end < start && (now <= end || now >= start))
        {
            should = NO;
        }
    }
    
    return should;
}

- (NSString *)textByCaller:(NSString *)caller type:(NIMNetCallMediaType)type
{
    NSString *action = type == NIMNetCallMediaTypeAudio ? @"音频":@"视频";
    NSString *text = [NSString stringWithFormat:@"你收到了一个%@聊天请求",action];
    NIMKitInfo *info = [[NIMKit sharedKit] infoByUser:caller option:nil];
    if ([info.showName length])
    {
        text = [NSString stringWithFormat:@"%@向你发起了一个%@聊天请求",info.showName,action];
    }
    return text;
}

@end
