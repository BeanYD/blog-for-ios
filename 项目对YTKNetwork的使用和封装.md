## 项目对YTKNetwork的使用和封装

### 1.配置YTKNetwork的请求

```objective-c
/**
 配置YTKNetwork的请求
 */
- (void)ytkConfig {
  	YTKNetworkConfig *config = [YTKNetworkConfig sharedConfig];
    NSString *httpIpAddress = nil;
    
#if DEBUG
  	// 根据开发测试人员选择的环境配置ip地址
    httpIpAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"GTHttpIPAddress"];
    if (httpIpAddress.length == 0) {
        httpIpAddress = kHttpIpAddressTest;
        [[NSUserDefaults standardUserDefaults] setObject:kHttpIpAddressTest forKey:@"GTHttpIPAddress"];
    }
#else
  	// 生产包使用生产环境
    httpIpAddress = kHttpIpAddressProduction;
#endif
    
    NSArray *hostArray = @[kHttpIpAddressDevelop1,kHttpIpAddressDevelop2,kHttpIpAddressTest,kHttpIpAddressProduction,kHttpIpAddressPre];
    for (NSString *host in hostArray) {
        if ([host containsString:[httpIpAddress substringToIndex:httpIpAddress.length-2]]) {
            httpIpAddress = host;
            break;
        }
    }
    config.baseUrl = httpIpAddress;
}
```

### 2.继承YTKRequest，重写部分接口GTRequest.h和GTRequest.m文件，用于所有请求错误的统一处理，如token失效

```objective-c
#import "YTKRequest.h"
#import "YTKNetwork.h"
#import "GTHttpDefine.h"

NS_ASSUME_NONNULL_BEGIN
  
@class GTRequest;

typedef void(^httpSuccess)(id result);
typedef void(^httpFailure)(id error);

// 回调
typedef void(^GTRequestSuccessCompletionBlock)(__kindof GTRequest *request);
typedef void(^GTRequestFailureCompletionBlock)(__kindof GTRequest *request);

@interface GTRequest : YTKRequest

/**
 urlString    与baseUrl拼接的url
 method       请求方式：get/post
 argument     请求体：如@{@"name" : name, @"password" : password}
 */
- (instancetype)initWithUrlString:(NSString *)urlString
                         method:(YTKRequestMethod)method
                       argument:(id)argument;

- (instancetype)initWithMethod:(YTKRequestMethod)method;

- (void)startWithDataCompletionBlockWithSuccess:(nullable GTRequestSuccessCompletionBlock)success
                                        failure:(nullable GTRequestFailureCompletionBlock)failure;

@property (copy, nonatomic) httpSuccess success;
@property (copy, nonatomic) httpFailure failure;

@property (nonatomic, copy, nullable) GTRequestSuccessCompletionBlock successDataCompletionBlock;
@property (nonatomic, copy, nullable) GTRequestFailureCompletionBlock failureDataCompletionBlock;
@property (nonatomic, copy, nullable) NSString *jsonModelName;
/// data包含code、data、msg
@property (nonatomic, strong, readonly, nullable) id gtResponseData;
/// 只包含data的内容
@property (nonatomic, strong, readonly, nullable) id gtResponseDic;
/// 转成jsonmodel
@property (nonatomic, strong, nullable) id gtResponseModel;

+ (void)setToken:(NSString *)token;

+ (NSString *)token;

@end

NS_ASSUME_NONNULL_END
```

```objective-c
#import "GTRequest.h"
#import "GTModel.h"
#import "GTSystemConfig.h"

NSString *GTLoginPageNotification = @"GTLoginPageNotification";
NSString *apiRefreshJWT = @"datacenter/auth/refreshJwt";

@interface GTRequest()

/// 是否需要json->model
@property (nonatomic, assign) BOOL needTransformModel;
@property (nonatomic, strong, readwrite, nullable) NSDictionary *gtResponseData;
@property (nonatomic, assign) BOOL refreshAlready;

@end

@implementation GTRequest {
    NSString *_urlString;
    YTKRequestMethod _method;
    id _argument;
}

#pragma mark - init
- (instancetype)initWithUrlString:(NSString *)urlString method:(YTKRequestMethod)method argument:(id)argument {
    if (self = [super init]) {
        _urlString = urlString;
        _method = method;
        _argument = argument;
    }
    return self;
}

- (instancetype)initWithMethod:(YTKRequestMethod)method {
    if (self = [super init]) {
        _method = method;
    }
    return self;
}

#pragma mark - request
- (void)startWithDataCompletionBlockWithSuccess:(GTRequestSuccessCompletionBlock)success
                                        failure:(GTRequestSuccessCompletionBlock)failure {
    [self setDataCompletionBlockWithSuccess:success failure:failure];
    [self startRequest];
}

- (void)setDataCompletionBlockWithSuccess:(GTRequestSuccessCompletionBlock)success
                                  failure:(GTRequestSuccessCompletionBlock)failure {
    self.successDataCompletionBlock = success;
    self.failureDataCompletionBlock = failure;
}

- (void)startRequest {
    [self startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSDictionary *dict = nil;
        if ([request.responseJSONObject isKindOfClass:[NSDictionary class]]) {
            dict = request.responseJSONObject;
            self.gtResponseData = dict;
        }
        
        if (self.refreshAlready) {
            self.refreshAlready = NO;
        }
        
        if (self.successDataCompletionBlock) {
            GTRequest *gtRequest = request;
            self.successDataCompletionBlock(gtRequest);
        }
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSInteger statusCode = request.response.statusCode;
        
        if (statusCode==401) {
            // go login page
            [[NSNotificationCenter defaultCenter] postNotificationName:GTLoginPageNotification object:@{@"kickoff":@(YES)}];
            [GTRequest setToken:@""];
            //[self refreshJWT];
        }else {
            if (self.failureDataCompletionBlock) {
                GTRequest *gtRequest = request;
                self.failureDataCompletionBlock(gtRequest);
                NSString *message = @"";
#if DEBUG
                NSString *httpIpAddress = [[NSUserDefaults standardUserDefaults] valueForKey:@"GTHttpIPAddress"];
                if (![httpIpAddress isEqualToString:kHttpIpAddressProduction]) {
                    message = [NSString stringWithFormat:@"错误接口：%@\n错误代码%ld",request.requestUrl,(long)request.response.statusCode];
                }

#else
                //message = @"服务器繁忙，请稍后重试！";
#endif
                if (message.length > 0) {
                    [[UIApplication sharedApplication].keyWindow makeToast:message];
                }
            }
        }
    }];
}

#pragma mark - refreshJWT

- (void)refreshJWT {
    GTRequest *api = [[GTRequest alloc] initWithUrlString:apiRefreshJWT method:YTKRequestMethodPOST argument:@{}];
    [api startWithCompletionBlockWithSuccess:^(__kindof YTKBaseRequest * _Nonnull request) {
        NSLog(@"");
    } failure:^(__kindof YTKBaseRequest * _Nonnull request) {
    }];
}

#pragma mark - private data
- (id)gtResponseDic {
    NSDictionary *dic;
    if ([_gtResponseData objectForKey:@"result"]) {
        dic = [_gtResponseData objectForKey:@"result"];
    }
    if (dic) {
        if ([dic isKindOfClass:[NSString class]] && ((NSString *)dic).length == 0) {
            dic = [NSDictionary dictionary];
        }
        return dic;
    }else {
        return _gtResponseData;
    }
}

- (id)gtResponseModel {
    if (_needTransformModel && _jsonModelName.length > 0) {
        id object = nil;
        if ([self.gtResponseDic isKindOfClass:[NSDictionary class]]) {
            object = [NSClassFromString(_jsonModelName) JSONModelWithKeyValues:self.gtResponseDic];
        }
        else if ([self.gtResponseData isKindOfClass:[NSDictionary class]]) {
            object = [NSClassFromString(_jsonModelName) JSONModelWithKeyValues:self.gtResponseData];
        }
        return object;
    }
    return nil;
}

- (void)setJsonModelName:(NSString *)jsonModelName {
    if (jsonModelName && jsonModelName.length > 0) {
        _jsonModelName = jsonModelName;
        _needTransformModel = YES;
    }
    else {
        _needTransformModel = NO;
    }
}

#pragma mark - overwrite

// 需要与baseUrl拼接的地址
- (NSString *)requestUrl {
    return _urlString;
}

// 请求方法
- (YTKRequestMethod)requestMethod {
    return _method;
}

// 请求体
- (id)requestArgument {
    return _argument;
}

// 请求头配置
- (NSDictionary<NSString *,NSString *> *)requestHeaderFieldValueDictionary {
    NSDictionary *headerFieldDic = [NSMutableDictionary dictionary];
    NSString *userPhoneNameStr = [[UIDevice currentDevice] name];// 手机名称
    NSString *systemVersionStr = [[UIDevice currentDevice] systemVersion];// 手机系统版本号
    NSString *deviceNameStr = [[UIDevice currentDevice] systemName];// 手机系统名称
//    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];// app版本
    
    if ([GTRequest token].length > 0) {
        [headerFieldDic setValue:[GTRequest token] forKey:@"authorization"];
    }
    if ([GTSystemConfig userLanguage].length == 0) {
        [GTSystemConfig setUserLanguage:@"zh-Hans"];
    }
 		// TODO:设置请求头相关数据
    
    switch (_method) {
        case YTKRequestMethodGET:
            [headerFieldDic setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forKey:@"content-type"];
            break;
        case YTKRequestMethodPOST:
        case YTKRequestMethodPUT:
            [headerFieldDic setValue:@"application/json;charset=UTF-8" forKey:@"content-type"];
            break;
        default:
            break;
    }
    return headerFieldDic;
}

- (YTKRequestSerializerType)requestSerializerType {
    return YTKRequestSerializerTypeJSON;
}

- (YTKResponseSerializerType)responseSerializerType {
    return YTKResponseSerializerTypeJSON;
}

+ (void)setToken:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setValue:token forKey:kJWTTokenKey];
}

+ (NSString *)token {
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJWTTokenKey];
}
```

### 3.各个模块单独继承GTRequest，用于模块调用。GTTestApi

```objective-c
#import "GTRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GTTestAPIType) {
  	GTTestAPITypeTest,
		...
};

// 登录
static NSString *apiTest = @"...";


@interface GTLoginAPI : GTRequest

/**
 init

 @param dictionary 参数
 @param type GTLoginAPIType
 @param method requsetMethod
 @return instance
 */
- (instancetype)initWithDict:(NSDictionary *)dictionary andType:(GTTestAPIType)type andMethod:(YTKRequestMethod)method;

@end

NS_ASSUME_NONNULL_END
```

```objective-c

#import "GTTestAPI.h"
#import "GTHttpDefine.h"


@interface GTTestAPI() {
    NSDictionary *_dict;
    NSInteger _type;
}
@end

@implementation GTTestAPI

- (instancetype)initWithDict:(NSDictionary *)dictionary andType:(GTTestAPIType)type andMethod:(YTKRequestMethod)method {
    if (self = [super initWithMethod:method]) {
        _dict = dictionary;
        _type = type;
    }
    return self;
}


- (NSString *)requestUrl {
    NSString *url = nil;
    switch (_type) {
        case GTTestAPITypeTest:
            url = apiTest;
            break;
        ...
    }
    return url;
}

- (id)requestArgument {
    return _dict;
}

@end
```

### 4.调用实例

```objective-c
- (void)requestWithParam1:(NSString *)param1 param2:(NSString *)param2 {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:param1 forKey:@"param1"];
    [params setValue:param2 forKey:@"param2"];
    
    GTTestApi *testApi = [[GTTestApi alloc] initWithDict:params andType:GTTestAPITypeTest andMethod:YTKRequestMethodPOST];
    testApi.jsonModelName = NSStringFromClass([GTTestModel class]);
    
    GTProgressHUD *hud = [GTProgressHUD HUDWithParentView:self.view];
    [testApi startWithDataCompletionBlockWithSuccess:^(__kindof GTRequest *request) {
        [hud hideProcessHUD];
        NSString *codeString = request.gtResponseData[@"code"];
        // TODO:请求成功处理
    } failure:^(__kindof GTRequest *request) {
        [hud hideProcessHUD];
        NSLog(@"%@", request.error);
    }];
}
```

