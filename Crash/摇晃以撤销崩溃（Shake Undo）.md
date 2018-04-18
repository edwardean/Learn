## 摇晃以撤销崩溃（Shake Undo）

### 崩溃堆栈信息：

-[NSTextStorage(UIKitUndoExtensions) _undoRedoAttributedSubstringFromRange:] + 156

```
Exception Type:  EXC_CRASH (SIGABRT)
Exception Codes: 0x00000000 at 0x0000000000000000
Crashed Thread:  0

Application Specific Information:
*** Terminating app due to uncaught exception 'NSRangeException', reason: '*** -[NSBigMutableString substringWithRange:]: Range {0, 61} out of bounds; string length 10
UserInfo:(null)'

Thread 0 Crashed:
0   CoreFoundation                  __exceptionPreprocess + 124
1   libobjc.A.dylib                 objc_exception_throw + 56
2   CoreFoundation                  -[NSException initWithCoder:] + 0
3   Foundation                      -[NSString substringWithRange:] + 140
4   UIKit                           -[NSTextStorage(UIKitUndoExtensions) _undoRedoAttributedSubstringFromRange:] + 156
5   UIKit                           -[_UITextUndoOperationReplace undoRedo] + 320
6   Foundation                      -[_NSUndoStack popAndInvoke] + 280
7   Foundation                      -[NSUndoManager undoNestedGroup] + 416
8   UIKit                           __58-[UIApplication _showEditAlertViewWithUndoManager:window:]_block_invoke.2492 + 32
9   UIKit                           -[UIAlertController _invokeHandlersForAction:] + 108
10  UIKit                           __103-[UIAlertController _dismissAnimated:triggeringAction:triggeredByPopoverDimmingView:dismissCompletion:]_block_invoke.459 + 28
11  UIKit                           -[UIPresentationController transitionDidFinish:] + 1320
12  UIKit                           __56-[UIPresentationController runTransitionForCurrentState]_block_invoke_2 + 188
13  UIKit                           -[_UIViewControllerTransitionContext completeTransition:] + 116
14  UIKit                           -[UIViewAnimationBlockDelegate _didEndBlockAnimation:finished:context:] + 764
15  UIKit                           -[UIViewAnimationState sendDelegateAnimationDidStop:finished:] + 312
16  UIKit                           -[UIViewAnimationState animationDidStop:finished:] + 296
17  UIKit                           -[UIViewAnimationState animationDidStop:finished:] + 456
18  QuartzCore                      CA::Layer::run_animation_callbacks(void*) + 284
```

### 复现步骤：

* 头条 V6.6.5

 ![头条V6.6.5.gif](https://i.loli.net/2018/04/18/5ad6a8f449c32.gif)


* 微信V6.6.6

 ![微信V6.6.6.gif](https://i.loli.net/2018/04/18/5ad6a9155be5c.gif)

* QQV7.5.8.422

 ![QQV7.5.8.422.gif](https://i.loli.net/2018/04/18/5ad6a93d7607f.gif)


### 修复方式

将`UIApplication`的`applicationSupportsShakeToEdit`属性关掉即可。