# NetworkLayer
一个安全的网络层设计，包含了整个请求流程，接口加密的逻辑。可作为安全性要求较高的网络层的参考使用。

##### 说明
- Demo中的RSA解密和加密用的密钥对，为了测试方便先直接保存本地。
- Demo的`密钥管理模块`由于一些原因未能公开，只提供了伪代码，后面会补上。
- 该Demo只作为一种网络加密请求的方案，给出客户端的关键代码。
- 服务端API Demo暂时还没有，等学完Go语言搭个Web服务器进行模拟，到时候就会给出完整的CS通信Demo。

## Demo目标功能
- [x] 基于RSA和3DES混合的加密机制。
- [x] Session会话过期机制。
- [x] 业务接口以业务的数字编号来区分，
- [x] 网络请求任务并发数设置。
- [x] 请求失败后的重试次数设置，失败多次后的任务挂起时间的设置。
- [  ]RSA的公钥失效后向服务端申请新Key。

## Class文件说明
- Network：网络请求总入口（Session会话的管理、网络请求的管理、失败重试机制及简单的请求保护措施）
- SessionTask：单次请求任务封装
- RequestSerializer：  自定义请求数据的解析，继承自AFHTTPRequestSerializer
- ResponseSerializer：自定义响应数据的解析，继承自AFJSONResponseSerializer
- ServerConfiguration：服务端地址的管理和切换
- NetworkDefine：接口编号的枚举、加密方式的枚举等

## 关键代码说明

- RequestSerializer：自定义请求解析器。根据与服务端的协议，按位右移进行字节拼接。
- ResponseSerializer：自定义响应解析器。根据与服务端的协议，按位左移进行字节读取。


## 流程图示

### 整体流程
![Alt text](https://upload-images.jianshu.io/upload_images/5076132-8cbe10dc027e80ec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 建立会话流程
![Screen Shot 2018-05-20 at 22.08.07.png](https://upload-images.jianshu.io/upload_images/5076132-4cfe516050c49b8d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 建立HTTP请求流程
![Screen Shot 2018-05-20 at 22.08.27.png](https://upload-images.jianshu.io/upload_images/5076132-5e9eb7cdc30e8365.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



