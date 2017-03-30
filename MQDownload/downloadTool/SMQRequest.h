//
//  SMQRequest.h
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/30.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SMQRequest;
typedef enum {
    downloadState_default = 0,
    downloadState_downloading,
    downloadState_waiting,
    downloadState_pauseing,
    downloadState_finish,
    downloadState_willing
}DownloadState;
@protocol  SMQRequestDelegate<NSObject>
//开始下载
- (void)requestDownloadStart:(SMQRequest *)request;
//下载失败
- (void)requestDownloadFail:(SMQRequest *)request;
//取消
- (void)requestDownloadCancle:(SMQRequest *)request;
//暂停
- (void)requestDownloadPause:(SMQRequest *)request;

//完成
- (void)requestDownloadFinish:(SMQRequest *)request;

//正在下载
- (void)requestDownloading:(SMQRequest *)request;

@end
@interface SMQRequest : NSObject

@property (nonatomic)NSURLSessionDownloadTask *task;             //现在任务对象

//下载文件的路径
@property (nonatomic,copy)NSString *savePath;
@property (nonatomic,copy)NSString *saveFileName;

@property (readonly)NSMutableURLRequest *request;                 //请求对象

@property (nonatomic,strong,readonly)NSData *resumeData;          //断点续传

@property (nonatomic,assign)long long totoalData;                   //下载文件的总长度
@property (nonatomic,assign)long long didWriteData;                 //已经写入的长度


//代理方法
@property (nonatomic,assign)id<SMQRequestDelegate> delegate;

@property (nonatomic,copy)NSString *url;


@property (nonatomic,copy)NSString *name;


@property (nonatomic,copy)NSString *fileName;


@property (nonatomic,assign)DownloadState currentState;

//下载的模型
@property (nonatomic,strong)id  Model;

//创建下载请求
+ (instancetype)requestWithName:(NSString *)name url:(NSString *)url;

//开始下载任务
- (void)startDownloadTask;

//暂停下载任务
- (void)pauseDownloadTask;

//取消下载任务
- (void)cancleDownloadTask;
//恢复下载
- (void)resumeDownloadTask;

//更换正在下载的任务
- (void)changeDownloadTask;

//移除断点续传文件
- (void)deleteResumeData;
@end
