//
//  ResponseSerializer.m
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import "ResponseSerializer.h"

@implementation ResponseSerializer

#pragma mark - override
+ (instancetype)serializer {
    return [self serializerWithReadingOptions:NSJSONReadingMutableLeaves|NSJSONReadingMutableContainers];
}
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.acceptableContentTypes  = [NSSet setWithObjects:@"text/html",@"text/json", @"text/javascript",@"application/json",nil];
    return self;
}

static NSInteger headerLength = 32;
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {

    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:" " length:1]];
    if (isSpace && data.length < headerLength) {
        return nil;
    }

    //解析包头数据
    NSDictionary *headerInfo = [self decodeHeaderData:data];
    if ([headerInfo[@"result"] integerValue] != 0) {
        return headerInfo;
    }

    //解密包体数据，从32位开始
    NSData *jsonData = [data subdataWithRange:NSMakeRange(headerLength, [headerInfo[@"bodyLength"] integerValue])];
    NSInteger encryptType = [headerInfo[@"encryptType"] integerValue];
    if (encryptType == 2) { //3DES
//        jsonData = [EncryptManager tripleDesDecryptData:jsonData];
    } else if (encryptType == 4){ //RSA
//        jsonData = [EncryptManager rsaDecryptData:jsonData];
    } else {
        //do nothing
    }
    return [super responseObjectForResponse:response data:jsonData error:error];
}


#pragma mark - 对包头数据进行解码
- (NSDictionary *)decodeHeaderData:(NSData *)data {
    if (data.length < headerLength) {
        return nil;
    }
    unsigned char *ptr = (unsigned char *)[data bytes];

    //包体长度 2~5
    NSUInteger length = 0;
    for (int i=2; i<6; i++) {
        length = (length << 8) + ptr[i];
    }

    //加密方式 6
    NSUInteger encryptType = ptr[6];

    //错误码 7~10
    NSInteger errorCode = 0;
    for (int i=7; i<11; i++) {
        errorCode = (errorCode << 8) + ptr[i];
    }

    return @{@"result":@(errorCode),
             @"bodyLength":@(length),
             @"encryptType":@(encryptType),
             @"msg":[self msgByErrorCode:errorCode]};
}


- (NSString *)msgByErrorCode:(NSInteger)errorCode {
    static NSDictionary *msgDic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        msgDic = @{
                   @(0):@"成功",
                   @(1):@"数据包头错误",
                   @(2):@"数据流或者通信出错（数据包体错误",
                   @(3):@"数据解密失败（3des)",
                   @(4):@"无效的协议版本号",
                   @(5):@"无效的加密方式",
                   @(6):@"发送的请求数据长度太长",
                   @(7):@"未知的服务器错误",
                   @(8):@"SessionID无效",
                   @(9):@"无效的接口编号(Act)",
                   @(10):@"接口已经停用，需要升级客户端"
                   };
    });

    return msgDic[@(errorCode)]?:[NSString stringWithFormat:@"%@,%@",@"未知错误",@(errorCode)];
}

@end
