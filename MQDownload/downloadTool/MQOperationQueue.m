//
//  MQOperationQueue.m
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/30.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import "MQOperationQueue.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "SMQRequest.h"
@interface MQOperationManager()<NSURLSessionDownloadDelegate>

@property (nonatomic,strong)NSURLSession *backgroudSession;


@property (strong, nonatomic) dispatch_queue_t downloadQueue;


//是否有任务正在下载
@property (nonatomic,assign,getter=isDownloading)BOOL downloading;

@end
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
static dispatch_semaphore_t semaphore = nil;
static NSInteger maxCountForDownloadTask = 1;
static MQOperationManager *manager = nil;
@implementation MQOperationManager
#pragma mark - backgroundURLSession
- (NSURLSession *)backgroundURLSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"com.yourcompany.appId.BackgroundSession";
        NSURLSessionConfiguration* sessionConfig = nil;
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000)
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
#else
        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#endif
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

+ (instancetype)defaultOperationManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.taskList = [NSMutableArray array];
        manager.downloadQueue = dispatch_queue_create("SMQDownloadQueue", DISPATCH_QUEUE_SERIAL);
        //创建信号量
        semaphore = dispatch_semaphore_create(1);
        manager.backgroudSession = [manager backgroundURLSession];
    });
    
    return manager;
}
- (SMQRequest *)requestForURL:(NSString *)url
{
    SMQRequest *req = nil;
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    for (SMQRequest *tmpRequest in self.taskList) {
        
        if ([tmpRequest.url isEqualToString:url]) {
            req = tmpRequest;
            break;
        }
    }
    dispatch_semaphore_signal(semaphore);
    return req;
    
}


- (void)dealloc {
    self.downloadQueue = nil;
    [self.taskList removeAllObjects];
    self.taskList = nil;
    self.backgroudSession = nil;
}
#pragma mark  =====   开始下载
- (void)startDownloadWithRequest:(SMQRequest *)request {
    //
    if (!request || !request.request) {//请求为空
        
        return;
    }
    //创建下载任务
    NSURLSessionDownloadTask *task = nil;
    if (request.resumeData) {//断点续传文件存在
        if (IS_IOS10ORLATER) {
          task = [self.backgroudSession downloadTaskWithCorrectResumeData:request.resumeData];
        }else {
         task = [self.backgroudSession downloadTaskWithResumeData:request.resumeData];
        }
    }else {
        task = [self.backgroudSession downloadTaskWithRequest:request.request];
    }
    request.task = task;
    request.currentState = downloadState_waiting;
    //将任务添加进队列
    [self addTaskQueueWithRequest:request];
}

//将请求加入队列
- (void)addTaskQueueWithRequest:(SMQRequest *)request {
    //
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloadQueue, ^{
        //对任务数组操作一定要枷锁
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if ([weakSelf.taskList containsObject:request]) {//已经包含此任务
            NSLog(@"该任务已经在下载队列中");
        }else {//将任务添加进队列
            [weakSelf.taskList addObject:request];
        }
        //操作完毕
        dispatch_semaphore_signal(semaphore);
        //开始下载任务
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf startTaskForRequest];
        });
    });
}
//开始下载任务
- (void)startTaskForRequest{
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloadQueue, ^{
        NSInteger taskCount = 0;
        BOOL hasTaskRun = NO;
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        for (int i = 0; i < weakSelf.taskList.count; i++) {
            SMQRequest *request = [weakSelf.taskList objectAtIndex:i];
            if (request.currentState == downloadState_downloading) {//正在下载
                taskCount ++;
                hasTaskRun = YES;
            }else if (request.currentState == downloadState_waiting) {//等待状态
                request.currentState = downloadState_downloading;
                taskCount++;
                hasTaskRun = YES;
                [request.task resume];
                if (request.delegate && [request respondsToSelector:@selector(requestDownloadStart:)]) {
                    [request.delegate requestDownloadStart:request];
                }
            }else if (request.currentState == downloadState_pauseing) {//暂停状态
                //不做任何操作
            }
            if (taskCount >= maxCountForDownloadTask) {
                break;
            }
        }
        //操作完毕
        dispatch_semaphore_signal(semaphore);
#ifdef TARGET_OS_IPHONE
        dispatch_async(dispatch_get_main_queue(), ^{
            //显示互联网标记
            [UIApplication sharedApplication].networkActivityIndicatorVisible = hasTaskRun;
        });
#endif
    });
   
}

#pragma mark ====  暂停下载
/**
 暂停下载
 
 @param request 下载任务
 */
- (void)pauseDownloadWithRequest:(SMQRequest *)request {
    self.downloading = NO;
    request.currentState = downloadState_pauseing;
    if (request.delegate && [request.delegate respondsToSelector:@selector(requestDownloadPause:)]) {
        [request.delegate requestDownloadPause:request];
    }
    //
    [self startTaskForRequest];
}
/**
 恢复下载
 
 @param request 从暂停中恢复下载
 */
- (void)resumeDownloadTaskWithRequest:(SMQRequest *)request {
    //创建下载任务
    NSURLSessionDownloadTask *task = nil;
    if (request.resumeData) {//断点续传文件存在
        if (IS_IOS10ORLATER) {
            task = [self.backgroudSession downloadTaskWithCorrectResumeData:request.resumeData];
        }else {
            task = [self.backgroudSession downloadTaskWithResumeData:request.resumeData];
        }
    }else {
        task = [self.backgroudSession downloadTaskWithRequest:request.request];
    }
    request.task = task;
    request.currentState = downloadState_waiting;
    //查看是否有任务在下载
    if (!self.isDownloading) {//有任务在下载
        [self addTaskQueueWithRequest:request];
 
       }
}

/**
 开始下载

 @param request 从等待状态开始下载
 */
- (void)playDownloadTaskWithRequest:(SMQRequest *)request {
    dispatch_async(self.downloadQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        for (SMQRequest *DownRequest in self.taskList) {
            if (DownRequest.currentState == downloadState_downloading) {
                [DownRequest pauseDownloadTask];
            }
        }
        dispatch_semaphore_signal(semaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startTaskForRequest];
        });
    });
}
#pragma mark  ==== 移除下载任务

/**
 移除下载任务
 
 @param request 下载任务
 */
- (void)removeDownloadTaskWithRequest:(SMQRequest *)request {
    if (!request) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.downloadQueue, ^{
        //信号
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [weakSelf.taskList removeObject:request];
        //操作完毕
        dispatch_semaphore_signal(semaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            [weakSelf startTaskForRequest];
        });
    });
    
    
}
#pragma mark ===== 取消下载任务
- (void)cancleDownloadWithRequest:(SMQRequest *)request {
    //
    [self removeDownloadTaskWithRequest:request];
}

#pragma mark ================================= NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    self.downloading = NO;
    __block SMQRequest *matchingRequest = nil;
    [self.taskList enumerateObjectsUsingBlock:^(SMQRequest *request, NSUInteger idx, BOOL *stop) {
        if([request.task.currentRequest.URL.absoluteString isEqualToString:downloadTask.currentRequest.URL.absoluteString]) {
            matchingRequest = request;
            [request deleteResumeData]; //移除断点续传缓存数据文件
            request.savePath = [request.savePath stringByAppendingPathComponent:request.saveFileName];
            NSError *error = nil;
            NSLog(@"  %@",[location path]);
            if(![[NSFileManager defaultManager] moveItemAtPath:location.path toPath:request.savePath error:&error]) {
               
                if ([request.delegate respondsToSelector:@selector(requestDownloadFail:)]) {
                    [request.delegate requestDownloadFail:request];
                }
            }else {
                if ([request.delegate respondsToSelector:@selector(requestDownloadFinish:)]) {
                    [request.delegate requestDownloadFinish:request];
                }
            }
            *stop = YES;
        }
    }];
    
    [self removeDownloadTaskWithRequest:matchingRequest];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
}
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    //设置标志提示有任务正在下载
    self.downloading = YES;
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(CGFloat)totalBytesWritten / totalBytesExpectedToWrite * 100);
    NSString *strProgress = [NSString stringWithFormat:@"%.2f",(CGFloat)totalBytesWritten / totalBytesExpectedToWrite];
    float progress = (float)(((float)totalBytesWritten) / ((float)totalBytesExpectedToWrite));
    [self.taskList enumerateObjectsUsingBlock:^(SMQRequest *request, NSUInteger idx, BOOL *stop) {
        if([request.task.currentRequest.URL.absoluteString isEqualToString:downloadTask.currentRequest.URL.absoluteString]) {
            if (!request.saveFileName || request.saveFileName.length <= 0) {
                request.saveFileName = downloadTask.response.suggestedFilename;
            }
            request.totoalData = totalBytesExpectedToWrite;
            request.didWriteData = totalBytesWritten;
            if ([request.delegate respondsToSelector:@selector(requestDownloading:)]) {
                [request.delegate requestDownloading:request];
            }
        }
    }];

}
/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (error) {
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            
        }
    } else {
        //将文件
    }
}
#pragma mark NSURLSession Authentication delegates

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }
    __block SMQRequest *matchingRequest = nil;
    [self.taskList enumerateObjectsUsingBlock:^(SMQRequest *request, NSUInteger idx, BOOL *stop) {
        if([request.task isEqual:task]) {
            matchingRequest = request;
            *stop = YES;
        }
    }];
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    completionHandler(NSURLSessionResponseAllow);
}
@end
