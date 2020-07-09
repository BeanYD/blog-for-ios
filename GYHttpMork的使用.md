### 使用GYHttpMork

1.可以直接使用GET请求

2.urlString：请求的url，一致就行

3.本地添加.json文件

```objective-c
    mockRequest(@"GET", urlString).
    andReturn(200).
    withBody(@"getTrainList.json");


    NSURLSession * session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        [self endRefresh];
        GTTrainListModel *listModel = [GTTrainListModel JSONModelWithKeyValues:dict[@"result"]];
        self.originalDataArray = [NSMutableArray arrayWithArray:listModel.trains];
        if (firstLoad) {
            [self getScreenDataFromRequestData];
            [self updateScreenDataForSearchViewCondition];
        }

        // 筛选数组
        [self screenOriginalDataArray];

        dispatch_async_on_main_queue(^{

        });
        if (error) {
            NSLog(@"%@",error);
        }else{
            NSLog(@"%@",data);
        }
    }] resume];
```

