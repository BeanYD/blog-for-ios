### ProgressReporting协议

iOS11提供了`NSProcessReporting`协议，NSURLSessionTask实现了协议

```objective-c
API_AVAILABLE(macos(10.9), ios(7.0), watchos(2.0), tvos(9.0))
@interface NSURLSessionTask : NSObject <NSCopying, NSProgressReporting>
/*
 * NSProgress object which represents the task progress.
 * It can be used for task progress tracking.
 */
@property (readonly, strong) NSProgress *progress API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0));
```

能获得`NSProcess`对象，该对象是只读的，描述如下：

```objective-c
/* If your class supports reporting progress, then you can adopt the NSProgressReporting protocol. Objects that adopt this protocol should typically be "one-shot" -- that is, the progress is setup at initialization of the object and is updated when work is done. The value of the property should not be set to another progress object. Instead, the user of the NSProgressReporting class should create a new instance to represent a new set of work.
 */
@protocol NSProgressReporting <NSObject>
@property (readonly) NSProgress *progress;
@end
```

`NSProcess`对象拥有以下方法被调用后，`task`对象的状态也会发生变更，两者进行了双向绑定：

```objective-c
/* Invoke the block registered with the cancellationHandler property, if there is one, and set the cancelled property to YES. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
*/
- (void)cancel;

/* Invoke the block registered with the pausingHandler property, if there is one, and set the paused property to YES. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
*/
- (void)pause;

/* Invoke the block registered with the resumingHandler property, if there is one, and set the paused property to NO. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
*/
- (void)resume API_AVAILABLE(macos(10.11), ios(9.0), watchos(2.0), tvos(9.0));
```

在获取进度方面，在`NSProcess`类上方有这样一段话：

```objective-c
/* The localizedDescription and localizedAdditionalDescription properties are meant to be observed as well as set. So are the cancellable and pausable properties. totalUnitCount and completedUnitCount on the other hand are often not the best properties to observe when presenting progress to the user. For example, you should observe fractionCompleted instead of observing totalUnitCount and completedUnitCount and doing your own calculation. NSProgress' default implementation of fractionCompleted does fairly sophisticated things like taking child NSProgresses into account.
*/
```

**totalUnitCount and completedUnitCount on the other hand are often not the best properties to observe when presenting progress to the user，**利用`totalUnitCount`和`completedUnitCount`在某些方面并不一定是标准的进度，后面举了一个例子，如果有子文件的。`NSReProcessReporting`的协议中，`NSProcess`对象可以以0-1.0的方式告诉我们当前进度，不再需要自己去拿已获得的数据量除以需要获得的数据总量，因为有时候并不一定能拿到数据总量。

```objective-c
#pragma mark *** Reporting Progress ***

/* The size of the job whose progress is being reported, and how much of it has been completed so far, respectively. For an NSProgress with a kind of NSProgressKindFile, the unit of these properties is bytes while the NSProgressFileTotalCountKey and NSProgressFileCompletedCountKey keys in the userInfo dictionary are used for the overall count of files. For any other kind of NSProgress, the unit of measurement you use does not matter as long as you are consistent. The values may be reported to the user in the localizedDescription and localizedAdditionalDescription.
 
   If the receiver NSProgress object is a "leaf progress" (no children), then the fractionCompleted is generally completedUnitCount / totalUnitCount. If the receiver NSProgress has children, the fractionCompleted will reflect progress made in child objects in addition to its own completedUnitCount. As children finish, the completedUnitCount of the parent will be updated.
*/
```

从上文中可以知道，`NSProcess`的进度可以在`NSProcess`的`userInfo`中获取，`key`为`NSProgressFileTotalCountKey`和`NSProgressFileCompletedCountKey`。



而标准的`NSProcess`进度需要在`localizedDescription`和`localizedAdditionalDescription`中获取，`localizedAdditionalDescription`比`localizedDescription`更加具体。两者皆为`NSProcess`的属性

```objective-c
/* A description of what progress is being made, fit to present to the user. NSProgress is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then NSProgress uses the value of the kind property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string.
  
  For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
    Copying 10 files…
    30% completed
    Copying “TextEdit”…
*/
@property (null_resettable, copy) NSString *localizedDescription;

/* A more specific description of what progress is being made, fit to present to the user. NSProgress is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then NSProgress uses the value of the kind property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string. The difference between this and localizedDescription is that this text is meant to be more specific about what work is being done at any particular moment.

   For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
    3 of 10 files
    123 KB of 789.1 MB
    3.3 MB of 103.92 GB — 2 minutes remaining
    1.61 GB of 3.22 GB (2 KB/sec) — 2 minutes remaining
    1 minute remaining (1 KB/sec)

*/
@property (null_resettable, copy) NSString *localizedAdditionalDescription;
```

调用方法：

```objective-c
NSLog(@"%@", task.progress.localizedDescription);
NSLog(@"%@", task.progress.localizedAdditionalDescription);
```

### 进行多路多协议的网络操作（Multipath Protocols for Mobile Devices）

NSURLSessionConfiguration属性：

```objective-c
/* multipath service type to use for connections.  The default is NSURLSessionMultipathServiceTypeNone */
@property NSURLSessionMultipathServiceType multipathServiceType API_AVAILABLE(ios(11.0)) API_UNAVAILABLE(macos, watchos, tvos);
```

Handover Mode（高可靠模式）

这种模式下优先考虑的是链接的可靠性。只有在Wi-Fi信号不好的时候，流量才会走Cellular。如果Wi-Fi信号好，但是Wi-Fi很慢，这时候也不会切到Cellular链路。

Interactive Mode（低延时模式）

这种模式下优先考虑的是链接的低延时。系统会看Wi-Fi快还是Cellular快。如果Cellular比Wi-Fi快，哪怕此时Wi-Fi信号很好，系统也会把流量切到Cellular链路。

Aggregation Mode（混合模式）

在这种模式下，Wi-Fi和Cellular会同时起作用。如果Wi-Fi是1G带宽，Cellular也是1G带宽，那么你的设备就能享受2G带宽。无法在生产环境使用。

### Network Extension Framework的新API

两个新类：`NEHotSpotConfiguration`、`NEDNSProxyProvider`

`NEHotSpotConfigutation`可以直接在app内进行热点的连接，不用切换到设置中去操作。

```objective-c
// 头文件包含
#import <NetworkExtension/NEHotspotConfigurationManager.h>

// 具体实现代码，其他接口阅读官方文档
NEHotspotConfiguration *pwdConfig = [[NEHotspotConfiguration alloc] initWithSSID:@"wifi名称" passphrase:@"wifi密码" isWEP:NO];

NEHotspotConfiguration *noPwdConfig = [[NEHotspotConfiguration alloc] initWithSSID:@"wifi名称"];
		
	
[[NEHotspotConfigurationManager sharedManager] applyConfiguration:pwdConfig completionHandler:^(NSError * _Nullable error) {
			
	
}];
```

`NEDNSProxyProvider`可以用来设置你的手机如何跟`DNS`做交互。你可以自己发`DNS`请求，也可以自己基于不同的协议去做`DNS`查询。例如`DNS over TLS`，`DNS over HTTP`。

