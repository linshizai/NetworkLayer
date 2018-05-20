//
//  RequestSerializer.m
//  NetworkLayerDemo
//
//  Created by 打不死的林小强 on 2018/5/19.
//  Copyright © 2018 打不死的林小强. All rights reserved.
//

#import "RequestSerializer.h"
#import "NetworkDefine.h"

@implementation RequestSerializer

#pragma mark - override

//重写NSURLRequest请求体
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableURLRequest *mutableRequest = [super requestBySerializingRequest:request withParameters:parameters error:error].mutableCopy;

    NSData *packetData = [self packetDataWithParameters:parameters];

    //所有数据都是存放在包体中
    [mutableRequest setHTTPBody:packetData];
    return mutableRequest;
}

#pragma mark - 添加包体的数据
- (NSData *)packetDataWithParameters:(id)parameters {
    NSData *bodyData = nil;

    if (self.act == ApiActUploadImages) { //特殊业务要求，例如图片上传必须经过压缩处理

    } else {
        NSString *base64String = @"parameters -> Base64";
        EncryptionType encryptionType = [self encryptionTypeByAct:self.act];
        switch (encryptionType) {
            case EncryptionTypeOrigin: {
                bodyData = [base64String dataUsingEncoding:NSUTF8StringEncoding];
                break;
            }
            case EncryptionType3DES: {
                //@"base64String -> UTF8 -> 3DES加密"
//                [EncryptManager tripleDESEncryptData:[base64String dataUsingEncoding:NSUTF8StringEncoding]];
                break;
            }
            case EncryptionTypeRSA: {

                //@"base64String -> UTF8 -> RSA加密";
//                bodyData = [EncryptManager rsaEncryptData:[base64String dataUsingEncoding:NSUTF8StringEncoding]];
                break;
            }
        }
    }
    return [self packetDataWithBodyData:bodyData];
}

#pragma mark - 添加包头的数据
//根据与服务端的协议，按位进行字节拼接
- (NSData *)packetDataWithBodyData:(NSData *)bodyData {
    unsigned char *packetHeader = (unsigned char*)malloc(64);
    memset(packetHeader, 0, 64);

    //0~1 预留
    NSInteger ran = arc4random()%10000+20001;
    packetHeader[0] = ran >> 8 & 0xff;
    packetHeader[1] = ran & 0xff;

    //2~5 包体长度
    NSInteger bodyLength = [bodyData length];
    for (int i=0; i<4; i++) {
        packetHeader[2+i] = bodyLength >> (3-i)*8 & 0xff;
    }

    //6~7 App版本号
    packetHeader[7] = 1;

    //8~9 API接口编号，act
    packetHeader[8] = self.act >> 8 & 0xff;
    packetHeader[9] = self.act & 0xff;

    //10~41 sessionId
    NSString *sessionId = @"取得id";
    if (sessionId) {
        NSData *data = [sessionId dataUsingEncoding:NSUTF8StringEncoding];
        memcpy(packetHeader+10, data.bytes, 32);
    }

    //42 加密方式
    //43~63 系统保留，空
    packetHeader[42] = [self encryptionTypeByAct:self.act];

    NSData *headerData = [NSData dataWithBytes:packetHeader length:64];
    free(packetHeader);

    //最后的拼接过程
    NSMutableData *packetData = [NSMutableData data];
    [packetData appendData:headerData];
    [packetData appendData:bodyData];

    return packetData;
}

#pragma mark - helper
- (EncryptionType)encryptionTypeByAct:(ApiAct)act {
    EncryptionType encryptionType = 0;
    switch (act) {
        case ApiActSessionId: //当请求sessionId，整个过程是不加密的
        case ApiActUploadImages:{
            encryptionType = EncryptionTypeOrigin;
            break;
        }
        default:
            encryptionType = EncryptionType3DES;
    }
    return encryptionType;
}

@end
