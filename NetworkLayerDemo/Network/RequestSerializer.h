//
//  RequestSerializer.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "NetworkDefine.h"

/**
 * 自定义请求数据的解析，继承自AFHTTPRequestSerializer
 */

@interface RequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) ApiAct act;

@end
