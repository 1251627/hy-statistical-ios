# HyStatistical iOS SDK

轻量级数据埋点 Swift SDK：事件上报、批量发送、离线缓存、自动采集 App 生命周期事件、**广告归因（v0.3.0+，可选）**。

## 安装

### Swift Package Manager（推荐）

Xcode → File → Add Package Dependencies → 输入：

```
https://github.com/1251627/hy-statistical-ios.git
```

Version 选 `v0.3.0`。

### CocoaPods

```ruby
pod 'HyStatistical', :git => 'https://github.com/1251627/hy-statistical-ios.git', :tag => 'v0.3.0'
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
        serverUrl: "https://your-collect-domain.com/api/v1",  // 必填
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
    serverUrl: "",                                       // 必填，例如 https://collect.your-domain.com/api/v1
    flushInterval: 10,                                   // 秒，定时 flush
    flushSize: 50,                                       // 积累多少条立刻 flush
    maxRetries: 3,                                       // 网络错误重试次数
    enableLog: false,                                    // 打开后打印 [HyStatistical] 前缀的调试日志
    enableAdAttribution: false                           // v0.3.0+：开启后采集 IDFA / PAID 用于广告归因，启用前请更新 App 隐私政策
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

## 广告归因（v0.3.0+，可选）

如果需要把 App 用户与外部广告点击（如小红书聚光 / 巨量 / 磁力）做归因匹配，开启 `enableAdAttribution`：

```swift
HyStatistical.initialize(
    config: .init(
        apiKey: "your_api_key",
        serverUrl: "https://collect.your-domain.com/api/v1",
        enableAdAttribution: true       // 新参数，默认 false
    ),
    appVersion: ...,
    userId: ...
)
```

### 工作机制

- **冷启动后**与 **`setUserId(_:)`** 调用时，SDK 自动采集一次设备指纹并上报；同 visitorId 24 小时内最多上报一次
- 采集字段：
  - **IDFA**：通过 `ASIdentifierManager`，**不弹 ATT 授权框**。用户未授权时系统返回全零 UUID，SDK 识别后上报空串（服务端识别为"未授权"）
  - **PAID**：基于 App 安装时间 + 系统更新时间 + 设备启动时间的不可逆 MD5 三元组，无授权要求
- 上报内容随下一次 flush 一起 POST 到 `<serverUrl>/collect`，附带在 `device_fingerprint` 字段里
- 关闭归因（默认状态）时，SDK 行为与 v0.2.x 完全一致，不采集任何广告标识符

### App Store 审核

即使不弹 ATT，**`Info.plist` 中建议添加 `NSUserTrackingUsageDescription`** 描述用途（例如「用于评估广告投放效果」），否则部分审核员会拒绝。

### 隐私政策

启用归因前必须更新 App 隐私政策。模板见 [PRIVACY_NOTICE_TEMPLATE.md](PRIVACY_NOTICE_TEMPLATE.md)。

## 调试

开发期把 `enableLog: true` 打开，会看到带 `[HyStatistical]` 前缀的日志，详见 Flutter SDK README 的「调试」小节，行为一致。

## 版本

查看 [Releases](https://github.com/1251627/hy-statistical-ios/releases)。最新稳定版：`v0.3.0`。

### v0.3.0 升级须知（向后兼容）

新增可选参数 `enableAdAttribution`（默认 `false`）。不开启的项目无需任何代码改动，从 v0.2.x 升级直接拉新版即可。

开启后 SDK 采集 IDFA + PAID 并上报，详见上文「广告归因」章节。注意启用前需更新 App 隐私政策，模板见 [PRIVACY_NOTICE_TEMPLATE.md](PRIVACY_NOTICE_TEMPLATE.md)。

### v0.2.0 升级须知（破坏性变更）

`serverUrl` 从默认值改为**必填**。从 v0.1.x 升级时，原本的 `HyStatisticalConfig(apiKey: "xxx")` 编译失败。需要补上：

```swift
HyStatisticalConfig(
    apiKey: "xxx",
    serverUrl: "https://collect.your-domain.com/api/v1"  // 新增此行
)
```

这一改动是为了避免「忘记改默认值，把生产事件错发到开发后端」的事故。
