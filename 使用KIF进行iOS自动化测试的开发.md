### 使用KIF进行iOS自动化测试的开发

原理：

基于ID来识别视图元素，然后私有API模仿用户的交互操作（使用代码触发点击、滑动、输入等），从而实现UI的测试。 官方推荐的ID设置是基于accessibilityLabel，它是用于TouchOver（旁白）盲人辅助功能的可本地化的视图ID，给一个视图设置ID，TouchOver就能读出该ID，从而帮助盲人识别视图。从另一个角度讲，这个ID一定程度是用户可见的。（一般搭配 accessibilityHint 、accessibilityTraits使用） 实践中比较方便的ID设置是基于accessibilityIdentifier，专门用来标识UI元素的ID，用户不可见。 

使用:

添加测试TARGETS:

![image-20190815105602315](/Users/dingbinbin/Library/Application Support/typora-user-images/image-20190815105602315.png)

cocoapods引入KIF框架

```objective-c
target 'GeelyTravelTests' do
  pod 'KIF', :configurations => ['Debug']
  pod 'KIF/IdentifierTests', :configurations => ['Debug']
end

target 'GeelyTravelUITests' do
  pod 'KIF', :configurations => ['Debug']
end
```



API  KIFUITestActor及其扩展类KIFUITestActor+IdentifierTests

等待视图出现（获取视图） 、点击视图、滑动、拖动、输入、清空输入、设置进度条等

```objective-c
- (UIView *)waitForViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)tapViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)tapRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;
- (void)tapItemAtIndexPath:(NSIndexPath *)indexPath inCollectionViewWithAccessibilityIdentifier:(NSString *)identifier;
```



方法使用举例

```objective-c
#import <XCTest/XCTest.h>

@interface GTLoginTests : KIFTestCase

@end

@implementation GTLoginTests

- (void)beforeAll {
    // 所有测试用例执行前
}

- (void)beforeEach {
    // 每个测试用例执行前
}

- (void)afterAll {
    // 所有测试用例执行后
}

- (void)afterEach {
    // 每个测试用例执行后
}

- (void)testLoginAccountExample {
    // TODO:切换环境
    
    // 登录
    if ([tester tryFindingViewWithAccessibilityLabel:@"Login account enter" error:nil]) {
        [tester clearTextFromAndThenEnterText:@"18268731130" intoViewWithAccessibilityLabel:@"Login account enter"];
        [tester clearTextFromAndThenEnterText:@"888888" intoViewWithAccessibilityLabel:@"Login password enter"];
        [tester tapViewWithAccessibilityLabel:@"登录"];
        [[tester usingTimeout:15] waitForViewWithAccessibilityLabel:@"机票"];
        NSLog(@"test--测试环境 登录成功");
    } else {
        NSLog(@"test--状态：已登录");
    }
    
}

@end
```

```objective-c
#import <XCTest/XCTest.h>

@interface GTHomePageTests : KIFTestCase

@end

@implementation GTHomePageTests

- (void)beforeAll {
    // 登录
    if ([tester tryFindingViewWithAccessibilityLabel:@"Login account enter" error:nil]) {
        [tester clearTextFromAndThenEnterText:@"18268731130" intoViewWithAccessibilityLabel:@"Login account enter"];
        [tester clearTextFromAndThenEnterText:@"888888" intoViewWithAccessibilityLabel:@"Login password enter"];
        [tester tapViewWithAccessibilityLabel:@"登录"];
        [[tester usingTimeout:15] waitForViewWithAccessibilityLabel:@"机票"];
        NSLog(@"test--测试环境 登录成功");
    } else {
        NSLog(@"test--状态：已登录");
    }
}

- (void)afterAll {
    
}

- (void)beforeEach {
    
}

- (void)afterEach {
    
}

#pragma mark - 个人模式测试模块
- (void)testHomePageAirTicketPersonalExample {
    // 引导页测试
    if ([tester tryFindingViewWithAccessibilityLabel:@"我知道了" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"我知道了"];
        NSLog(@"test--已点击引导页");
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"代订模式" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"代订模式"];
        NSLog(@"test--已转换为个人模式");
    }
    
    [tester tapViewWithAccessibilityLabel:@"机票"];
    NSLog(@"test--已选择机票业务");
    
    // 差规界面测试
    if ([tester tryFindingViewWithAccessibilityLabel:@"Scene select view" error:nil]) {
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Scene table view"];
        [tester tapViewWithAccessibilityLabel:@"确定"];
        NSLog(@"test--已选择场景");
    }
        
    [[tester usingTimeout:10] waitForViewWithAccessibilityLabel:@"机票预订"];
    NSLog(@"test--已进入机票预订界面");
}


#pragma mark - 代订模式测试模块

@end
```

