//
//  ServerConfiguration.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/20.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#ifndef ServerConfiguration_h
#define ServerConfiguration_h

/**
 * 用于存放服务端的所有地址，例如总API接口、Web接口等
 */

//切换生产和测试环境
#define DistributionVersion true

#pragma mark - 生产环境
#if DistributionVersion
#define ServerURL @"http://api.server.com/..."


#pragma mark - 测试环境
#else
#define ServerURL @"http://api.test.server.com/..."

#endif

#endif /* ServerConfiguration_h */
