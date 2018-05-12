# PHCachingImageManager.stopCachingImagesForAllAssets() 崩溃

* PHCachingImageManager.stopCachingImagesForAllAssets()方法在没有相册访问权限的情况下调用会发生crash

![屏幕快照 2018-05-12 下午10.50.29.png](https://i.loli.net/2018/05/12/5af6ff5847034.png)


* 解决方案：

PHCachingImageManager.stopCachingImagesForAllAssets调用之前判断是否有相册访问权限

```
deinit {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            return
        }

        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        PHCachingImageManager.stopCachingImagesForAllAssets()
    }
```
