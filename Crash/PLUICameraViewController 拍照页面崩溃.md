## PLUICameraViewController 拍照页面崩溃

* 系统： iOS 9全系统

* 崩溃信息

```
Exception Type:  EXC_BAD_ACCESS (SIGBUS)
Exception Codes: KERN_INVALID_TASK at 0x0000000000000010
Crashed Thread:  0

Thread 0 Crashed:
0   libobjc.A.dylib                 objc_msgSend + 16
1   Foundation                      __NSFireDelayedPerform + 428
2   CoreFoundation                  __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__ + 28
3   CoreFoundation                  __CFRunLoopDoTimer + 884
4   CoreFoundation                  __CFRunLoopRun + 1520
5   CoreFoundation                  CFRunLoopRunSpecific + 384
6   GraphicsServices                GSEventRunModal + 180
7   UIKit                           UIApplicationMain + 204
8   moma                            main (main.m:14)
9   libdyld.dylib                   0x00000001823028b8 0x182300000 + 10424
```

然而，卵用没有~

从crash出现时的页面记录中发现了线索：

```
2018-04-20 18:26:47 [APPEAR]DEFMultipleImagePickerTableViewController
2018-04-20 18:26:47 [APPEAR]DEFAlbumPickerViewController
2018-04-20 18:26:47 [DISAPPEAR]PLUICameraViewController
2018-04-20 18:26:47 [ACTION]PLCropOverlay(_tappedBottomBarCancelButton:)
2018-04-20 18:26:39 [APPEAR]PLUICameraViewController
2018-04-20 18:26:39 [DISAPPEAR]DEFAlbumPickerViewController
2018-04-20 18:26:39 [LOADED]PLUICameraViewController
2018-04-20 18:26:38 [DISAPPEAR]DEFMultipleImagePickerTableViewController
2018-04-20 18:26:38 [ACTION]DEFMultipleImageTableViewCell(cameraButtonClicked:)
2018-04-20 18:26:33 [APPEAR]DEFMultipleImagePickerTableViewController
```

最后是在系统的拍照页面`PLUICameraViewController`消失之后崩溃的，借着这个线索在SO上找到了复现步骤：
https://stackoverflow.com/questions/26844432/how-to-find-out-what-causes-a-didhidezoomslider-error-on-ios-8/29959695

* 复现步骤

![ImagePicker_iOS9_crash.gif](https://wx4.sinaimg.cn/mw1024/a1e206c1gy1fqno8mra2fg20a00dc7wn.gif)

在拍照页面中双指捏合后会出现`CMKZoomSlider`，这个view出现后会在5s后自动消失。如果在它消失前的一刹那点击“取消”将拍照页面dismiss掉的话就会出现crash。

![IMG_0583.PNG](https://i.loli.net/2018/04/24/5adebafa0ae9c.png)

![IMG_0582.PNG](https://i.loli.net/2018/04/24/5adebadd1d0ec.png)



* 解决方案：

Hook `PLUICameraViewController`类的`viewWillDisappear`方法，将`CMKZoomSlider`的`delegate`设为nil。详见[SO](https://stackoverflow.com/questions/26844432/how-to-find-out-what-causes-a-didhidezoomslider-error-on-ios-8/29959695)。


