# iOS 自动点击器 (AutoClicker) - 可导出IPA并用第三方签名工具签名

## 功能说明
这是一个运行在苹果手机上的自动点击APP，可以根据屏幕内容自动生成点击动作，编译后导出IPA，你可以使用第三方签名工具签名安装到手机。

**优势：不需要你自己有Mac电脑，使用国内 Gitee(码云) 在线免费编译生成IPA，国内可以正常访问**

## 项目结构
```
手机屏幕自动点击/
├── .github/
│   └── workflows/
│       └── build-ipa.yml            # GitHub Actions自动编译配置（国外）
├── .gitee/
│   └── workflows/
│       └── build-ipa.yml            # Gitee国内自动编译配置（国内可用）
├── AutoClicker/                     # iOS Xcode项目
│   ├── AutoClicker.xcodeproj/       # Xcode项目文件
│   │   └── project.pbxproj          # 项目配置
│   ├── AutoClicker/                 # 源代码
│   │   ├── AppDelegate.swift        # 应用入口
│   │   ├── ViewController.swift     # 主界面和自动点击核心逻辑
│   │   └── Info.plist               # 应用配置
│   ├── AutoClickerTests/            # 单元测试目录
│   └── AutoClickerUITests/          # UI测试目录
├── app/                             # Android项目（可选）
├── .gitignore                       # Git忽略配置
└── README.md                        # 本文档
```

## 无Mac编译生成IPA方法（国内推荐 Gitee 码云，访问没问题）
如果你访问不了GitHub，可以用国内的 Gitee 码云，步骤如下：

1. 注册/登录 [Gitee 码云](https://gitee.com/)，国内可以正常访问
2. 新建一个仓库（项目）
3. 在你本地项目文件夹，打开PowerShell，执行下面命令（复制粘贴即可：

```powershell
git init
git add .
git commit -m "Initial commit: 自动点击器"
git branch -M main
git remote add origin https://gitee.com/你的Gitee用户名/你的仓库名.git
git push -u origin main
```

4. 在Gitee打开你的仓库 → 点击 **流水线** → **Gitee Go**
5. 开启Gitee Go后，会自动识别流水线，选择我们已经配置好的 `编译IPA流水线，点击运行流水线即可
6. 等待3-5分钟编译完成，在流水线运行成功后，在 **产物** 那里就可以下载编译好的IPA文件
7. 下载得到IPA文件后，放到你现在这个文件夹，再用你的第三方签名工具签名就可以安装到手机了

## 如果你能访问GitHub，也可以用GitHub Actions：
1. 在GitHub上创建一个新的仓库（公开私有都可以）
2. 将你本地这个项目的所有文件推送到GitHub仓库
3. 在GitHub上打开你的仓库，进入 **Actions** 标签页
4. 你会看到已经有一个 "Build iOS IPA" workflow，点击 **Run workflow** 手动运行
5. 等待几分钟编译完成，进入编译结果页面，下载生成的 `AutoClicker-ipa` 压缩包，解压就得到IPA文件了
6. 将得到的IPA用你的第三方签名工具签名即可安装到苹果手机

> GitHub Actions和Gitee Go都提供免费额度，足够用了，完全免费。

## 如果要手动在Mac编译，步骤如下：
1. 将整个 `AutoClicker` 文件夹复制到你的Mac电脑上
2. 打开 `AutoClicker.xcodeproj` 用Xcode打开项目
3. 在Xcode中修改 `PRODUCT_BUNDLE_IDENTIFIER` 改成你自己的ID（在项目设置 -> Targets -> AutoClicker -> General -> Bundle Identifier）
4. 选择 "Any iOS Device" 作为编译目标
5. 菜单栏选择 **Product -> Archive** 进行归档
6. 归档完成后，在打开的Archives窗口中选择 "Distribute App" -> "Ad Hoc" 或者 "Export"，导出IPA文件
7. 将导出的IPA文件用你的第三方签名工具重新签名即可

## 核心功能说明
- 基于iOS官方 **Accessibility(辅助功能)** API实现自动点击，这是iOS唯一合法允许方案
- 支持随机位置自动点击，可以很方便修改点击间隔和点击位置逻辑
- 可随时在APP里启动/停止点击
- 已经配置好需要的权限说明

## 功能修改：自定义点击规则
你可以在 [ViewController.swift](AutoClicker/AutoClicker/ViewController.swift) 中修改点击逻辑：
- 修改 `startAutoClick()` 中的点击间隔（默认1秒点击一次）
- 如果需要根据屏幕内容识别文字再点击，可以加上 **Vision OCR** 识别，参考代码：

```swift
import Vision

func recognizeText(in image: UIImage, completion: @escaping ([VNRecognizedTextObservation]) -> Void) {
    guard let cgImage = image.cgImage else {
        completion([])
        return
    }
    
    let request = VNRecognizeTextRequest { request, error in
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            completion([])
            return
        }
        completion(observations)
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("OCR error: \(error)")
        completion([])
    }
}
```

## 安装和使用说明
在手机上安装后：
1. 打开iOS 设置 -> 隐私与安全性 -> 辅助功能，找到你的应用，开启权限
2. 打开本APP，点击 "开始自动点击" 即可开始
3. 点击 "停止点击" 停止运行

## 上架App Store说明
如果你需要上架App Store，注意：
1. 需要有付费苹果开发者账号（99美元/年）
2. 在应用描述中必须清晰说明应用用途，不要用于违规用途
3. 本项目使用的Accessibility API是苹果官方允许的，只要功能合规可以通过审核

如果只是自己使用或者企业内部分发，你只需要导出IPA后用第三方签名工具签名即可，不需要上架App Store。

## 常见问题
1. **编译失败怎么办？**
   - 确保你把所有文件都推送成功了，特别是 `AutoClicker.xcodeproj/project.pbxproj`
   - 检查流水线运行日志，一般重新推送一次就好

2. **点击不生效？**
   需要确保你在系统设置中已经给这个APP开启了辅助功能权限：设置 -> 隐私与安全性 -> 辅助功能，找到你的APP，开启权限。

3. **我想改成固定位置点击？**
   修改 `performRandomClick()` 方法，把 `randomX` 和 `randomY` 改成你要点击的固定坐标就好。
