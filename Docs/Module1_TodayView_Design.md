# Module 1 — "今天的你" 工程设计文档

**项目：** andBeat (PULSE App)
**模块：** Today View / 首页
**版本：** v0.1.0
**创建日期：** 2026-05-21
**状态：** 代码完成，待 Xcode 集成验证

---

## 1. 模块概述

"今天的你"是 PULSE App 的首页，也是用户每日打开应用的第一个视图。其核心目标是：

- 一眼呈现用户当前所处的月经周期阶段
- 展示今日关键身体数据（心率、体温、HRV、呼吸）
- 提供基于周期阶段的个性化行动建议
- 作为其他功能模块（睡眠、AI 对话）的流量入口

---

## 2. 文件结构

```
andBeat/andBeat/
├── andBeatApp.swift              ← App 入口，注册 SwiftData 模型
├── ContentView.swift             ← Tab 导航根视图
├── Models/
│   ├── CycleProfile.swift        ← 周期档案数据模型（核心）
│   └── DailyMetrics.swift        ← 每日身体数据模型
└── Views/
    └── TodayView.swift           ← "今天的你"完整页面
```

---

## 3. 数据模型

### 3.1 CycleProfile

> 文件：`Models/CycleProfile.swift`

用户的月经周期基础档案，使用 SwiftData 持久化存储。

| 字段 | 类型 | 说明 |
|------|------|------|
| `lastPeriodStart` | `Date` | 上次经期开始日期 |
| `cycleLength` | `Int` | 平均周期天数，默认 28 |
| `periodLength` | `Int` | 平均经期天数，默认 5 |
| `userName` | `String` | 用户名 |

**计算属性：**

| 属性 | 返回类型 | 说明 |
|------|---------|------|
| `currentCycleDay` | `Int` | 今天是周期第几天（从 1 开始） |
| `currentPhase` | `CyclePhase` | 当前所处阶段 |
| `daysToNextPhase` | `Int` | 距下一阶段还有几天 |

**CyclePhase 枚举：**

| 值 | 显示名 | 天数范围（默认28天周期） |
|----|--------|----------------------|
| `.menstrual` | 经期 | 第 1 天 — 第 periodLength 天 |
| `.follicular` | 卵泡期 | 第 periodLength+1 天 — 第 13 天 |
| `.ovulation` | 排卵期 | 第 14 天 — 第 15 天 |
| `.luteal` | 黄体期 | 第 16 天 — 第 cycleLength 天 |

每个阶段携带：`description`（阶段特征说明）、`nextPhaseName`（下一阶段名称）、`color`（对应 Asset 颜色 key）。

---

### 3.2 DailyMetrics

> 文件：`Models/DailyMetrics.swift`

每日身体数据快照，每次同步耳环设备或 HealthKit 时写入一条记录。

| 字段 | 类型 | 单位 | 数据来源（MVP） | 数据来源（后期） |
|------|------|------|--------------|--------------|
| `date` | `Date` | — | 系统时间 | 系统时间 |
| `heartRate` | `Double?` | bpm | HealthKit | 耳环传感器 |
| `bodyTemperature` | `Double?` | °C | Mock | 耳环传感器 |
| `hrv` | `Double?` | ms | HealthKit | 耳环传感器 |
| `respiratoryRate` | `Double?` | 次/分钟 | HealthKit | 耳环传感器 |
| `notes` | `String?` | — | 用户手动输入 | 用户手动输入 |

所有身体数据字段均为可选类型（`Optional`），UI 层在字段为 `nil` 时统一显示 `"--"`。

---

## 4. 页面 UI 架构

### 4.1 整体布局

```
TodayView
└── ScrollView
    └── VStack (spacing: 20)
        ├── GreetingHeaderView       ① 顶部问候区
        ├── CyclePhaseCardView       ② 周期位置核心卡片
        ├── MetricsGridView          ③ 今日身体数据（2×2 网格）
        ├── StatusSummaryView        ④ 今日状态一句话摘要
        ├── DailyTipsView            ⑤ 今日行动建议
        └── QuickLinksView           ⑥ 快速跳转入口
```

背景色：`Color(.systemGroupedBackground)`（浅色系，跟随系统）

---

### 4.2 子组件说明

#### ① GreetingHeaderView
- 根据当前小时自动切换问候语（早上好 / 下午好 / 晚上好）
- 显示 `CycleProfile.userName`
- 右侧有 `DeviceStatusDot`：MVP 阶段固定显示"未连接"灰色状态点；后期对接 BLE 后变为绿色"已连接"

#### ② CyclePhaseCardView
- 主要内容：当前阶段名称、周期第 N 天、阶段描述、距下一阶段倒计时
- 核心子组件 `CycleArcView`：用 `Circle().trim()` 实现圆弧进度条，以 `currentDay / cycleLength` 为进度，带 `easeInOut` 动画
- 未设置周期时显示 `SetupPromptView` 引导用户录入

#### ③ MetricsGridView
- `LazyVGrid` 实现 2×2 响应式网格
- 每格为 `MetricCard`，包含图标（SF Symbols）、指标名、数值、单位
- 数值来自 `DailyMetrics`，为 `nil` 时显示 `"--"`

| 卡片 | SF Symbol | 颜色 |
|------|-----------|------|
| 心率 | `heart.fill` | `.red` |
| 体温 | `thermometer.medium` | `.orange` |
| HRV | `waveform.path.ecg` | `.purple` |
| 呼吸 | `lungs.fill` | `.teal` |

#### ④ StatusSummaryView
- 根据 `currentPhase` 从固定文案库匹配一句描述
- MVP 阶段为规则匹配；后期替换为 Claude API 动态生成

#### ⑤ DailyTipsView
- 每个 `CyclePhase` 对应 3 条建议（图标 + 文案），存储在 `switch` 分支内
- 以 `VStack + Divider` 实现列表样式，外层 `RoundedRectangle` 卡片容器

#### ⑥ QuickLinksView
- 两个 `QuickLinkButton`，分别跳转"今晚的睡眠"和"AI 顾问"
- MVP 阶段 Button action 为空，等 Tab 导航与目标页面建立后接入

---

## 5. 导航结构

`ContentView` 作为根视图，使用 `TabView` 管理 4 个一级页面：

| Tab | 标题 | 图标 | 状态 |
|-----|------|------|------|
| 0 | 今天 | `sun.max.fill` | ✅ 完成 |
| 1 | 周期 | `calendar` | 🔲 占位 |
| 2 | 睡眠 | `moon.stars.fill` | 🔲 占位 |
| 3 | AI | `message.fill` | 🔲 占位 |

---

## 6. 数据流

```
SwiftData (本地持久化)
    │
    ├── CycleProfile ──→ CyclePhaseCardView
    │                ──→ StatusSummaryView
    │                ──→ DailyTipsView
    │                ──→ GreetingHeaderView (userName)
    │
    └── DailyMetrics ──→ MetricsGridView
```

- `@Query` 自动监听数据变化，UI 响应式更新
- 当前阶段无需单独存储，由 `CycleProfile` 的计算属性实时推导

---

## 7. MVP 与后期演进路径

| 功能 | MVP（当前） | 后期接入 |
|------|-----------|---------|
| 身体数据来源 | 字段为 nil，显示"--" | HealthKit（心率/HRV/呼吸）+ 耳环传感器（体温） |
| 设备连接状态 | 固定显示"未连接" | BLE 蓝牙低功耗连接状态 |
| 今日状态摘要 | 规则匹配固定文案 | Claude API 动态生成 |
| 周期数据录入 | 需手动在数据库写入 | 引导流程 OnboardingView（待开发） |

---

## 8. 待完成事项

- [ ] **OnboardingView**：用户首次打开 App 时引导录入经期信息（写入 `CycleProfile`）
- [ ] **HealthKit 接入**：在 Xcode Capabilities 开启 HealthKit，读取心率/HRV/呼吸数据
- [ ] **DailyMetrics 写入逻辑**：目前只有模型，缺少触发写入的业务逻辑
- [ ] **CyclePhase 颜色 Asset**：`Assets.xcassets` 中需补充 4 个阶段对应的颜色（`PhaseMenstrual` 等）
- [ ] **QuickLinks 跳转**：等周期/睡眠/AI 页面完成后，接入 Tab 切换逻辑

---

## 9. 开发环境

| 项目 | 版本 |
|------|------|
| 语言 | Swift 6 |
| UI 框架 | SwiftUI |
| 数据层 | SwiftData |
| 最低部署目标 | iOS 17.0+ |
| Xcode | 16.0+ |
