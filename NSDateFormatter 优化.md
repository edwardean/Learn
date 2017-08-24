## NSDateFormatter 优化

>
> 用`localtime`替代`NSDateFormatter `来完成`NSDate`到`NSString`的转换 
> 
[Gist](https://gist.github.com/edwardean/db9a8c8bb0f5f1d6a78918e625e25432)

* 测量代码

```
- (void)testDateFormatter {
    NSDate *date = [NSDate date];
    
    uint64_t t1 = dispatch_benchmark(10000, ^{
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        NSString *dateString = [fmt stringFromDate:date];
        //NSLog(@"%@", dateString);
    });

    uint64_t t2 = dispatch_benchmark(10000, ^{
        time_t timeInterval = [date timeIntervalSince1970];
        struct tm *cTime = localtime(&timeInterval);
        NSString *dateString = [NSString stringWithFormat:@"%d-%02d-%02d",cTime->tm_year+1900,
                                cTime->tm_mon+1,cTime->tm_mday];
        //NSLog(@"%@", dateString);
    });
    
    NSLog(@"t1:%llu, t2:%llu", t1, t2);
}
```

* 输出

```
t1:65482, t2:17860
t1:64783, t2:16978
t1:64048, t2:16813
t1:63576, t2:18177
t1:63270, t2:16066
```

* `localtime`与`NSDateFormatter `相比较性能方面有大约73%左右的提升。
