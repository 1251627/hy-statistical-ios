# HyStatistical iOS SDK

轻量级数据埋点 Swift SDK：事件上报、批量发送、离线缓存、自动采集 App 生命周期事件。

## 安装

### Swift Package Manager（推荐）

Xcode → File → Add Package Dependencies → 输入：

```
https://github.com/1251627/hy-statistical-ios.git
```

Version 选 `v0.1.4`。

### CocoaPods

```ruby
pod 'HyStatistical', :git => 'https://github.com/1251627/hy-statistical-ios.git', :tag => 'v0.1.4'
```

```bash
pod install
```

## 快速开始

```swift
import HyStatistical

HyStatistical.initialize(
    config: .init(
        apiKey: "your_api_key",
        enableLog: false    // 开发期可以开
    ),
    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
    userId: loadLocalUserId()   // 可选；传入后首条 app_open 也带 user_id
)
```

## 上报事件

```swift
// 自定义事件 + 自定义参数
HyStatistical.track("subscribe_results", [
    "source": "home_banner",
    "is_success": true,
    "product_id": "year_dy",
    "period": "yearly"      // weekly / monthly / yearly
])

// 无参数事件
HyStatistical.track("button_click")
```

事件名和 properties 完全由业务决定，服务端根据 `event_name` 和 JSON 自动识别展示。

## 配置项

```swift
HyStatisticalConfig(
    apiKey: "required",                                  // 必填
    serverUrl: "http://192.168.9.85:3000/api/v1",       // 默认后端地址
    flushInterval: 10,                                   // 秒，定时 flush
    flushSize: 50,                                       // 积累多少条立刻 flush
    maxRetries: 3,                                       // 网络错误重试次数
    enableLog: false                                     // 打开后打印 [HyStatistical] 前缀的调试日志
)
```

## API 速查

| API | 说明 |
|---|---|
| `HyStatistical.initialize(config:, appVersion:, userId:)` | 初始化（idempotent，重复调用会忽略） |
| `HyStatistical.track(_:_:)` | 上报事件 |
| `HyStatistical.setUserId(_:)` | 用户登录/登出时更新 user_id |
| `HyStatistical.setAppVersion(_:)` | 运行时更新 app_version |
| `HyStatistical.flush()` | 手动立刻 flush |
| `HyStatistical.clearPending()` | 清空内存队列 + 离线缓存（慎用） |
| `HyStatistical.deviceId` | 获取 SDK 生成的 device_id |
| `HyStatistical.pendingCount` | 队列里待发事件数 |

## 自动采集

| 事件 | 触发时机 |
|------|---------|
| `app_open` | 首次初始化 |
| `app_foreground` | App 从后台回到前台 |

进入后台时自动触发队列发送，防止数据丢失。

## 离线缓存和重试策略

- 事件先写入内存队列，按 `flushInterval` 或队列达到 `flushSize` 触发 flush
- HTTP 200 → 从队列移除
- HTTP 4xx → **该批直接丢弃**（业务参数有问题，重试无意义）
- HTTP 5xx / 网络错误 → 重试 `maxRetries` 次，最终失败写入 UserDefaults，下次启动自动恢复
- `insert_id` 是每条事件的 UUID，服务端根据这个去重

## 调试

开发期把 `enableLog: true` 打开，会看到带 `[HyStatistical]` 前缀的日志，详见 Flutter SDK README 的「调试」小节，行为一致。

## 版本

查看 [Releases](https://github.com/1251627/hy-statistical-ios/releases)。最新稳定版：`v0.1.4`。
