//
//  SMQRequest.m
//  dingdongxueyuaniOS
//
//  Created by 孙明卿 on 2017/3/30.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import "SMQRequest.h"
#import "MQOperationQueue.h"
#import <CommonCrypto/CommonDigest.h>
@interface DownloadPathUtils : NSObject
+ (NSString *)downloadTmpPath;
+ (NSString *)downloadPath;
+ (NSString *)resumeDatatTmpPath;
+ (NSString *)cachedFileNameForKey:(NSString *)key;

@end
@implementation DownloadPathUtils
+ (void)checkFilePath:(NSString *)path
{
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (!(isDir && existed)) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}
/**
 * 默认下载临时路径
 **/
+ (NSString *)downloadTmpPath
{
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [documentPaths objectAtIndex:0];
    NSString *tmpPath = [docsDir stringByAppendingPathComponent:@"MQDownloadTmpFiles"];
    [DownloadPathUtils checkFilePath:tmpPath];
    return tmpPath;
}

/**
 * 默认下载路径
 **/
+ (NSString *)downloadPath
{
    
    NSString *savePath = [NSString stringWithFormat:@"%@/Library/Caches/ASRVdeio/",NSHomeDirectory()];
    [DownloadPathUtils checkFilePath:savePath];
    return savePath;
}

/**
 * 获取app  tmp 目录
 **/
+ (NSString *)resumeDatatTmpPath
{
    NSString *tmpDir = NSTemporaryDirectory();
    return tmpDir;
}


/**
 * 计算URL的MD5值作为缓存数据文件名
 **/
+ (NSString *)cachedFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

@end
@interface SMQRequest()
@property (nonatomic,strong)MQOperationManager *manager;

@property (strong, nonatomic,readwrite) NSData *resumeData;   //断点续传的Data(包含URL)

@property (readwrite)NSMutableURLRequest *request;                 //请求对象

@end
@implementation SMQRequest

/**
* 实例化请求对象 已经存在则返回 不存在则创建一个并返回
**/
+ (SMQRequest *)initWithURL:(NSString *)url
{
    SMQRequest *request = [[MQOperationManager defaultOperationManager] requestForURL:url];
    if (!request) {
        request = [[SMQRequest alloc] initWithURL:url];
    }else {
        NSLog(@" 该任务已经在下载队列中了");
    }
    return request;
}
- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self) {
        self.url = url;
        self.currentState = downloadState_default;
        self.manager = [MQOperationManager defaultOperationManager];
        self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
        self.request.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
        //    self.request.timeoutInterval = 60;
        self.resumeData = [self readResumeData];
    }
    return self;
}

//开始下载任务
- (void)startDownloadTask {
    [self.manager startDownloadWithRequest:self];
}

//暂停下载任务
- (void)pauseDownloadTask {
    if (self.currentState == downloadState_pauseing) {//当前状态本来就是暂停
    
        return;
    }
    //
    __weak typeof(self) weakSelf = self;
    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        weakSelf.resumeData = resumeData;
        weakSelf.task = nil;
        [weakSelf.manager pauseDownloadWithRequest:weakSelf];
        //将resume写入文件，以便回复
        [weakSelf resumeDataWriteToFile];
    }];
}
//取消下载任务
- (void)cancleDownloadTask {
    if (self.currentState == downloadState_downloading) {
        [self.task cancel];
    }
    [self deleteResumeData];
    [self.manager cancleDownloadWithRequest:self];
}
//恢复下载任务
- (void)resumeDownloadTask {
    self.resumeData = [self readResumeData];
    if (self.currentState != downloadState_pauseing) {
        return;
    }
   [self.manager startDownloadWithRequest:self];
    self.resumeData = nil;
}
//更换正在下载的任务
- (void)changeDownloadTask {
    
}
#pragma mark  ======  resumedata的操作
//断点缓存数据写入文件
- (void)resumeDataWriteToFile
{
    if (!self.resumeData) {
        return;
    }
    NSString *tmpPath = [[DownloadPathUtils resumeDatatTmpPath] stringByAppendingPathComponent:[DownloadPathUtils cachedFileNameForKey:self.url]];
    if (![self.resumeData writeToFile:tmpPath atomically:NO]) {
    }
}

//移除断点缓存数据
- (void)deleteResumeData
{
    NSString *tmpPath = [[DownloadPathUtils resumeDatatTmpPath] stringByAppendingPathComponent:[DownloadPathUtils cachedFileNameForKey:self.url]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tmpPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
    }
}
/**
 * 读取本地保存的文件下载断点位置信息数据
 **/
- (NSData *)readResumeData
{
    NSString *resumeDataPath = [[DownloadPathUtils resumeDatatTmpPath] stringByAppendingPathComponent:[DownloadPathUtils cachedFileNameForKey:self.url]];
    NSData *resume_Data = [NSData dataWithContentsOfFile:resumeDataPath];
    return resume_Data;
}
@end
