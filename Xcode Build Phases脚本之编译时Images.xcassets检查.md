### Xcode Build Phases脚本之编译时Images.xcassets检查

> In shell build phases you can write to stderr using the following format:
<filename>:<linenumber>: error | warn | note : <message>\n

> It’s the same format gcc uses to show errors. The filename:linenumber part can be omitted. Depending on the mode (error, warn, note), Xcode will show your message with a red or yellow badge.
If you include an absolute file path and a line number (if the error occurred in a file), double clicking the error in the build log lets Xcode open the file and jumps to the line, even if it is not part of the project. Very handy.

大概意思是说在build phases里按照 <文件名>:行号: error | warning: <提示信息>这样的方式log一条消息的话可以在Xcode的Issue navigator中看到。error显示一条错误信息，warning显示一条警告信息。

网上有很多关于在Xcode的Issue navigator中显示TODO:和FIXME:这些警告信息的文章（比如[这篇](https://krakendev.io/blog/generating-warnings-in-xcode)）,其中运用的就是这个方式。

今天我要说的是用这个方法在Xcode编译时能够动态检查Images.xcassets里的图片是否有未被使用或者在源码中引用了不在Images.xcassets中的图片这两种错误情况。这样就可以在编译器帮我们检查出来图片相关的一些错误。

话不多少，直接上检查代码:

`AssetChecker.swift:`

``` swift
#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

// Configure me \o/
var sourcePathOption: String?
var assetCatalogPathOption: String?

for (index, arg) in CommandLine.arguments.enumerated() {
    switch index {
    case 1:
        sourcePathOption = arg
    case 2:
        assetCatalogPathOption = arg
    default:
        break
    }
}

guard let sourcePath = sourcePathOption, FileManager.default.fileExists(atPath: sourcePath) else {
    print("\(#file):\(#line): error: 请检查第一个参数：要检查的源代码路径！")
    exit(0)
}

guard let assetCatalogAbsolutePath = assetCatalogPathOption, FileManager.default.fileExists(atPath: assetCatalogAbsolutePath) else {
    print("\(#file):\(#line): error: 请检查第二个参数：Images.xcassets路径！")
    exit(0)
}

print("Searching sources in \(sourcePath) for assets in \(assetCatalogAbsolutePath)")

// MARK: AssetChecker 检查图片白名单

func AssetWhiteList() -> [String] {
    return
        [
            "H5_Share",
            "H5_Favorite_On",
            "H5_Favorite_Off",
            "H5_Custom_Back",
            "H5_Search",
            "H5_Retry"
        ]
}

// MARK: - End Of Configurable Section

func elementsInEnumerator(_ enumerator: FileManager.DirectoryEnumerator?) -> [String] {
    var elements = [String]()

    while let e = enumerator?.nextObject() as? String {
        elements.append(e)
    }
    return elements
}

// MARK: - List Assets

func listAssets() -> [String] {
    let extensionName = "imageset"
    let enumerator = FileManager.default.enumerator(atPath: assetCatalogAbsolutePath)
    return elementsInEnumerator(enumerator)
        .filter { $0.hasSuffix(extensionName) } // Is Asset
        .map { $0.replacingOccurrences(of: ".\(extensionName)", with: "") } // Remove extension
        .map { $0.components(separatedBy: "/").last ?? $0 } // Remove folder path
}

// MARK: - List Used Assets in the codebase

typealias AssetUsedInfo = (assetName: String, fileName: String, lineNumber: Int)

func listUsedAssetLiteralsIn(_ file: String) -> [AssetUsedInfo] {
    guard let content = try? String(contentsOfFile: file, encoding: .utf8) else { return [] }

    var localizedStrings = [AssetUsedInfo]()
    let namePattern = "([\\w-]+)"
    let patterns = [
        "#imageLiteral\\(resourceName: \"\(namePattern)\"\\)", // Image Literal
        "UIImage\\(named:\\s*\"\(namePattern)\"\\)", // Default UIImage call (Swift)
        "UIImage imageNamed:\\s*\\@\"\(namePattern)\"", // Default UIImage call
        "\\<image name=\"\(namePattern)\".*" // Storyboard resources
    ]

    let group = DispatchGroup()
    for pattern in patterns {
        let queue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
        queue.async(group: group) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
            let range = NSRange(location: 0, length: content.count)
            regex.enumerateMatches(in: content, options: [], range: range, using: { result, _, _ in
                if let result = result {
                    let value = (content as NSString).substring(with: result.range(at: 1))

                    var lineNumber = 0
                    let firstRange = result.range
                    if firstRange.location < content.count {
                        let subContent = (content as NSString).substring(with: NSRange(location: 0, length: firstRange.location))
                        let subContents = subContent.components(separatedBy: .newlines)
                        lineNumber = subContents.count
                    }

                    localizedStrings.append(AssetUsedInfo(assetName: value, fileName: file, lineNumber: lineNumber))
                }
            })
        }
    }
    group.wait()

    return localizedStrings
}

func listUsedAssetLiterals() -> [AssetUsedInfo] {
    let enumerator = FileManager.default.enumerator(atPath: sourcePath)
    print(sourcePath)

    let assetInfos = elementsInEnumerator(enumerator)
        .filter { $0.hasSuffix(".m") || $0.hasSuffix(".swift") || $0.hasSuffix(".xib") || $0.hasSuffix(".storyboard") } // Only Swift and Obj-C files
        .map { "\(sourcePath)/\($0)" }
        .flatMap(listUsedAssetLiteralsIn)
    return assetInfos
}

// MARK: - Begining of script

let assets = Set(listAssets())
let used = Set(listUsedAssetLiterals().compactMap { $0.assetName } + AssetWhiteList())

// Generate Warnings for Unused Assets
let unused = assets.subtracting(used)
unused.forEach { print("\(assetCatalogAbsolutePath): warning: [Asset 未使用] \($0)") }
if !unused.isEmpty {
    print("\(#file):34: warning: 如果确定Asset已使用，请将其添加到白名单AssetWhiteList()方法 中")
}

// Generate Error for broken Assets
let broken = listUsedAssetLiterals().filter { !assets.contains($0.assetName) }
broken.forEach { print("\($0.fileName):\($0.lineNumber): error: [Asset 缺失] \($0.assetName)") }

if !broken.isEmpty {
    exit(1)
}

```

这个脚本先将Images.xcassets中的图片名保存下来，再编译项目中的源码文件，包含.m，.swift，.xib，.storyboard这几种文件格式，再按照
`#imageLiteral(resourceName:)`,`UIImage(named:)`,`[UIImage imageNamed:]`,`<image name=>`这几种图片的使用方式把源码中所有引用过的图片名称保存下来。

最后再对Images.xcassets中和代码中引用的图片进行比较，可能会有下面两种情况：

	* 如果Images.xcassets中的图片没有在代码中引用，就说明图片未被使用；
	* 如果代码中引用的图片不存在Images.xcassets中，说明引用了不存在的图片；

图片未被使用，在Xcode的Issue navigator中显示一条警告，点击警告信息自动跳转到Images.xcassets。

引用不存在的图片，在在Xcode的Issue navigator中显示一条错误，点击错误信息自动跳转到引用错误图片的源码位置。

最后如果确认图片已经被使用但是出现了误报的情况，就可以把图片名称添加到AssetWhiteList()白名单中。

***
上面就是Images.xcassets检查的核心逻辑，这个脚本是Swift文件，需要另外再增加一个shell脚本来调用它，并将Images.xcassets和要检查的源码根路径两个参数传进去。

`AssetChecker.sh`

``` shell
#!/bin/sh

#  Figure out where we're being called from
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo $DIR

# Path to Swift script file
swiftFile="${DIR}/bin/AssetChecker.swift"

SOURCE="$1"
CATALOG="$2"

cmd="$swiftFile $SOURCE $CATALOG"
echo $cmd
$cmd

```

下面在Xcode的Build Phases中新增一个Run Script，在里面调用AssetChecker.sh脚本。

```
${SRCROOT}/AssetChecker.sh ${SRCROOT}/Class ${SRCROOT}/MOMA/Images.xcassets
```

*** 
图片检查结果

![1533108607410-image.png](https://i.loli.net/2018/08/01/5b616193bd523.png)
