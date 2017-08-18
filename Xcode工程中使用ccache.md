##[Ccahe](https://ccache.samba.org/)


* ccache安装

	`brew install ccache`


* 编辑`ccache-clang`脚本：

	```
 #!/bin/sh
 if type -p ccache >/dev/null 2>&1; then
  export CCACHE_MAXSIZE=3G
  export CCACHE_CPP2=true
  export CCACHE_HARDLINK=true
  export CCACHE_SLOPPINESS=file_macro,time_macros,include_file_mtime,include_file_ctime,file_stat_matches

  #指定日志文件路径到桌面，等下排查集成问题有用，集成成功后删除，否则很占磁盘空间
  #export CCACHE_LOGFILE='~/Desktop/CCache.log'
  exec ccache /usr/bin/clang "$@"
else
  exec clang "$@"
fi
```

* 在工程User-Defined中添加CC变量,我是将ccache-clang脚本放在了项目目录下的ccache子目录下
```
$(SRCROOT)/ccache/ccache-clang
```
![](https://ooo.0o0.ooo/2017/08/18/599688cca441f.png)


* ccache由于不支持module，所以要在Podfile中关闭Pod工程的Enable Modules：
	
	```
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            #关闭 Enable Modules
            config.build_settings['CLANG_ENABLE_MODULES'] = 'NO'
            # 在生成的 Pods 项目文件中加入 CC 参数，路径的值根据你自己的项目来修改
            config.build_settings['CC'] = '$(PODS_ROOT)/../ccache/ccache-clang'
        end
    end
end
```

* 在Podfile中进行配置，将头文件里的`@import`全都改写成`#import`:

	```
pre_install do |installer| 
require 'fileutils'
def iterate_souce_and_modify_at_import(glob_str)
regexp = /@import\s+(\w+);/
at_import_files = Dir[glob_str].select do |file_name|
text = File.read(file_name)
regexp.match(text)
end
at_import_files.each do |file_name|
text = File.read(file_name)
new_content = text.gsub(regexp, '#import <\1/\1.h>')
FileUtils.chmod "u+w", file_name, :verbose => true
File.open(file_name, 'w+') {|file| file.write(new_content)}
FileUtils.chmod "u-w", file_name, :verbose => true
end
end
iterate_souce_and_modify_at_import('./Pods/**/*.h')
iterate_souce_and_modify_at_import('./Pods/**/*.m')
end
```

ccache编译时长：
打开Xcode编译时间

```
> defaults write com.apple.dt.Xcode ShowBuildOperationDuration YES
```

用`ccache -s`查看缓存命中情况

```
➜  ~ ccache -s
cache directory                     /Users/lihang/.ccache
primary config                      /Users/lihang/.ccache/ccache.conf
secondary config      (readonly)    /usr/local/Cellar/ccache/3.3.4_1/etc/ccache.conf
cache hit (direct)                147505
cache hit (preprocessed)           15739
cache miss                         66303
cache hit rate                     71.12 %
called for link                      451
called for preprocessing             109
compile failed                        82
preprocessor error                  2021
can't use precompiled header          79
cache file missing                     2
no input file                        114
cleanups performed                   123
files in cache                    124710
cache size                           2.5 GB
max cache size                       5.0 GB
```
在我自己的开发Mac上当缓存命中率打到70%时工程编译时间由原来的260s左右减少至现在的20s左右，可以说提升还是很大的。