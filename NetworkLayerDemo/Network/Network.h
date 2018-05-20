//
//  Network.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionTask.h"

/**
 * 网络请求的总入口
 * 1. Session会话的管理
 * 2. 网络请求的管理
 * 3. 失败重试机制及简单的请求保护措施
 * 4. 一个业务请求对应一个SessionTask
 */

@interface Network : NSObject
@end

@interface Network (Encrypt)

/**
 *  请求SessionId
 *
 *  @note 本地已有sessionId，则什么都不做
 *  @note 每次业务请求的包头都要带上sessionId
 */

+ (void)requestSessionIfNeeded;
+ (NSString *)sessionId;


/**
 *  通过接口编号请求接口
 *
 *  @param act        接口编号或者接口动作
 *  @param parameters 业务参数
 *  @param success    成功回调
 *  @param fail       失败回调
 */
+ (id<SessionTask>)postJSONWithAct:(ApiAct)act parameters:(id)parameters success:(void (^)(id json))success fail:(void (^)(void))fail;

@end

@interface Network (Other)

/**
 *  上传图片
 *
 *  @param images  图片数组
 *  @param success 成功回调
 *  @param fail    失败回调
 */
+ (id<SessionTask>)uploadImages:(NSArray *)images success:(void (^)(id json))success fail: (void (^)(void))fail;

/**
 *  下载文件
 *
 *  @param url               url字符串或者NSURL
 *  @param filePath          将文件下载路径，可传nil
 *  @param completionHandler 完成回调
 */
+ (void)downloadFileWithURL: (id)url
                   filePath: (NSString *)filePath
          completionHandler:(void (^)(NSURLResponse *response, NSURL *fileURL, NSError *error))completionHandler;

@end

