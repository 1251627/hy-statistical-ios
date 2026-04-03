# HyStatistical iOS SDK

轻量级数据埋点 Swift SDK，支持事件上报、批量发送、离线缓存、自动采集 App 生命周期事件。

## 安装

### Swift Package Manager（推荐）

Xcode → File → Add Package Dependencies → 输入：

```
https://github.com/1251627/hy-statistical-ios.git
```

Version 选 `0.1.0`。

### CocoaPods

```ruby
pod 'HyStatistical', :git => 'https://github.com/1251627/hy-statistical-ios.git', :tag => '0.1.0'
```

```bash
pod install
```

## 使用

### 初始化

```swift
import HyStatistical

HyStatistical.initialize(
    config: .init(apiKey: "your_api_key"),
    appVersion: "1.0.0"
)
```

### 上报事件

#### 订阅事件

事件名必须为 `subscribe_success`，后台订阅页面根据此名称识别。

```swift
HyStatistical.track("subscribe_success", [
    "plan_id": "pro_monthly",
    "period": "monthly",       // weekly / monthly / yearly
    "source": "paywall_home"   // 触发订阅的页面来源
])
```

#### 其他业务事件

事件名和 properties 的 key/value 可以按自己的业务需求自由定义，后台会自动识别并展示。

```swift
// 自定义事件 + 自定义参数
HyStatistical.track("your_event_name", [
    "your_key": "your_value",
    "another_key": 123
])

// 无参数事件
HyStatistical.track("button_click")
```

### 设置用户 ID（可选，登录后调用）

```swift
HyStatistical.setUserId("user_123")
```

## 自动采集

SDK 初始化后自动采集以下事件，无需手动调用：

| 事件 | 触发时机 |
|------|---------|
| `app_open` | 首次初始化 |
| `app_foreground` | App 从后台回到前台 |

进入后台时自动触发队列发送，防止数据丢失。
