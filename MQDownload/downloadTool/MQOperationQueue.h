//
//  MQOperationQueue.h
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/30.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import <UIKit/UIKit.h>
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
@end
