## 使用UILocalizedIndexedCollation进行分组和排序功能

1.相关代码

```objective-c
// 按首字母分组排序数组
-(NSMutableArray *)sortObjectsAccordingToInitialWithArray:(NSArray *)arr {
    // 获取UILocalizedIndexedCollation单例
    UILocalizedIndexedCollation *collation = [UILocalizedIndexedCollation currentCollation];
    
    //得出collation索引的数量，这里是27个（26个字母和1个#）
    NSInteger sectionTitlesCount = [[collation sectionTitles] count];
    //初始化一个数组newSectionsArray用来存放最终的数据，我们最终要得到的数据模型应该形如@[@[以A开头的数据数组], @[以B开头的数据数组], @[以C开头的数据数组], ... @[以#(其它)开头的数据数组]]
    NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    //初始化27个空数组加入newSectionsArray
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [newSectionsArray addObject:array];
    }
    
    //将每个名字分到某个section下
  	/*
    for (NSString *str in arr) {
        //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11，self指NSString本身
        NSInteger sectionNumber = [collation sectionForObject:str collationStringSelector:@selector(self)];
        //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
        NSMutableArray *sectionNames = newSectionsArray[sectionNumber];
        [sectionNames addObject:str];
    }
    */
    for (GTModel *model in arr) {
        //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11，costCenterName是model中的属性
        NSInteger sectionNumber = [collation sectionForObject:model collationStringSelector:@selector(name)];
        //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
        NSMutableArray *sectionNames = newSectionsArray[sectionNumber];
        [sectionNames addObject:model];
    }
    
    //对每个section中的数组按照name属性排序
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *personArrayForSection = newSectionsArray[index];
        NSArray *sortedPersonArrayForSection;
        // sortedPersonArrayForSection = [collation sortedArrayFromArray:personArrayForSection collationStringSelector:@selector(self)];
        sortedPersonArrayForSection = [collation sortedArrayFromArray:personArrayForSection collationStringSelector:@selector(name)];
        newSectionsArray[index] = sortedPersonArrayForSection;
    }

    //删除空的数组
    NSMutableArray *finalArr = [NSMutableArray new];
    for (NSInteger index = 0; index < sectionTitlesCount; index++) {
        if (((NSMutableArray *)(newSectionsArray[index])).count != 0) {
            [finalArr addObject:newSectionsArray[index]];
            [self.sectioinArray addObject:collation.sectionTitles[index]];
        }
    }
    return finalArr;
}
```

2.使用sortedArrayFromArray:collationStringSelector:方法进行排序，如果单个分组下的数据量达到500条，需要1s时间；900条需要3s时间。大数据量下进行分组排序使用，建议将数据分组排序业务放入子线程中，并前置进行。