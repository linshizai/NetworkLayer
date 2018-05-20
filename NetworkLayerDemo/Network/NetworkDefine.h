//
//  NetworkDefine.h
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

/**
 * 用于存放具体的业务接口、加密方式定义
 */

#ifndef NetworkDefine_h
#define NetworkDefine_h

typedef NS_ENUM(NSInteger, ApiAct) {
    ApiActUndefined             = 0,   //无效的act
    ApiActSessionId             = 1,   //获取sessionId
    ApiActVerificationCode      = 2,   //发送验证码
    ApiActLogin                 = 3,   //登录
    ApiActUserInfo              = 4,   //获取用户信息
    ApiActUploadImages          = 5
    //其他业务的定义.....
};

//加密方式
typedef NS_ENUM(NSInteger, EncryptionType) {
    EncryptionTypeOrigin = 0,
    EncryptionType3DES = 2,
    EncryptionTypeRSA = 4,
};

#endif /* NetworkDefine_h */
