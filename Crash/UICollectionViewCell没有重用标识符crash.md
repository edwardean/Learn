# UICollectionViewCell没有重用标识符crash

之前我们项目中在写UITableView的cellForRow方法中对于数据源越界的情况都会返回一个新的Cell作为兜底：

``` objc
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < dishSet.selectedDishes.count) {
    DEFTableCell *cell= [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
     DEFDish *dish = [dishSet.selectedDishes objectAtIndex:indexPath.row];
     [cell setupData:dish];
     cell.selectionStyle = UITableViewCellSelectionStyleNone;
     return cell;
    }
    //数组越界返回兜底cell
    return [[UITableViewCell alloc] init];
}
```

这种情况下如果一旦发生indexPath超出数据数组长度的情况下会返回一个空cell，不会出崩溃问题。

对于UICollectionView我们也是这种类似的做法：

```
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *tags = self.viewModel.tags;
    if (indexPath.row < tags.count) {
        DEFMerchantCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DEFMerchantCell" forIndexPath:indexPath];
        DEFMerchantTag *tag = self.viewModel.tags[indexPath.row];
        [cell load:tag.name];
        return cell;
    }
    return [[UICollectionViewCell alloc] init];
}
```

但是出现了需要返回兜底cell的时候却出现了崩溃：

```
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'the cell returned from -collectionView:cellForItemAtIndexPath: does not have a reuseIdentifier - cells must be retrieved by calling -dequeueReusableCellWithReuseIdentifier:forIndexPath:'
```

意思就是说UICollectionViewCell必须要有一个重用标识符才可以，像[[UICollectionViewCell alloc] init]这样直接返回是不允许的。