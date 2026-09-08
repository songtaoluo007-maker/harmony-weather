# 首页下半屏 · 材质与天气仪表

2026-09-08。用户确认保留城市景观，改善向下滚动后的视觉落差。

## 改动

- 按 Product UI Design 统一柔和青绿、暖金、暖白、细描边、24vp 圆角与数字/单位层级。
  材质为透明渐变，叠在现有天气色板上；无新增依赖或重模糊效果。
- 生活气象保留三张原有具象插画和全部七个入口。插画卡片统一裁切/渐隐/排版；
  其余入口合为紧凑 2×2 组。缺失指数弱化但仍可点击，未补造评分。
- 风向与风速合为罗盘面板；日出与日落合为日照轨迹；湿度/降水一组，
  能见度/气压/云量一组。原有八项详情数据全部保留。
- AQI 显示实际指数对应的六档位置，六项污染物和各自单位保留，CO 仍为 mg/m³。
- `WeatherInstruments` 从已有数据计算绘图数值：未知风向不画北向箭头，
  AQI 按非等距阈值分档，日照按城市日期与当天日出/日落时间计算。
  夜间不画太阳光点，旧日期/无效日出日落不伪造轨迹位置。
- `InstrumentDial` 使用实测 Canvas 尺寸，仅在数据/布局改变时重绘。
  日照复用首页现有分钟时钟；没有增加帧循环或更改城市动态场景。
- 生活入口使用语义 Button；装饰刻度不参与读屏，日照描述包含当前时段。

## 原生证据

截图均为 Pura 90 模拟器的实际 ArkUI 页面，不是生成图或网页仿制。
天气保持默认在线数据源，青岛当地约 22:38，未修改设备时间或注入演示天气。
系统状态栏使用 12 小时制；页面使用城市当地 24 小时制。

- [前后对比](../design/atmosphere-comparison.jpg)：同一台设备，本次改造前后；天气随时间略有变化。
- [保留的城市首页](../design/atmosphere-home.jpeg)
- [空气质量](../design/atmosphere-air.jpeg)、[生活气象](../design/atmosphere-life.jpeg)、
  [风与日照](../design/atmosphere-details.jpeg)、[底部完整指标](../design/atmosphere-metrics.jpeg)
- [空气详情](../design/atmosphere-air-dialog.jpeg)、[穿衣详情](../design/atmosphere-life-dialog.jpeg)、
  [缺失旅游指数](../design/atmosphere-unavailable.jpeg)：实际点击，原数据/解释保留。
- 320vp 父容器 / 1.3× 字体组合检查：
  [生活卡片](../design/atmosphere-320-life.jpeg)、[风与日照](../design/atmosphere-320-details.jpeg)、
  [底部指标](../design/atmosphere-320-metrics.jpeg)。右侧白带是窄容器之外的测试窗口，
  不是交付布局。截图记录布局修正后的检查，最终正常宽度版本另做单位和文本对齐微调。
  临时宽度/字体钩子全部移除，最终 HAP 恢复设备宽度及正常字体。

## 验证与边界

- 59 项真实模型/Service/页面方法测试通过。新增 7 项仪表测试先失败再修复，
  覆盖八风向/未知风向、百分比边界、AQI 阈值/位置、日出/正午/日落/夜间、
  旧日期与异常端点、负 UTC 偏移。平台 I/O 使用测试替身，不冒充接口端到端测试。
- Hvigor `assembleHap`，SDK `6.1.1(24)` 成功；未签名 HAP 安装/启动成功。
- 原生约 377vp 滚动、数值和单位、卡片边界、插画、夜间日照图及详情点击检查完成。
  320vp/大字体检查修正了插画卡片高度不齐、按钮圆角和风速单位挤向罗盘的问题。
- 独立只读代码审查未发现重要回归；已修正 AQI 端点与当前日照的可访问描述。
- 不新增天气源、不改变缓存、设置、资讯、城市或密钥配置；未删除功能。
  日照弧线表示白昼时间进度，不是实际太阳高度角或太阳方位。
- 新版全尺寸/横屏/平板、原生白昼光点、完整读屏遍历、真实设备长时性能仍待验证。
  既有商业 API 授权、正式签名和上线审查边界不变；本轮不是企业级发布认证。

复现：使用 DevEco Node 运行 README 所列四个测试文件，再执行
`powershell -ExecutionPolicy Bypass -File scripts/build-hap.ps1`。
截图对比只做等比缩放、标注和排列：`python scripts/design-evidence.py atmosphere-board`。
