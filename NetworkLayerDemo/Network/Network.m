//
//  Network.m
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import <AFNetworking.h>
#import "Network.h"
#import "SessionTask.h"
#import "RequestSerializer.h"
#import "ResponseSerializer.h"
#import "NetworkDefine.h"
#import "ServerConfiguration.h"

#define kApiErrorCode @"result"
#define ApiErrorCodeSuccess (!([json isKindOfClass:[NSDictionary class]]&&json[kApiErrorCode]&&[json[kApiErrorCode] integerValue] != 0))

#define ApiShowRequestErrorMsg if([json isKindOfClass:[NSDictionary class]]&&json[@"msg"]) { [FunctionCommon popNotice:json[@"msg"]];}

#define MaxActivityTaskCount 20        //最大请求并发数
#define MaxRetryTimes 3                //请求失败后最大重试次数
#define MaxRetryTimeInterval 30        //超过最大重试次数，等待30秒之后才能重新请求

static NSString*        _sessionId;
static NSMutableArray*  _suspendedTasks;
static NSInteger        _activityTaskCount = 19;
static BOOL             _isRequestingSessionId = NO;

static AFHTTPSessionManager *_encryptionSessionManager = nil;
static dispatch_semaphore_t _lock; //信号灯保证线程安全

//出现多次请求失败则重置sessionID
@interface Network (PROTECT)

+ (void)increaseTotalFailTimes;
+ (void)clearFailTimes;

@end

@implementation Network @end
@implementation Network (Encrypt)

#pragma mark - initialize
+ (void)load {
    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }];
}

+ (void)initializationConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _encryptionSessionManager = [AFHTTPSessionManager manager];
        _encryptionSessionManager.requestSerializer = [RequestSerializer serializer];
        _encryptionSessionManager.responseSerializer = [ResponseSerializer serializer];
        _lock = dispatch_semaphore_create(1);
    });
}

#pragma mark - session
+ (void)requestSessionIfNeeded {
    if (![self sessionId] && !_isRequestingSessionId ) {
        [self requestSessionId];
    }
}
+ (void)requestSessionId {
    [self initializationConfig];
    if (_isRequestingSessionId) {
        return;
    }

    [self setSessionId: nil];
    //这里要做一次3DES密钥和干扰码的初始化工作
    //[EncryptManager remakeTripleDesKeyAndIv];


    //公共参数
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"model"] = @"手机的型号";
    data[@"version"] = @"手机固件版本";
    data[@"os"] = @"手机平台ID Android=1, iPhone=2";
    data[@"imei"] = @"手机设备IMEI";
    data[@"country"] = @"国家地区";
    data[@"language"] = @"语言";
    data[@"network"] = @"联网方式：WIFI=1, Mobile=2";
    data[@"cityid"] = @"当前城市ID";


    //请求参数
    NSMutableDictionary *parameters = @{}.mutableCopy;
    parameters[@"publickey"] = @"RSA公钥";
    parameters[@"interference"] = @"本地的DES干扰码，自己随机生成";
    parameters[@"sign"] = @"本地的3DES密钥 -> RSA公钥加密";
    parameters[@"data"] = @"将data字典 -> NSData -> 3DES -> Base64";

    [self postJSONWithAct:ApiActSessionId parameters:parameters success:^(id json) {
        if (ApiErrorCodeSuccess) {
            [self setSessionId:json[@"sessionid"]];
        } else {
            //失败后重试
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self requestSessionId];
            });
        }
        _isRequestingSessionId = NO;
    } fail:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _isRequestingSessionId = NO;
            [self requestSessionId];
        });
    }];
}

+ (void)setSessionId:(NSString *)sessionId {
    //本地做持久化处理
}
+ (NSString *)sessionId {
    return @"从本地读取sessionId";
}

#pragma mark - post
+ (id<SessionTask>)postJSONWithAct:(ApiAct)act
                        parameters:(id)parameters
                           success:(void (^)(id json))success
                              fail:(void (^)(void))fail
{
    SessionTask *sessionTask = [SessionTask taskWithAct:act params:parameters success:success fail:fail];
    [self addTask:sessionTask];
    return sessionTask;
}

+ (void)addTask:(SessionTask *)sessionTask {
    [self initializationConfig];

    NSURLSessionDataTask *task = nil;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    ((RequestSerializer *)_encryptionSessionManager.requestSerializer).act = sessionTask.act;

    if (((_isRequestingSessionId || ![self sessionId] || _activityTaskCount >= MaxActivityTaskCount))&& sessionTask.act != ApiActSessionId){
        [self enqueueTask:sessionTask];
    } else {
        _activityTaskCount++;
        task = [_encryptionSessionManager POST:ServerURL parameters:sessionTask.params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id json) {

                _activityTaskCount = MAX(0, _activityTaskCount-1);

                if ([json isKindOfClass:[NSDictionary class]] && [json[kApiErrorCode] integerValue] == 8) {
                    //错误码8表示SessionID无效
                    [self requestSessionId];

                    //调用sessionTask，告知任务超时（会话失效）
                    [sessionTask resume];
                } else {
                    if (!ApiErrorCodeSuccess) {
                        [self increaseTotalFailTimes];
                    } else {
                        [self clearFailTimes];
                    }
                    sessionTask.success(json);
                    [self dequeueAndResumeTasks];
                }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                _activityTaskCount = MAX(0, _activityTaskCount-1);
                if ([self isUserCancel:error]) {
                    return;
                }

                if (sessionTask.failedTimes < MaxRetryTimes &&
                    [[NSDate date] timeIntervalSinceDate:sessionTask.date] < MaxRetryTimeInterval) {
                    sessionTask.failedTimes++;
                    [sessionTask resume];
                } else {
                    [self dequeueAndResumeTasks];
                    sessionTask.fail();
                }
        }];
    }

    dispatch_semaphore_signal(_lock);
    sessionTask.innerTask = task;
}

#pragma mark - task queue
+ (BOOL)isUserCancel:(NSError *)error {
    return [error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled;
}

+ (void)enqueueTask:(SessionTask *)task{
    if (!task) {
        return;
    }
    if (!_suspendedTasks) {
        _suspendedTasks = [NSMutableArray array];
    }
    [_suspendedTasks addObject:task];
}

+ (SessionTask *)dequeueTask {
    SessionTask *task = [_suspendedTasks firstObject];
    [_suspendedTasks removeObject:task];
    return task;
}

+ (void)dequeueAndResumeTasks {
    while (!_isRequestingSessionId &&
           [self sessionId] &&
           _suspendedTasks.count > 0 &&
           _activityTaskCount < MaxActivityTaskCount)
    {
        SessionTask *suspendedTask = [self dequeueTask];
        [suspendedTask resume];
    }
}

@end

#pragma mark - upload & download
@implementation Network (Other)

+ (NSURLSessionDataTask *)uploadImages:(NSArray *)images success:(void (^)(id json))success fail: (void (^)(void))fail {
    if (_isRequestingSessionId || ![self sessionId]) {
        return nil;
    }

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [RequestSerializer serializer];
    manager.responseSerializer = [ResponseSerializer serializer];

    ((RequestSerializer *)manager.requestSerializer).act = ApiActUploadImages;

    NSURLSessionDataTask *task = [manager POST:ServerURL parameters:images progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable json) {
        success(json);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        fail();
    }];

    return task;
}

+ (void)downloadFileWithURL: (id)url
                   filePath: (NSString *)filePath
          completionHandler:(void (^)(NSURLResponse *response, NSURL *fileURL, NSError *error))completionHandler {

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        if (filePath) {
            return [NSURL URLWithString:filePath];
        } else {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        completionHandler(response, filePath, error);
    }];
    [task resume];
}

@end

#pragma mark - request protect
@implementation Network (PROTECT)

static NSInteger totalFailTimes = 0;
+ (void)increaseTotalFailTimes {
    totalFailTimes++;
    if (totalFailTimes > 5) {
        [self clearFailTimes];
        [self requestSessionId];
    }
}

+ (void)clearFailTimes {
    totalFailTimes = 0;
}

@end
