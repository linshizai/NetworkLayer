//
//  RequestSerializer.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "NetworkDefine.h"

@interface RequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) ApiAct act;

@end