#### 问题：

整个app不知从哪个版本开始，所有的UIScrollView，以及UIScrollView的子类，滚动减速时，全部会卡，用YYFPSLabel检测时，基本处于53FPS左右。

#### 问题排查过程：

一开始完全没思路，天马星空地去想

- 写个新的`tableview`，添加最简单的`tableview`，滚动，仍然卡顿，排除页面变高，图片加载的影响。

- 找了`UIViewController`的分类，并删除后，仍然卡顿。

- 对着屏幕思考许久。

- 找了郭YY大神的流畅的一匹的`tableviewdemo`看看。

- 手机上看到消息，切换app回复后，切回该app，发现卡顿的问题好了，全程60fps（好像找到了问题），但是仅此而已，还是想不出问题所在。

- 由于业务量不是很大，也没进行组件化，只能使用最笨的办法，本地删除所有业务代码，`common`文件夹下的文件和新写的最简单的`tableview`

    ![截屏2020-04-17下午3.21.42](/Users/dingbinbin/Desktop/截屏2020-04-17下午3.21.42.png)

- 一个个删除`Vendors`下的第三方库

    ![截屏2020-04-17下午3.25.37](/Users/dingbinbin/Desktop/截屏2020-04-17下午3.25.37.png)

- 直到`UMVisualSDK`删除后，fps才回复正常

    ![截屏2020-04-17下午3.27.29](/Users/dingbinbin/Desktop/截屏2020-04-17下午3.27.29.png)

- 最后定位到UMVisual的库引起了整个app的`UIScrollView`卡顿的问题

由此，定位了一整天的bug终于得到了修复