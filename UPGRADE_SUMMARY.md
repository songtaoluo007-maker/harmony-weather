# 鸿蒙天气 · 完整升级方案 — 执行清单

## 📁 新文件清单（已全部创建）

```
entry/src/main/
├── module.json5                          ← Stage 模块配置（替代 config.json）
├── entryability/
│   └── EntryAbility.ets                  ← UIAbility 入口
├── pages/
│   ├── Index.ets                         ← 主页：全屏沉浸式天气仪表盘
│   └── CitySelector.ets                  ← 城市选择：毛玻璃网格 + 搜索
├── models/
│   └── WeatherModels.ets                 ← 数据模型（7个类 + 枚举）
├── theme/
│   └── WeatherTheme.ets                  ← 动态主题系统（天气×时段）
├── services/
│   └── WeatherService.ets                ← 数据服务（缓存 + 预留 API）
├── components/
│   ├── GlassCard.ets                     ← 毛玻璃卡片基类
│   ├── BreathingBackground.ets           ← 呼吸背景（渐变+光晕+粒子）
│   ├── HeroSection.ets                   ← Hero 区（城市+温度+天气）
│   ├── HourlyCapsules.ets               ← 逐小时胶囊横滑
│   ├── WeeklyForecast.ets               ← 7日预报 + 温度条
│   ├── AirQualityCard.ets               ← 空气质量环形进度
│   ├── LifeIndexGrid.ets                ← 生活指数 6 宫格
│   └── DataGrid.ets                     ← 风速/湿度/能见度/气压
└── resources/
    ├── base/
    │   ├── element/color.json            ← 颜色资源
    │   ├── element/string.json           ← 字符串资源
    │   └── profile/main_pages.json       ← 页面路由
    └── rawfile/
        └── mock_weather.json             ← 模拟天气数据

配置变更：
├── entry/build-profile.json5             ← apiType: faMode → stageMode
├── entry/src/main/config.json            ← 已备份为 config.json.bak
└── entry/src/main/js/                    ← 旧 FA 代码（保留参考）
```

---

## 🎨 视觉效果清单

### 1. 呼吸背景（BreathingBackground）
- **Layer 1**：天气渐变（晴天暖橙→粉红 / 雨天深灰→蓝 / 夜晚靛蓝→紫）
- **Layer 2**：呼吸光晕（正弦波 5s 周期，opacity 0.25↔0.40，scale 0.97↔1.03）
- **Layer 3**：粒子系统（晴天 25 个光点漂浮 / 雨天 60 个雨滴下落 / 雪天 40 片雪花飘落）
- **时段自适应**：黎明暖橙、白天明亮、黄昏深紫、夜晚靛蓝

### 2. Hero 区（HeroSection）
- 96sp 极细体温度，入场弹性缩放（0.8→1.0）
- stagger 动画：城市名 200ms → 温度 350ms → 描述 500ms → 详情 650ms

### 3. 逐小时胶囊（HourlyCapsules）
- 横向滚动，选中态毛玻璃高亮（25% 白 + 1px 边框）
- 点击回弹动画

### 4. 7日预报（WeeklyForecast）
- 温度条渐变映射（低温 #5AC8FA 蓝 → 高温 #FF9500 橙）
- 按全局最低/最高动态计算宽度和偏移

### 5. 空气质量（AirQualityCard）
- 环形进度（绿/橙/红/紫按 AQI 等级）
- PM2.5/PM10/NO₂/SO₂/CO/O₃ 6 项污染物

### 6. 生活指数（LifeIndexGrid）
- 3×2 宫格：穿衣/运动/紫外线/洗车/旅游/感冒
- 每格独立毛玻璃卡片 + 入场 stagger

---

## 🔧 架构变更对比

| 维度 | 旧（FA） | 新（Stage） |
|------|---------|------------|
| 入口 | MainAbility (JS) | EntryAbility.ets (ArkTS) |
| 配置 | config.json | module.json5 |
| UI | .hml + .css + .js | ArkTS 声明式 |
| 状态 | JS 全局单例 + dataStorage | @State/@Link + AppStorage |
| 路由 | @ohos.router (FA) | @ohos.router (Stage) |
| 提示 | @system.prompt | promptAction |
| 存储 | @system.dataStorage | @ohos.data.preferences |
| 背景 | 静态图片 | 3 层动态 Canvas |
| 动画 | CSS transition | animateTo + Canvas 60fps |

---

## ▶️ 下一步

1. 用 DevEco 6.0 打开项目，Sync & Build
2. 模拟器运行验证视觉效果
3. 按需调参（粒子密度、呼吸速度、颜色值）
4. 接入真实天气 API（WeatherService 中预留了接口）
5. 桌面卡片（FormExtensionAbility）迁移
