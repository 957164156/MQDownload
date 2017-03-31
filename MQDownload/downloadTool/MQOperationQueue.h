//
//  MQOperationQueue.h
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/30.
//  Copyright © 2017年 爱书人. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@class SMQRequest;



@interface MQOperationManager : NSObject

+ (instancetype)defaultOperationManager;
- (SMQRequest *)requestForURL:(NSString *)url;

//
@property (nonatomic,strong)NSMutableArray *taskList;

/**
 开始下载

 @param request 下载任务
 */
- (void)startDownloadWithRequest:(SMQRequest *)request;


/**
 暂停下载

 @param request 下载任务
 */
- (void)pauseDownloadWithRequest:(SMQRequest *)request;


/**
 移除下载任务

 @param request 下载任务
 */
- (void)removeDownloadTaskWithRequest:(SMQRequest *)request;


/**
 取消下载任务

 @param request 下载任务
 */
- (void)cancleDownloadWithRequest:(SMQRequest *)request;


/**
 开始任务

 @param request 从等待中开始的任务
 */
- (void)playDownloadTaskWithRequest:(SMQRequest *)request;


/**
 恢复下载

 @param request 从暂停中恢复下载
 */
- (void)resumeDownloadTaskWithRequest:(SMQRequest *)request;
@end
