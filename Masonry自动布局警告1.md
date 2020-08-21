### 使用Masonry过程中，消除autolayout的冲突

#### 1.场景：

​	继承自UIView的自定义customView，重写了两个初始化方法，使用masonry进行自动布局。在viewController中懒加载customView，调用了init方法。

```objective-c
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    
    return self;
}
- (instancetype)init {
    if (self = [super init]) {
	[self configUI];
    }
    
    return self;
}
- (void)configUI {
  // Masonry布局
  ...
}
```

​	问题: 报如下警告，且经过调试，发现出现警告的时候，customView的frame大小是没有的

```objective-c
GeelyTravel[25638:1054131] [LayoutConstraints] Unable to simultaneously satisfy constraints.
 Probably at least one of the constraints in the following list is one you don't want. 
 Try this: 
  (1) look at each constraint and try to figure out which you don't expect; 
  (2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<MASLayoutConstraint:0x600003da0000 GTIgnoreHighLightButton:0x7f9f06cf2bd0.left == GTAirTicketChoosePathView:0x7f9f06cc4f80.left + 16>",
    "<MASLayoutConstraint:0x600003da09c0 GTIgnoreHighLightButton:0x7f9f06c00940.right == GTAirTicketChoosePathView:0x7f9f06cc4f80.right - 16>",
    "<MASLayoutConstraint:0x600003d839c0 UIButton:0x7f9f06ca1fd0.left == GTIgnoreHighLightButton:0x7f9f06cf2bd0.left>",
    "<MASLayoutConstraint:0x600003d834e0 UIButton:0x7f9f06ca1fd0.right == GTIgnoreHighLightButton:0x7f9f06c00940.right>",
    "<NSLayoutConstraint:0x600003afcaa0 GTAirTicketChoosePathView:0x7f9f06cc4f80.width == 0>"
)
```

​	可以直接在懒加载中调用initWithFrame:方法，并添加相应的frame值。

​	衍生问题：上述两个初始化方法中，我只在init中添加了configUI方法。在调用initWithFrame:时发现，无法进入configUI方法。	

​	在initWithFrame:中添加configUI。删除init方法

```objective-c
// customView相关代码
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configUI];
    }
    
    return self;
}

- (void)configUI {
  // Masonry布局
  ...
}
```

```objective-c
// controllerView懒加载相关代码
- (CustomView *)customView {
    if (!_customView) {
        _customView = [[CustomView alloc] initWithFrame:...];
        _customView.backgroundColor = UIColorFromRGB(0xFFFFFF);
    }
    
    return _customView;
}
```

#### 总结：

customView的调用Masonry布局时，由于init方法会自动调用initWithFrame:方法，加载的时候customView的frame为CGRectZero，导致Masonry进行自动布局时，无法根据父视图的frame大小进行布局，就会报警告。后续对customView的frame进行添加时，还是可以显示正常的。
