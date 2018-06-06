## Fix libstdc++.6在Xcode10编译报错问题

#### libstdc++.6已经在Xcode10中被废弃，所以链接有stdc++.6的lib会在Xcode10上编译报错，这时就需要手动将stdc++.6替换成c++.
 
在Podfile中增加post_install的hook，代码如下:

``` ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
    	target.build_configurations.each do |config|
            # Fix libstdc++.6在Xcode10编译报错问题
            if target.name == "Pods-SomeTarget"
                xcconfig_path = config.base_configuration_reference.real_path
                xcconfig = File.read(xcconfig_path)
                new_xcconfig = xcconfig.sub('stdc++.6', 'c++')

                File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
            end
        end
    end
end
```
 