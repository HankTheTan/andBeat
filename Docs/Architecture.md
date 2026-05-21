# PULSE App — 模块边界架构设计文档

**版本：** v0.2.0
**创建日期：** 2026-05-21
**适用对象：** 全体开发人员（开发前必读）

---

## 1. 整体目录结构

```
andBeat/andBeat/
│
├── andBeatApp.swift              ← App 入口【项目负责人维护】
├── ContentView.swift             ← Tab 导航根视图【项目负责人维护】
│
├── Core/                         ← 共享层【所有人可读，修改需评审】
│   ├── Models/
│   │   ├── CycleProfile.swift    ← 周期档案数据模型
│   │   └── DailyMetrics.swift    ← 每日身体数据模型
│   └── Services/
│       ├── SupabaseService.swift  ← 云端数据服务单例
│       └── HealthKitService.swift ← HealthKit 数据服务单例
│
└── Features/                     ← 功能模块层【各模块独立负责】
    ├── Today/                    ← 开发人员 A
    │   ├── TodayView.swift
    │   └── TodayViewModel.swift
    ├── Cycle/                    ← 开发人员 B
    │   ├── CycleView.swift
    │   └── CycleViewModel.swift
    ├── Sleep/                    ← 开发人员 C
    │   ├── SleepView.swift
    │   └── SleepViewModel.swift
    └── AI/                       ← 开发人员 D
        ├── AIView.swift
        └── AIViewModel.swift
```

---

## 2. 分层职责定义

### Core 层（共享基础层）

| 子目录 | 职责 | 修改规则 |
|--------|------|---------|
| `Core/Models/` | SwiftData 数据模型定义、枚举、计算属性 | 修改前需通知所有模块开发人员，因为任何字段变更都可能影响其他模块 |
| `Core/Services/` | Supabase / HealthKit 等外部服务的统一封装，以单例形式提供 | 只增加方法，不删除/重命名已有方法，避免破坏其他模块 |

### Features 层（功能模块层）

每个 Feature 文件夹对应一个 Tab 页面，由一名开发人员完全负责：

| 模块 | 文件夹 | Tab 位置 | 负责人 |
|------|--------|---------|--------|
| 今天的你 | `Features/Today/` | Tab 0 | 开发人员 A |
| 周期追踪 | `Features/Cycle/` | Tab 1 | 开发人员 B |
| 今晚的睡眠 | `Features/Sleep/` | Tab 2 | 开发人员 C |
| AI 顾问 | `Features/AI/` | Tab 3 | 开发人员 D |

### App 层（导航入口）

| 文件 | 职责 | 修改规则 |
|------|------|---------|
| `andBeatApp.swift` | 注册 SwiftData 模型、注入环境对象 | 只有 Core/Models 新增模型时才修改，由项目负责人操作 |
| `ContentView.swift` | TabView 导航，连接 4 个 Feature 根视图 | 由项目负责人维护，不允许包含任何业务逻辑 |

---

## 3. 模块边界规则

### ✅ 允许的访问

```
任何模块  →  Core/Models     （读取数据模型定义）
任何模块  →  Core/Services   （调用共享服务）
Today     →  TodayViewModel  （本模块 VM）
Cycle     →  CycleViewModel  （本模块 VM）
Sleep     →  SleepViewModel  （本模块 VM）
AI        →  AIViewModel     （本模块 VM）
```

### ❌ 禁止的访问

```
Today     →  CycleViewModel  （跨模块 ViewModel，禁止）
Cycle     →  TodayView       （跨模块 View，禁止）
Sleep     →  AIViewModel     （跨模块 ViewModel，禁止）
任何模块  →  andBeatApp.swift（不允许反向依赖 App 入口）
```

### 跨模块数据共享的正确方式

如果模块 B（周期）需要模块 A（今天）产生的数据：

```
❌ 错误：CycleViewModel 直接引用 TodayViewModel
✅ 正确：两个模块都从 Core/Models（SwiftData）或 Core/Services 读取同一份数据源
```

---

## 4. 模块内部文件规范

每个 Feature 模块的标准结构：

```
Features/Today/
├── TodayView.swift         ← 纯 UI，只调用本模块 ViewModel，不含业务逻辑
├── TodayViewModel.swift    ← 业务逻辑，调用 Core/Services 获取数据
└── Components/             ← （可选）该模块私有的子组件，不对外暴露
    └── SomeCard.swift
```

**ViewModel 设计规则：**
- 使用 `@Observable`（iOS 17+）
- 通过 `Core/Services` 单例访问外部数据，不直接操作 `HKHealthStore` 或 Supabase 客户端
- 业务逻辑方法使用 `async/await`，不在 ViewModel 内部做 UI 操作

**View 设计规则：**
- `@State private var viewModel = XxxViewModel()` 持有本模块 ViewModel
- `@Query` 直接读取 SwiftData 本地数据，再通过 `viewModel.load()` 传入
- 子组件定义为 `private struct`，不对外暴露
- 每个 View 文件末尾必须有 `#Preview`

---

## 5. Core/Services 使用规范

### SupabaseService

```swift
// 正确用法（在 ViewModel 内调用）
let profile = try await SupabaseService.shared.fetchCycleProfile()

// 错误用法（在 View 内直接调用）
// ❌ 不要在 View 的 body 或 onAppear 里直接调用 SupabaseService
```

### HealthKitService

```swift
// 权限申请：在 andBeatApp.swift 启动时统一申请，各模块无需重复申请
// 数据读取：在各模块 ViewModel 内调用
let hr = await HealthKitService.shared.fetchLatestHeartRate()
```

---

## 6. 模块依赖图

```
┌─────────────────────────────────────────────────────┐
│                    App 层                            │
│  andBeatApp.swift ──→ ContentView.swift              │
└──────────┬──────────────────────────────────────────┘
           │ 引用各模块根 View
┌──────────▼──────────────────────────────────────────┐
│                  Features 层                         │
│                                                      │
│  Today/          Cycle/         Sleep/      AI/      │
│  ├─ View         ├─ View        ├─ View     ├─ View  │
│  └─ ViewModel    └─ ViewModel   └─ ViewModel└─ VM    │
│        │               │              │         │    │
└────────┼───────────────┼──────────────┼─────────┼───┘
         │               │              │         │
┌────────▼───────────────▼──────────────▼─────────▼───┐
│                    Core 层                           │
│                                                      │
│   Models/                    Services/               │
│   ├─ CycleProfile.swift      ├─ SupabaseService      │
│   └─ DailyMetrics.swift      └─ HealthKitService     │
└─────────────────────────────────────────────────────┘
```

---

## 7. Git 工作流建议

```
main            ← 稳定版本，只接受经过测试的 PR
├── dev         ← 集成分支，各模块完成后合并到此
│   ├── feature/today-xxx    ← 开发人员 A 的分支
│   ├── feature/cycle-xxx    ← 开发人员 B 的分支
│   ├── feature/sleep-xxx    ← 开发人员 C 的分支
│   └── feature/ai-xxx       ← 开发人员 D 的分支
└── core/xxx    ← 修改 Core 层时单独开分支，合并前通知所有人
```

**分支命名规则：**
- 功能开发：`feature/<module>-<简短描述>`，例：`feature/today-healthkit`
- Core 层修改：`core/<描述>`，例：`core/add-sleep-model`
- Bug 修复：`fix/<module>-<描述>`

**PR 合并规则：**
- Feature 分支 → dev：需至少 1 人 Review
- Core 分支 → dev：需所有模块开发人员确认不影响自己的模块
- dev → main：需项目负责人最终审批

---

## 8. 各模块当前状态

| 模块 | ViewModel | View | 数据接入 | 文档 |
|------|-----------|------|---------|------|
| Today | ✅ 完成 | ✅ 完成（6个子模块） | 🔲 HealthKit 待接 | ✅ Module1_TodayView_Design.md |
| Cycle | 🔲 骨架 | 🔲 占位 | 🔲 | 🔲 |
| Sleep | 🔲 骨架 | 🔲 占位 | 🔲 | 🔲 |
| AI    | 🔲 骨架 | 🔲 占位 | 🔲 Claude API 待接 | 🔲 |

---

## 9. 新开发人员 Onboarding 检查清单

- [ ] 阅读本文档（Architecture.md）
- [ ] 阅读 Module1_TodayView_Design.md（了解已有实现作为参考）
- [ ] 在 Xcode 中将所有 `Core/` 和 `Features/` 文件加入项目 Target
- [ ] 申请 Apple Developer 账号（HealthKit 真机调试必须）
- [ ] 申请 Supabase 账号，获取 Project URL 和 anon key（AI / 云同步模块需要）
- [ ] 确认只修改自己负责的 `Features/<Module>/` 下的文件
- [ ] 修改 `Core/` 层前，必须在群组内提前告知所有人
