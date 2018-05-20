//
//  SessionTask.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkDefine.h"

@protocol SessionTask<NSObject>
- (void)cancel;
@end

@interface SessionTask: NSObject<SessionTask>

//初始化方法
+ (instancetype)taskWithAct:(ApiAct)act params: (id)params success:(void(^)(id json))success fail:(void(^)(void))fail;
- (void)resume;


//请求体
@property (nonatomic, assign) ApiAct act;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, copy) void (^success)(id json);
@property (nonatomic, copy) void (^fail)(void);


//记录任务开始的时间
@property (nonatomic, strong) NSDate *date;

//任务已失败次数
@property (nonatomic, assign) NSInteger failedTimes;

//任务是否取消/过期
@property (nonatomic, assign) BOOL canceled;
@property (nonatomic, assign, readonly, getter=isExpired) BOOL expired;



@property (nonatomic, strong) NSURLSessionDataTask *innerTask;


@end
