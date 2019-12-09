## UIStackView 在iOS10或以下系统Crash问题：

* 崩溃堆栈：


```
Date/Time:       2019-12-08 23:06:07.000 +0800
OS Version:      iPhone OS 9.2 (13C75)
Report Version:  104

Exception Type:  EXC_CRASH (SIGABRT)
Exception Codes: 0x00000000 at 0x0000000000000000
Crashed Thread:  0

Application Specific Information:
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: '{objective 0x1460e8080: <> + <1:1>*0x1460e2680.marker{id: 17427} + <1:1>*0x1460ea9d0:UISV-canvas-connection.marker{id: 17628} + <1:-1>*0x1460eaa20:UISV-canvas-connection.marker{id: 17629} + <1:1>*0x146206980.marker{id: 17453} + <1:-1>*0x14620ae50.marker{id: 17452} + <1:-0.00277778>*BusinessDataBisinessOrderCountUnitView:0x14620f230.Height{id: 17395}}: internal error.  Setting empty vector for variable BusinessDataBisinessOrderCountUnitView:0x146202af0.Height{id: 3080}.
UserInfo:(null)'

Thread 0 Crashed:
0   CoreFoundation                  __exceptionPreprocess + 124
1   libobjc.A.dylib                 objc_exception_throw + 56
2   CoreFoundation                  -[NSException initWithCoder:] + 0
3   Foundation                      -[NSISObjectiveLinearExpression setPriorityVector:forKnownAbsentVariable:] + 88
4   Foundation                      __128-[NSISObjectiveLinearExpression replaceVariable:withExpression:processVariableNewToReceiver:processVariableDroppedFromReceiver:]_block_invoke + 308
5   Foundation                      -[NSISLinearExpression enumerateVariablesAndCoefficients:] + 284
6   Foundation                      -[NSISObjectiveLinearExpression replaceVariable:withExpression:processVariableNewToReceiver:processVariableDroppedFromReceiver:] + 352
7   Foundation                      -[NSISEngine substituteOutAllOccurencesOfBodyVar:withExpression:] + 600
8   Foundation                      -[NSISEngine pivotToMakeBodyVar:newHeadOfRowWithHead:andDropRow:] + 340
9   Foundation                      -[NSISEngine minimizeConstantInObjectiveRowWithHead:] + 384
10  Foundation                      -[NSISEngine optimize] + 196
11  Foundation                      -[NSISEngine withBehaviors:performModifications:] + 260
12  UIKit                           -[UIView(AdditionalLayoutSupport) _withAutomaticEngineOptimizationDisabledIfEngineExists:] + 64
13  UIKit                           -[UIView(AdditionalLayoutSupport) updateConstraintsIfNeeded] + 244
14  UIKit                           -[UITableViewCellContentView updateConstraintsIfNeeded] + 200
15  UIKit                           -[UIView(AdditionalLayoutSupport) _updateConstraintsAtEngineLevelIfNeeded] + 268
16  UIKit                           -[UIView(Hierarchy) layoutBelowIfNeeded] + 764
17  iMerchant                       -[BusinessDataBizAmountWrapperView setBusinessesAmountArray:] (BusinessDataBizAmountWrapperView.m:80)
```

* 原代码：

```
#pragma mark - Getter
- (UIStackView *)contentStackView
{
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] initWithFrame:self.bounds];
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFillProportionally;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentStackView.spacing = 0;
        [_contentStackView setContentHuggingPriority:UILayoutPriorityFittingSizeLevel
                                             forAxis:UILayoutConstraintAxisVertical];
        [_contentStackView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                           forAxis:UILayoutConstraintAxisVertical];
    }
    return _contentStackView;
}

#pragma mark - Setter
- (void)setBusinessesAmountArray:(NSArray<ModuleEntity *> *)businessesAmountArray
{
    if ([_businessesAmountArray isEqualToArray:businessesAmountArray]) {
        return;
    }
    
    _businessesAmountArray = [businessesAmountArray copy];
    [self.contentStackView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (ModuleEntity *bizEntity in _businessesAmountArray) {
        BusinessDataBizAmountView *businessAmountView = [[BusinessDataBizAmountView alloc] init];
        businessAmountView.bizModuleEntity = bizEntity;
        businessAmountView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentStackView addArrangedSubview:businessAmountView];
    }
    
    [self.contentStackView layoutIfNeeded];
    [self layoutIfNeeded];
}

```


* 修改代码：

```
#pragma mark - Getter
- (UIStackView *)contentStackView
{
    if (!_contentStackView) {
        _contentStackView = [[UIStackView alloc] initWithFrame:self.bounds];
        _contentStackView.axis = UILayoutConstraintAxisVertical;
        _contentStackView.alignment = UIStackViewAlignmentFill;
        _contentStackView.distribution = UIStackViewDistributionFillProportionally;
        _contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentStackView.spacing = 0.5; //spacing设置非0值
        [_contentStackView setContentHuggingPriority:UILayoutPriorityFittingSizeLevel
                                             forAxis:UILayoutConstraintAxisVertical];
        [_contentStackView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                           forAxis:UILayoutConstraintAxisVertical];
    }
    return _contentStackView;
}

#pragma mark - Setter
- (void)setBusinessesAmountArray:(NSArray<ModuleEntity *> *)businessesAmountArray
{
    if ([_businessesAmountArray isEqualToArray:businessesAmountArray]) {
        return;
    }
    
    _businessesAmountArray = [businessesAmountArray copy];
    
    // arrangedSubviews先移除
    for (UIView *arrangedSubview in self.contentStackView.arrangedSubviews) {
        [self.contentStackView removeArrangedSubview:arrangedSubview];
    }
    [self.contentStackView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (ModuleEntity *bizEntity in _businessesAmountArray) {
        BusinessDataBizAmountView *businessAmountView = [[BusinessDataBizAmountView alloc] init];
        businessAmountView.bizModuleEntity = bizEntity;
        businessAmountView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentStackView addArrangedSubview:businessAmountView];
    }
    
    [self.contentStackView layoutIfNeeded];
    [self layoutIfNeeded];
}

```