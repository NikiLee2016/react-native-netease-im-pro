//
//  NoticeViewController.m
//  NIM
//
//  Created by Dowin on 2017/5/4.
//  Copyright © 2017年 Dowin. All rights reserved.
//

#import "NoticeViewController.h"
#import "NTESBundleSetting.h"
@interface NoticeViewController ()<NIMUserManagerDelegate,NIMSystemNotificationManagerDelegate>
{
    NSMutableArray *_notifications;
    NSMutableArray *_notiArr;
    BOOL _shouldMarkAsRead;
}

@end

@implementation NoticeViewController


+(instancetype)initWithNoticeViewController{
    static NoticeViewController *notVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notVC = [[NoticeViewController alloc]init];
        
    });
    return notVC;
}
-(void)initWithDelegate{
    [[[NIMSDK sharedSDK] systemNotificationManager] addDelegate:self];
    [[[NIMSDK sharedSDK] userManager] addDelegate:self];
    _notifications = [NSMutableArray array];
    [self setAllread];
    id<NIMSystemNotificationManager> systemNotificationManager = [[NIMSDK sharedSDK] systemNotificationManager];
    [systemNotificationManager addDelegate:nil];
    
    NSArray *notifications = [systemNotificationManager fetchSystemNotifications:nil
                                                                           limit:MaxNotificationCount];
    _notiArr = [NSMutableArray array];
    if ([notifications count])
    {
//        for (int i = 0; i < notifications.count - 1; i++) {
//            NIMSystemNotification *notices = [notifications objectAtIndex:i];
//            NIMSystemNotification *notices1 = [notifications objectAtIndex:i+1];
//           NSLog(@"555555555555555%@",notices.sourceID);
//            if ([notices.sourceID isEqualToString:notices1.sourceID]) {
//                
//                [[NIMSDK sharedSDK].systemNotificationManager markNotificationsAsRead:notices];
//                [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notices];
//            }
//        }
        for (int i = 0; i < notifications.count - 1; i++) {
            for (int j = i+ 1; j <  notifications.count; j++) {
                NIMSystemNotification *notices = [notifications objectAtIndex:i];
                NIMSystemNotification *notices1 = [notifications objectAtIndex:j];
                if ([notices.sourceID isEqualToString:notices1.sourceID]) {
                    
                    [[NIMSDK sharedSDK].systemNotificationManager markNotificationsAsRead:notices];
                    [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notices];
                }
            }
        }
    }
    
    [self ReFrash];
  
}
-(void)ReFrash{
    id<NIMSystemNotificationManager> systemNotificationManager = [[NIMSDK sharedSDK] systemNotificationManager];
    [systemNotificationManager addDelegate:self];
    NSArray *Secnotifications = [systemNotificationManager fetchSystemNotifications:nil
                                                                              limit:MaxNotificationCount];
    
   
   
        [_notiArr removeAllObjects];
        [_notifications removeAllObjects];
        [_notifications addObjectsFromArray:Secnotifications];
        for (NIMSystemNotification *notices in _notifications) {
            NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
            [self updateSourceMember:sourceMember andNoti:notices];
        }
        [self refrash];
    
}


- (void)stopSystemMsg{
    //[[[NIMSDK sharedSDK] systemNotificationManager] removeDelegate:self];
    [[[NIMSDK sharedSDK] userManager] removeDelegate:self];
}
#pragma mark - NIMSDK Delegate
- (void)onSystemNotificationCountChanged:(NSInteger)unreadCount
{
    NIMModel *mode = [NIMModel initShareMD];
    mode.unreadCount = unreadCount;
    NSLog(@"2-----------unreadCount:%zd",unreadCount);

}
- (void)onReceiveSystemNotification:(NIMSystemNotification *)notification{
    NSLog(@"2----notification:%@",notification);
    if (notification.type == NIMSystemNotificationTypeFriendAdd) {
        NIMUserAddAttachment *attach = notification.attachment;
        NSLog(@"2------attach.type:%zd",attach.operationType);
        if (attach.operationType == NIMUserOperationVerify) {//如果是通过添加好友请求，标为已读并删除
            [[NIMSDK sharedSDK].systemNotificationManager markNotificationsAsRead:notification];
            [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notification];
            return;
        }
    }
    
    if (_notifications.count) {
        NSMutableArray *tmpArr = [NSMutableArray array];
        for (NIMSystemNotification *notices in _notifications) {
            
            if ([notices.sourceID isEqualToString:notification.sourceID]) {
                [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notices];
            }else{
                [tmpArr addObject:notices];
            }
        }
        [_notifications removeAllObjects];
        [_notifications addObjectsFromArray:tmpArr];
    }
    [_notifications insertObject:notification atIndex:0];
    
    _shouldMarkAsRead = YES;
    [_notiArr removeAllObjects];
    for (NIMSystemNotification *notices in _notifications) {
        NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
        [self updateSourceMember:sourceMember andNoti:notices];
    }
    [self refrash];
}


- (void)updateSourceMember:(NIMKitInfo *)sourceMember andNoti:(NIMSystemNotification *)noti{
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    BOOL isVerify = @"0";
    NIMSystemNotificationType type = noti.type;
    NSString *avatarUrlString = sourceMember.avatarUrlString;
    NSURL *url;
    if (avatarUrlString.length) {
        url = [NSURL URLWithString:avatarUrlString];
    }
    NIMTeam *team;
    NSString *verifyText = @"未知请求";
    switch (type) {
        case NIMSystemNotificationTypeTeamApply:
        {
            team = [[NIMSDK sharedSDK].teamManager teamById:noti.targetID];
            isVerify = @"1";
            verifyText = [NSString stringWithFormat:@"申请加入群 %@", team.teamName];
        }
            break;
        case NIMSystemNotificationTypeTeamApplyReject:
        {
            team = [[NIMSDK sharedSDK].teamManager teamById:noti.targetID];
            verifyText = [NSString stringWithFormat:@"群 %@ 拒绝你加入", team.teamName];
        }
            break;
        case NIMSystemNotificationTypeTeamInvite:
        {
            team = [[NIMSDK sharedSDK].teamManager teamById:noti.targetID];
            isVerify = @"1";
            verifyText = [NSString stringWithFormat:@"群 %@ 邀请你加入", team.teamName];
        }
            break;
        case NIMSystemNotificationTypeTeamIviteReject:
        {
            team = [[NIMSDK sharedSDK].teamManager teamById:noti.targetID];
            verifyText = [NSString stringWithFormat:@"拒绝了群 %@ 邀请", team.teamName];
        }
            break;
        case NIMSystemNotificationTypeFriendAdd:
        {
            id object = noti.attachment;
            if ([object isKindOfClass:[NIMUserAddAttachment class]]) {
                NIMUserOperation operation = [(NIMUserAddAttachment *)object operationType];
                switch (operation) {
                    case NIMUserOperationAdd:
                        verifyText = @"已添加你为好友";
                        break;
                    case NIMUserOperationRequest:
                        isVerify = @"1";
                        verifyText = [noti.postscript length]?noti.postscript:@"请求添加你为好友";
                        break;
                    case NIMUserOperationVerify:
                        verifyText = @"通过了你的好友请求";
                        noti.handleStatus = NotificationHandleTypeOk;
                        break;
                    case NIMUserOperationReject:
                        verifyText = @"拒绝了你的好友请求";
                        noti.handleStatus = NotificationHandleTypeNo;
                        break;
                    default:
                        break;
                }
            }
        }
            break;
        default:
            break;
    }
    [dic setObject:[NSString stringWithFormat:@"%d",isVerify] forKey:@"isVerify"];
    [dic setObject:[NSString stringWithFormat:@"%@",verifyText] forKey:@"verifyText"];
    [dic setObject:[NSString stringWithFormat:@"%@",verifyText] forKey:@"verifyResult"];
    [dic setObject:@"" forKey:@"messageId"];
    [dic setObject:[NSString stringWithFormat:@"%ld",noti.type] forKey:@"type"];
    [dic setObject:[NSString stringWithFormat:@"%@",noti.targetID] forKey:@"targetId"];
    [dic setObject:[NSString stringWithFormat:@"%@",noti.sourceID] forKey:@"fromAccount"];
    [dic setObject:[NSString stringWithFormat:@"%@",noti.postscript] forKey:@"content"];
    [dic setObject:[NSString stringWithFormat:@"%@",sourceMember.showName] forKey:@"name"];
    [dic setObject:[NSString stringWithFormat:@"%@",url] forKey:@"avatar"];
    [dic setObject:[NSString stringWithFormat:@"%ld",noti.handleStatus] forKey:@"status"];
    [dic setObject:[NSString stringWithFormat:@"%f",noti.timestamp] forKey:@"time"];
    
    [_notiArr addObject:dic];

}
//加载更多
- (void)loadMore:(id)sender
{
    NSArray *notifications = [[[NIMSDK sharedSDK] systemNotificationManager] fetchSystemNotifications:[_notifications lastObject]
                                                                                                limit:MaxNotificationCount];
    if ([notifications count])
    {
        [_notifications addObjectsFromArray:notifications];
        
    }
}
//删除信息
-(void)deleteNotice:(NSString *)targetID timestamp:(NSString *)timestamp{
    for (int i = 0; i < _notifications.count; i++) {
        NIMSystemNotification *notices =_notifications[i];
        if ([targetID isEqualToString:notices.sourceID]) {
                [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:notices];
        }
    }
    [self ReFrash];
}
//删除所有
-(void)deleAllNotic{
    [[[NIMSDK sharedSDK] systemNotificationManager] deleteAllNotifications];
    [_notifications removeAllObjects];
    [_notiArr removeAllObjects];
    [self refrash];
    
}
-(void)refrash{
    NIMModel *mode = [NIMModel initShareMD];
   
    mode.notiArr = _notiArr;
}
//返回标记为已读
-(void)setAllread{
    if (_shouldMarkAsRead)
    {
        [[[NIMSDK sharedSDK] systemNotificationManager] markAllNotificationsAsRead];
    }
}
//同意
-(void)onAccept:(NSString *)targetID timestamp:(NSString *)timestamp sucess:(Success)success error:(Errors)err{
    
    __weak typeof(self)weakSelf = self;
    for (int i = 0; i < _notiArr.count; i++) {
        if ([targetID isEqualToString:[[_notiArr objectAtIndex:i] objectForKey:@"fromAccount"]]) {
            if ([timestamp isEqualToString:[[_notiArr objectAtIndex:i] objectForKey:@"time"]]) {
                NIMSystemNotification *notices = [_notifications objectAtIndex:i];
                switch (notices.type) {
                    case NIMSystemNotificationTypeTeamApply:{
                        [[NIMSDK sharedSDK].teamManager passApplyToTeam:notices.targetID userId:notices.sourceID completion:^(NSError *error, NIMTeamApplyStatus applyStatus) {
                            if (!error) {
                                [_notifications replaceObjectAtIndex:i withObject:notices];
                                for (NIMSystemNotification *notices in _notifications) {
                                    NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
                                    [self updateSourceMember:sourceMember andNoti:notices];
                                }
                                notices.handleStatus = NotificationHandleTypeOk;
                                success(@"同意成功");
                            }else {
                                if(error.code == NIMRemoteErrorCodeTimeoutError) {
                                    err(@"网络问题，请重试");
                                } else {
                                    notices.handleStatus = NotificationHandleTypeOutOfDate;
                                }
                            }
                        }];
                        break;
                    }
                    case NIMSystemNotificationTypeTeamInvite:{
                        [[NIMSDK sharedSDK].teamManager acceptInviteWithTeam:notices.targetID invitorId:notices.sourceID completion:^(NSError *error) {
                            if (!error) {
                                [_notifications replaceObjectAtIndex:i withObject:notices];
                                for (NIMSystemNotification *notices in _notifications) {
                                    NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
                                    [self updateSourceMember:sourceMember andNoti:notices];
                                }
                                notices.handleStatus = NotificationHandleTypeOk;
                                success(@"同意成功");
                            }else {
                                if(error.code == NIMRemoteErrorCodeTimeoutError) {
                                    success(@"请求超时");
                                }
                                else if (error.code == NIMRemoteErrorCodeTeamNotExists) {
                                    err(@"群组不存在");
                                }
                                else {
                                    notices.handleStatus = NotificationHandleTypeOutOfDate;
                                }
                                
                            }
                        }];
                    }
                        break;
                    case NIMSystemNotificationTypeFriendAdd:
                    {
                        NIMUserRequest *request = [[NIMUserRequest alloc] init];
                        request.userId = notices.sourceID;
                        request.operation = NIMUserOperationVerify;
                        
                        [[[NIMSDK sharedSDK] userManager] requestFriend:request
                                                             completion:^(NSError *error) {
                                                                 if (!error) {
                                                                     notices.handleStatus = NotificationHandleTypeOk;
                                                                     [_notifications replaceObjectAtIndex:i withObject:notices];
                                                                     [_notiArr removeAllObjects];
                                                                     for (NIMSystemNotification *notices in _notifications) {
                                                                         NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
                                                                         [self updateSourceMember:sourceMember andNoti:notices];
                                                                     }
                                                                     success(@"同意成功");
                                                                     [weakSelf sendMakeFriendSucessMessgae:request.userId];
                                                                     [self refrash];
                                                                 }
                                                                 else
                                                                 {
                                                                     err(@"网络问题，请重试");
                                                                     
                                                                 }
                                                             }];
                    }
                        break;
                    default:
                        break;
                }
                
            }
        }
    }
    
    
}


//发送成为好友提醒
- (void)sendMakeFriendSucessMessgae:(NSString *)strUserId{
    NIMMessage *message = [[NIMMessage alloc] init];
    message.text    = @"我们已经是朋友啦，一起来聊天吧！";
    NIMMessageSetting *setting = [[NIMMessageSetting alloc]init];
    setting.apnsEnabled = NO;
    message.setting = setting;
    NIMSession *session = [NIMSession session:strUserId type:NIMSessionTypeP2P];
    //发送消息
    [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:session error:nil];
}


//拒绝
-(void)onRefuse:(NSString *)targetID timestamp:(NSString *)timestamp sucess:(Success)success error:(Errors)err{
    for (int i = 0; i < _notiArr.count; i++) {
        if ([targetID isEqualToString:[[_notiArr objectAtIndex:i] objectForKey:@"fromAccount"]]) {
            if ([timestamp isEqualToString:[[_notiArr objectAtIndex:i] objectForKey:@"time"]]) {
                NIMSystemNotification *notices = [_notifications objectAtIndex:i];
                switch (notices.type) {
                    case NIMSystemNotificationTypeTeamApply:{
                        [[NIMSDK sharedSDK].teamManager rejectApplyToTeam:notices.targetID userId:notices.sourceID rejectReason:@"" completion:^(NSError *error) {
                            if (!error) {
                                
                                notices.handleStatus = NotificationHandleTypeNo;
                                [_notifications replaceObjectAtIndex:i withObject:notices];
                                for (NIMSystemNotification *notices in _notifications) {
                                    NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
                                    [self updateSourceMember:sourceMember andNoti:notices];
                                }
                                success(@"拒绝成功");
                            }else {
                                if(error.code == NIMRemoteErrorCodeTimeoutError) {
                                    err(@"网络问题，请重试");
                                } else {
                                    notices.handleStatus = NotificationHandleTypeOutOfDate;
                                }
                                DDLogDebug(@"%@",error.localizedDescription);
                            }
                        }];
                    }
                        break;
                        
                    case NIMSystemNotificationTypeTeamInvite:{
                        [[NIMSDK sharedSDK].teamManager rejectInviteWithTeam:notices.targetID invitorId:notices.sourceID rejectReason:@"" completion:^(NSError *error) {
                            if (!error) {
                                
                                notices.handleStatus = NotificationHandleTypeNo;
                                [_notifications replaceObjectAtIndex:i withObject:notices];
                                for (NIMSystemNotification *notices in _notifications) {
                                    NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
                                    [self updateSourceMember:sourceMember andNoti:notices];
                                }
                                success(@"拒绝成功");
                            }else {
                                if(error.code == NIMRemoteErrorCodeTimeoutError) {
                                    err(@"网络问题，请重试");
                                }
                                else if (error.code == NIMRemoteErrorCodeTeamNotExists) {
                                    err(@"群不存在");
                                    
                                }
                                else {
                                    notices.handleStatus = NotificationHandleTypeOutOfDate;
                                }
                                DDLogDebug(@"%@",error.localizedDescription);
                            }
                        }];
                        
                    }
                        break;
                    case NIMSystemNotificationTypeFriendAdd:
                    {
                        NIMUserRequest *request = [[NIMUserRequest alloc] init];
                        request.userId = notices.sourceID;
                        request.operation = NIMUserOperationReject;
                        
                        [[[NIMSDK sharedSDK] userManager] requestFriend:request
                                                             completion:^(NSError *error) {
                                                                 if (!error) {
                                                                     
                                                                     notices.handleStatus = NotificationHandleTypeNo;
//                                                                     [_notifications replaceObjectAtIndex:i withObject:notices];
//                                                                     for (NIMSystemNotification *notices in _notifications) {
//                                                                         NIMKitInfo *sourceMember = [[NIMKit sharedKit] infoByUser:notices.sourceID option:nil];
//                                                                         [self updateSourceMember:sourceMember andNoti:notices];
//                                                                     }
                                                                     success(@"拒绝成功");
                                                                     
                                                                 }
                                                                 else
                                                                 {
                                                                     err(@"拒绝失败,请重试");
                                                                 }
                                                                 
//                                                                 DDLogDebug(@"%@",error.localizedDescription);
                                                             }];
                    }
                        break;
                    default:
                        break;
                }
            }
        }
    }
    
    
    [self refrash];
}

@end
