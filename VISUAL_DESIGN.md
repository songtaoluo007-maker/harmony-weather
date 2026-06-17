# 🌤 鸿蒙天气 · 视觉系统设计文档
## Landing Page 官网式 + 动态视觉系统

---

## 一、设计哲学

**核心理念：「天气即画布」**

抛弃传统天气 App 的卡片堆叠，采用 **全屏沉浸式** 设计——
整个屏幕就是一块动态画布，天气数据以 **浮动图层** 的形式叠加其上，
像一个会呼吸的天气仪表盘。

参考风格：
- Apple Weather（动态天气背景 + 毛玻璃卡片）
- Nothing Weather（极简 + 几何粒子）
- Linear 官网（渐变光效 + 微动效）
- Stripe 官网（流体渐变 + 精致排版）

---

## 二、动态背景系统（呼吸背景）

### 2.1 天气场景映射

每种天气类型对应一套 **渐变色 + 粒子效果 + 光晕动画**：

| 天气 | 主渐变 | 辅助色 | 粒子效果 | 光晕 |
|------|--------|--------|----------|------|
| ☀️ 晴天 | `#FF9500 → #FF5E3A → #FF2D55` | 金色光斑 | 漂浮光点 | 太阳光晕（脉冲呼吸） |
| 🌤 晴转多云 | `#4A90D9 → #74B9FF → #A8D8EA` | 白色云朵 | 缓慢漂移的云 | 柔和日光 |
| ☁️ 多云 | `#636e72 → #b2bec3 → #dfe6e9` | 灰白色 | 多层云雾漂移 | 扩散柔光 |
| 🌧 小雨 | `#2d3436 → #636e72 → #74b9ff` | 水滴蓝 | 雨滴粒子下落 | 水面涟漪 |
| ⛈ 雷阵雨 | `#0c0c1d → #1a1a2e → #16213e` | 闪电紫 | 雨滴 + 随机闪电 | 电弧光效 |
| 🌨 雪天 | `#e8eaf6 → #c5cae9 → #9fa8da` | 雪白 | 雪花飘落（不同大小/速度） | 冰晶折射 |
| 🌫 雾霾 | `#a0a0a0 → #c0c0c0 → #d5d5d5` | 浑浊灰 | 缓慢流动的雾气 | 无光晕 |
| 🌙 夜晚晴 | `#0f0c29 → #302b63 → #24243e` | 星光 | 闪烁星星 + 流星 | 月光光晕 |

### 2.2 呼吸动画核心算法

```
背景渐变不是静态的，而是通过 3 层叠加实现「呼吸感」：

Layer 1 — 基础渐变层（静态，决定主色调）
Layer 2 — 光晕层（正弦波脉冲，周期 4-6 秒，模拟呼吸）
Layer 3 — 粒子层（独立运动，与呼吸节奏错开）

呼吸公式：
  opacity = 0.3 + 0.15 * sin(time * 2π / breatheCycle)
  scale = 1.0 + 0.05 * sin(time * 2π / breatheCycle + π/3)
  
  // 三层正弦波叠加，相位各差 120°，产生有机感
```

### 2.3 时间段影响

同一天气类型，不同时间段色调不同：

| 时段 | 色温 | 效果 |
|------|------|------|
| 🌅 黎明 (5:00-7:00) | 暖橙→粉紫渐变 | 日出光晕从底部升起 |
| ☀️ 白天 (7:00-17:00) | 明亮饱和 | 正常呼吸效果 |
| 🌇 黄昏 (17:00-19:00) | 深橙→深紫渐变 | 夕阳光晕从右侧消退 |
| 🌙 夜晚 (19:00-5:00) | 深蓝→靛蓝 | 星空粒子 + 月光 |

---

## 三、布局系统（Landing Page 风格）

### 3.1 整体结构

```
┌─────────────────────────────────────┐
│          动态背景（全屏画布）          │
│  ┌─────────────────────────────┐    │
│  │     ① Hero 区（核心信息）     │    │
│  │     城市名 + 温度 + 天气状态    │    │
│  │     体感温度 · 最高/最低       │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     ② 逐小时横滑条（胶囊）     │    │
│  │  [14°晴] [13°多] [12°阴] →→→  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     ③ 7日预报（毛玻璃卡片）     │    │
│  │  今天  晴  ████████░░  25/18  │    │
│  │  周二  多云 ██████░░░░  26/19  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ ④ 空气质量 │  │ ⑤ 生活指数 │        │
│  │  AQI 50  │  │ 🏃 适宜  │        │
│  │   优     │  │ ☀️ 中等  │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │     ⑥ 附加信息（风速/湿度等）    │    │
│  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ │    │
│  │  │ 💨 │ │ 💧 │ │ 👁 │ │ 🌡 │ │    │
│  │  │风速 │ │湿度 │ │能见度│ │气压 │ │    │
│  │  └────┘ └────┘ └────┘ └────┘ │    │
│  └─────────────────────────────┘    │
│                                     │
│  ⑦ 底部信息栏（数据来源/更新时间）     │
└─────────────────────────────────────┘
```

### 3.2 毛玻璃卡片设计

```css
/* 毛玻璃卡片核心样式 */
GlassCard {
  background: rgba(255, 255, 255, 0.12)      /* 半透明白 */
  backdropBlur: 20                           /* 高斯模糊 20 */
  border: 1px solid rgba(255, 255, 255, 0.18) /* 微白边框 */
  borderRadius: 24                           /* 大圆角 */
  shadow: 0 8px 32px rgba(0, 0, 0, 0.12)     /* 柔和阴影 */
}

/* 深色文字（浅色背景时用） */
GlassCard-Dark {
  background: rgba(0, 0, 0, 0.2)
  backdropBlur: 24
  border: 1px solid rgba(255, 255, 255, 0.08)
}
```

### 3.3 温度数字设计

Hero 区的温度是视觉焦点：

```
设计参数：
  字号: 96sp（主温度）
  字重: FontWeight 200（极细体，高级感）
  颜色: #FFFFFF（纯白）
  阴影: 0 2px 20px rgba(0,0,0,0.15)
  
  动画: 页面进入时从 opacity 0 → 1 + translateY(20 → 0)
        缓动: cubic-bezier(0.16, 1, 0.3, 1)（弹性出）
```

---

## 四、组件视觉规范

### 4.1 Hero 区（核心展示）

```
┌──────────────────────────────┐
│           深圳市              │  ← 18sp, rgba(255,255,255,0.7)
│                              │
│           26°                │  ← 96sp, #FFFFFF, 极细体
│                              │
│           晴                 │  ← 20sp, #FFFFFF
│                              │
│    体感 24° · 最高 28° 最低 19° │  ← 14sp, rgba(255,255,255,0.6)
└──────────────────────────────┘

动画：温度数字有微弱的「呼吸」效果
  scale: 1.0 ↔ 1.02（周期 4s，与背景呼吸同步）
```

### 4.2 逐小时胶囊

```
┌──────────────────────────────────────────┐
│  [ 现在 ]  [ 14时 ]  [ 15时 ]  [ 16时 ]  │  ← 横向滚动
│   ☀️        ☀️       🌤        ☁️       │
│   26°      25°      24°       23°      │
└──────────────────────────────────────────┘

胶囊样式：
  宽: 64dp, 高: 96dp
  背景: 选中 → rgba(255,255,255,0.25), 未选 → rgba(255,255,255,0.08)
  圆角: 20dp
  边框: 选中 → 1px rgba(255,255,255,0.4), 未选 → 无
  
  选中动画: scale 0.95 → 1.0, 200ms
```

### 4.3 7日预报卡片

```
┌─────────────────────────────────────────┐
│  今天    ☀️    ████████░░░░░░  28° / 19° │
│  周二    🌤    ██████░░░░░░░░  27° / 20° │
│  周三    ☁️    ████░░░░░░░░░░  25° / 18° │
│  周四    🌧    ██░░░░░░░░░░░░  22° / 16° │
│  周五    🌤    ██████░░░░░░░░  26° / 19° │
└─────────────────────────────────────────┘

温度条设计：
  总宽度: 按比例映射（全局最低 → 全局最高）
  高温色: #FF9500（暖橙）
  低温色: #5AC8FA（天蓝）
  渐变: 低温色 → 高温色
  高度: 4dp, 圆角: 2dp
  背景条: rgba(255,255,255,0.1)
```

### 4.4 数据网格（风速/湿度/能见度/气压）

```
┌──────────┐ ┌──────────┐
│  💨 风速  │ │  💧 湿度  │
│   12km/h │ │   65%    │
│  东南风   │ │          │
└──────────┘ └──────────┘
┌──────────┐ ┌──────────┐
│  👁 能见度│ │  🌡 气压  │
│   15km   │ │  1015hPa │
│          │ │          │
└──────────┘ └──────────┘

样式：
  2×2 网格
  每格: 毛玻璃卡片, padding 16dp
  数字: 28sp, #FFFFFF, FontWeight 600
  标签: 12sp, rgba(255,255,255,0.5)
  图标: 16sp
```

---

## 五、动效系统

### 5.1 页面进入动画

```
时序（stagger 出场）：
  0ms   — 背景渐变开始过渡
  200ms — 城市名 fade in + slide up
  350ms — 温度数字 fade in + scale up（弹性）
  500ms — 天气描述 fade in
  650ms — 逐小时胶囊依次滑入（每项 80ms 间隔）
  900ms — 7日卡片从底部 slide up
  1100ms — 数据网格卡片依次 fade in（每项 100ms）
  1300ms — 底部信息 fade in

缓动函数: cubic-bezier(0.16, 1, 0.3, 1) — 弹性出场
```

### 5.2 天气切换动画

```
当城市切换或天气更新时：
  1. 当前内容 fade out + scale(1 → 0.95), 300ms
  2. 背景渐变 morph 过渡, 800ms（色值插值）
  3. 新内容 fade in + scale(0.95 → 1), 300ms
  
  背景过渡使用 HSL 色彩空间插值，避免中间灰色
```

### 5.3 微交互

| 交互 | 效果 |
|------|------|
| 下拉刷新 | 背景渐变拉伸 + 温度数字上移 + 加载指示器（旋转天气图标） |
| 卡片点击 | scale(1 → 0.97) 回弹，展开详情 |
| 城市切换 | 背景色平滑 morph，内容 stagger 出场 |
| 温度更新 | 数字滚动动画（旧值→新值） |
| 天气图标 | 微动画（太阳旋转、云漂移、雨滴下落） |

---

## 六、ArkTS 技术实现要点

### 6.1 呼吸背景核心代码架构

```typescript
@Component
struct BreathingBackground {
  @State breathePhase: number = 0
  @Link weatherType: WeatherType
  
  // 3层Canvas叠加
  build() {
    Stack() {
      // Layer 1: 基础渐变
      Canvas() { /* 绘制主渐变 */ }
      
      // Layer 2: 呼吸光晕
      Canvas() { /* 正弦波驱动的光晕 */ }
        .opacity(this.getBreatheOpacity())
        .scale({ x: this.getBreatheScale(), y: this.getBreatheScale() })
      
      // Layer 3: 粒子系统
      ParticleCanvas({ weatherType: this.weatherType })
    }
  }
  
  // 正弦波呼吸
  private getBreatheOpacity(): number {
    return 0.3 + 0.15 * Math.sin(this.breathePhase * 2 * Math.PI / BREATHE_CYCLE)
  }
  
  // 定时器驱动
  aboutToAppear() {
    this.startBreathing()
  }
}
```

### 6.2 粒子系统架构

```typescript
// 粒子基类
class Particle {
  x: number; y: number
  vx: number; vy: number
  size: number; opacity: number
  life: number; maxLife: number
}

// 雨滴粒子（高速下落 + 拉长）
class RainParticle extends Particle { ... }

// 雪花粒子（慢速飘落 + 旋转）
class SnowParticle extends Particle { ... }

// 光点粒子（漂浮 + 呼吸）
class GlowParticle extends Particle { ... }

// Canvas 驱动
@Component
struct ParticleCanvas {
  private particles: Particle[] = []
  private animator: Animator = null
  
  aboutToAppear() {
    this.initParticles()
    this.animator = new Animator(60) // 60fps
    this.animator.onFrame = (dt) => {
      this.updateParticles(dt)
      this.invalidate() // 触发重绘
    }
    this.animator.start()
  }
}
```

### 6.3 毛玻璃卡片

```typescript
@Component
struct GlassCard {
  @Prop blurRadius: number = 20
  @Prop opacity: number = 0.12
  @Prop borderRadius: number = 24
  
  build() {
    Column() {
      // children
    }
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundColor(`rgba(255,255,255,${this.opacity})`)
    .borderRadius(this.borderRadius)
    .border({ width: 1, color: `rgba(255,255,255,0.18)` })
    .shadow({ radius: 32, color: 'rgba(0,0,0,0.12)', offsetY: 8 })
  }
}
```

### 6.4 温度滚动数字

```typescript
@Component
struct RollingTemperature {
  @State displayTemp: number = 0
  @Prop targetTemp: number = 0
  
  // 数字滚动动画
  aboutToAppear() {
    animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
      this.displayTemp = this.targetTemp
    })
  }
  
  build() {
    Text(`${Math.round(this.displayTemp)}°`)
      .fontSize(96)
      .fontWeight(FontWeight.Thin)
      .fontColor('#FFFFFF')
  }
}
```

---

## 七、色彩令牌系统

```typescript
// 根据天气类型 + 时间段动态计算
class WeatherTheme {
  // 获取主渐变色
  static getGradient(type: WeatherType, hour: number): string[] {
    const isNight = hour < 6 || hour > 19
    
    const themes: Record<WeatherType, { day: string[], night: string[] }> = {
      sunny:     { day: ['#FF9500','#FF5E3A','#FF2D55'], night: ['#0f0c29','#302b63','#24243e'] },
      cloudy:    { day: ['#636e72','#b2bec3','#dfe6e9'], night: ['#1a1a2e','#16213e','#0f3460'] },
      rainy:     { day: ['#2d3436','#636e72','#74b9ff'], night: ['#0c0c1d','#1a1a2e','#16213e'] },
      snowy:     { day: ['#e8eaf6','#c5cae9','#9fa8da'], night: ['#2c3e50','#34495e','#4a6fa5'] },
      stormy:    { day: ['#2d3436','#636e72','#6c5ce7'], night: ['#0c0c1d','#1a1a2e','#6c5ce7'] },
      foggy:     { day: ['#a0a0a0','#c0c0c0','#d5d5d5'], night: ['#2c3e50','#34495e','#7f8c8d'] },
    }
    
    return isNight ? themes[type].night : themes[type].day
  }
}
```

---

## 八、性能预算

| 指标 | 目标 |
|------|------|
| 首帧渲染 | < 300ms |
| 背景动画帧率 | 稳定 60fps |
| 粒子数量上限 | 晴天 30 / 雨天 80 / 雪天 60 |
| 内存占用 | < 80MB |
| 主线程阻塞 | 0（动画全部异步） |

---

## 九、与现有代码的映射关系

| 原 hml 组件 | 新 ArkTS 组件 | 视觉变化 |
|-------------|--------------|---------|
| briefWeatherInfo | HeroSection | 全屏沉浸 + 呼吸动画 |
| timeWeather | HourlyCapsules | 横滑胶囊 + 选中态 |
| weeklyWeather | WeeklyForecast | 温度条渐变 + 毛玻璃 |
| qualityWeather | AirQualityCard | 环形进度 + 色彩映射 |
| livingIndex | LifeIndexGrid | 2×N 网格 + 图标动画 |
| windPointer | WindCompass | SVG 风向标 + 旋转动画 |
| hourlyTempChart | TempCurveChart | Canvas 曲线 + 填充渐变 |
| title | TopBar | 透明背景 + 城市切换入口 |

---

*设计稿完成。下一步：选择一个天气场景开始实现。*
