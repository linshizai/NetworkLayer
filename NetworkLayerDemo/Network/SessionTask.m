//
//  SessionTask.m
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import "SessionTask.h"
#import "Network.h"

@interface SessionTask ()

@end

@implementation SessionTask

- (BOOL)isExpired {
    return [[NSDate date] timeIntervalSinceDate:self.date] > 60;
}

+ (instancetype)taskWithAct:(ApiAct)act params:(id)params success:(void(^)(id json))success fail:(void(^)(void))fail {
    SessionTask *task = [[self alloc] init];
    task.date = [NSDate date];
    task.act = act;
    task.params = params;
    task.success = success;
    task.fail = fail;
    return task;
}

- (void)resume {
    if (self.canceled) {
        return;
    }

    if (!self.isExpired) {
        [Network postJSONWithAct:self.act parameters:self.params success:self.success fail:self.fail];
    } else{
        if (self.success) {
            self.success(@{@"result":@(408),@"msg":@"任务超时"});
        }
    }
}


- (void)cancel {
    self.canceled = YES;
    if (self.innerTask) {
        [self.innerTask cancel];
        self.innerTask = nil;
    }
}

@end
