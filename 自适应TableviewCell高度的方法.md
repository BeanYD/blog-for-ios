# 自适应TableviewCell高度的方法

### 1.利用iOS8的新特性+Masonry（非xib版本），适合小数据量加载时使用

两行代码设置高度自适应：

```objective-c
    self.tableView.estimatedRowHeight = 44;
  	self.tableView.rowHeight = UITableViewAutomaticDimension;	// 高度自适应——默认，可不设置
```

创建一个tableview：

```objective-c
- (void)configUI {
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44;
    self.tableView.mj_header.hidden = YES;
    self.tableView.mj_footer.hidden = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[GTBaggageInsTableViewCell class] forCellReuseIdentifier:@"GTBackageInsTableViewCellId"];
    [self.tableView registerClass:[GTRefoundChangeInsHeaderView class] forHeaderFooterViewReuseIdentifier:@"GTRefoundChangeInsHeaderViewId"];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(8);
        make.right.equalTo(self.view).offset(-8);
        make.top.equalTo(self.view).offset(15);
        make.bottom.equalTo(self.view).offset(-15);
    }];
}
```

实现代理时，不需要实现\- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

自定义tableViewCell:

```objective-c
#import "GTBaggageInsTableViewCell.h"
#import "GTTicketChangePolicyModel.h"

@interface GTBaggageInsTableViewCell()

@property (strong, nonatomic) UILabel *baggageLabel;

@end

@implementation GTBaggageInsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self configUI];
    }
    
    return self;
}

- (void)bindDataWithModel:(id)model {
    // TODO:绑定数据
}

- (void)configUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.baggageLabel];
    [self.baggageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.contentView).offset(7);
        make.bottom.equalTo(self.contentView).offset(-7);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - lazy load
- (UILabel *)baggageLabel {
    if (!_baggageLabel) {
        _baggageLabel = [[UILabel alloc] init];
        _baggageLabel.textColor = UIColorFromRGBA(0x000000, 0.8);
        _baggageLabel.textAlignment = NSTextAlignmentLeft;
        _baggageLabel.font = [UIFont systemFontOfSize:14.];
        _baggageLabel.numberOfLines = 0;
    }
    
    return _baggageLabel;
}
```



### 2.加载前提前计算后高度缓存在model中，大数据量下使用，性能较好

先通过数据计算子控件的高度、宽度

计算高度、宽度方法类

GTFrameTool.h

```objective-c
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GTFrameTool : NSObject

/**
  根据宽度求高度
  @param text 计算的内容
  @param width 计算的宽度
  @param font font字体大小
  @return 放回label的高度
  */

+ (CGFloat)getLabelHeightWithText:(NSString *)text width:(CGFloat)width font:(CGFloat)font;

/**
  根据高度求宽度
  @param text 计算的内容
  @param height 计算的高度
  @param font font字体大小
  @return 返回Label的宽度
  */

+ (CGFloat)getWidthWithText:(NSString *)text height:(CGFloat)height font:(CGFloat)font;

/**
  根据高度求宽度
  @param text 计算的内容
  @param height 计算的高度
  @param font font  粗体字体大小
  @return 返回Label的宽度
  */
+ (CGFloat)getWidthWithText:(NSString *)text height:(CGFloat)height boldFont:(CGFloat)font;


/**
 计算frame

 @param text 文字
 @param font 字体
 @return frame
 */
+ (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font;

@end

NS_ASSUME_NONNULL_END
```

GTFrameTool.m

```objective-c
#import "GTFrameTool.h"

@implementation GTFrameTool

/**
  根据宽度求高度
  @param text 计算的内容
  @param width 计算的宽度
  @param font font字体大小
  @return 放回label的高度
  */

+ (CGFloat)getLabelHeightWithText:(NSString *)text width:(CGFloat)width font:(CGFloat)font {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]} context:nil];
    return rect.size.height;
}
/**
  根据高度求宽度
  @param text 计算的内容
  @param height 计算的高度
  @param font font字体大小
  @return 返回Label的宽度
  */

+ (CGFloat)getWidthWithText:(NSString *)text height:(CGFloat)height font:(CGFloat)font {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font]}
                                     context:nil];
    return rect.size.width;
}

+ (CGFloat)getWidthWithText:(NSString *)text height:(CGFloat)height boldFont:(CGFloat)font {
    CGRect rect = [text boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:font]}
                                     context:nil];
    return rect.size.width;
}

+ (CGSize)sizeWithText:(NSString *)text font:(UIFont *)font {
    NSDictionary *attrs = @{NSFontAttributeName:font};
    return  [text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

@end
```

将计算好的高度缓存到对应的cell的model中

在\- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath中返回model中的高度