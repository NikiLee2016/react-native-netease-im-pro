//
//  RNNeteaseIm.h
//  RNNeteaseIm
//
//  Created by Dowin on 2017/5/9.
//  Copyright © 2017年 Dowin. All rights reserved.
//
#if __has_include("RCTViewManager.h")
#import "RCTViewManager.h"
#else
#import <React/RCTViewManager.h>
#endif

#if __has_include("RCTUtils.h")
#import "RCTUtils.h"
#else
#import <React/RCTUtils.h>
#endif

#import "NIMModel.h"
#import "NIMViewController.h"
#import "ContactViewController.h"
#import "NoticeViewController.h"
#import "TeamViewController.h"
#import "ConversationViewController.h"
#import "BankListViewController.h"

@interface RNNeteaseIm : RCTViewManager <NIMNetCallManagerDelegate>

@end
