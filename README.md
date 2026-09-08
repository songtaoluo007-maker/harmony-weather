# 原境天气（HarmonyOS）

一款使用 ArkTS Stage 模型实现的现代动态天气应用。提供天气、资讯、设置三个入口，支持逐小时预报、15 日预报、空气质量、生活指数、城市管理、定位、离线缓存及官方原文在线阅读。

背景由三部分实时合成：城市影像、天气/昼夜色彩层、动态天气层。晴天和多云时云层缓慢移动；雨天叠加中远景雨线与前景玻璃水滴，雪天有分层飘雪，关闭“动态天气”后位移动画停止。

首页和设置已移除背景预览、开发配置卡片及大段演示说明，来源与资源署名集中在“关于”。
设置提供温度单位、动态天气、更新频率、城市管理、系统定位权限、天气缓存清理和隐私说明。
资讯连接中国天气网官方移动版新闻与气象科普原站，不打包、抓取或虚构新闻内容。
本轮交付与上线前边界见 [正式产品界面验收](docs/product-shell.md)。

首页下半部分已升级为统一的柔光材质：具象生活插画、六档 AQI 刻度、风向罗盘、
城市当地日照轨迹与紧凑环境指标。保留真实数据与全部原有入口；见
[原生前后对比](design/atmosphere-comparison.jpg) 和 [本轮界面验收](docs/atmosphere-polish.md)。

## 本地天气配置

项目现在默认连接 **Open-Meteo 在线天气**，无需注册、登录或 API 密钥。
当前天气、逐小时、15 日预报与日出日落来自在线气象模型；空气质量为 CAMS
模型估算，明确标记为 **US AQI**，不冒充中国站点实测。

免费端点限非商业用途并有调用额度，不提供可用性保证；正式商用应选择付费套餐
或其他获授权的数据源。详情见 [官方价格与使用范围](https://open-meteo.com/en/pricing)。
网络失败时只读取同一数据源、同一城市的真实缓存并显示“离线数据”；无缓存则失败重试，
不会自动替换成演示数据。只有显式设置 `provider: "mock"` 才用于演示；选择和风却缺少
凭据时会报告配置错误，不会悄悄改为模拟数据。

如需改回和风天气（此轮无密钥，尚未实测该账户接口）：

1. 复制根目录的 `weather_config.local.example.json`。
2. 填入自己的和风天气 API Key，以及控制台分配的专属 API Host；保留 `provider: "qweather"`。
3. 将文件放到 `entry/src/main/resources/rawfile/weather_config.local.json`。

该文件已加入 `.gitignore`。客户端密钥仍可能从安装包中提取，正式发布建议使用服务端代理。
本地文件优先于默认配置；切回免费源时删除本地覆盖文件或将其 provider 改为 `openmeteo`。
完整说明见 [在线天气与动态场景](docs/live-weather-scenes.md)。

已补回风速数值、六项污染物、原有六个生活入口、夜间预报、雪粒动画与加载骨架。
旅游/感冒无可靠指数时显示暂无数据，温差独立展示；其他生活提示仍为本地规则。
夜间预报依据日落至次日日出的逐小时数据汇总，不直接复制全天概况。
功能保留清单与验收范围见 [功能补回报告](docs/feature-restoration.md)。

## 构建

在 DevEco Studio 中选择 `entry > default` 并运行 `assembleHap`。当前验证 SDK：`6.1.1(24)`；生成的未签名 HAP 位于：

`entry/build/default/outputs/default/entry-default-unsigned.hap`

命令行构建建议使用 `powershell -ExecutionPolicy Bypass -File scripts/build-hap.ps1`。脚本会从本机 `local.properties` 读取 SDK 与 Node 路径，并为当前进程设置 `DEVECO_SDK_HOME`；如果 Hvigor 守护进程继承了旧环境，可追加 `-RestartDaemon`。

正式签名信息属于本机或 CI 环境配置，不应提交到仓库。

## 视觉与资源

- 最新首页卡片：[design/atmosphere-comparison.jpg](design/atmosphere-comparison.jpg)
- 正式产品入口：[design/product-shell.jpg](design/product-shell.jpg)（首页卡片为此次改造前）
- 当前青岛夜间云层实录：[design/product-cloud-motion.gif](design/product-cloud-motion.gif)（真实天气，无预览覆盖）
- 以下预览/演示截图为之前阶段的历史证据；正式界面已不提供背景预览入口。
- 选定视觉稿：[design/originos-weather-target.png](design/originos-weather-target.png)
- 2026-09 原生界面总览：[design/redesign-overview.jpg](design/redesign-overview.jpg)
- 当前在线天气 / 城市夜景 / 白天雨景：[design/live-weather-scenes.jpg](design/live-weather-scenes.jpg)
- 功能补回原生截图：[design/feature-restoration.jpg](design/feature-restoration.jpg)
- 原生飘雪动态采样：[design/parity-snow-motion.gif](design/parity-snow-motion.gif)（明确标注的背景预览）
- 深圳自动夜景：[design/live-shenzhen-night.jpeg](design/live-shenzhen-night.jpeg)
- 生活气象：[design/redesign-life-final.jpeg](design/redesign-life-final.jpeg)
- 白天雨景实际动态采样：[design/live-day-rain-motion.gif](design/live-day-rain-motion.gif)（明确标注的背景预览）
- 本轮设计说明与后续优先级：[docs/ui-redesign-2026-09.md](docs/ui-redesign-2026-09.md)
- 实际验证范围与限制：[design-qa.md](design-qa.md)
- 城市影像按稳定城市 ID 与昼夜自动切换；当前 15 个城市的白天、夜间照片均已离线打包。
- 夜间使用有真实建筑灯光的夜景/暮色照片，不再只是调暗白天照片；照片不是实时摄像头。
- 城市列表变化后，运行 `scripts/fetch_city_backgrounds.py` 可一次性更新全部城市影像和 ArkTS 映射，无需逐城制作。
- 城市影像来源见 [CITY_BACKGROUND_SOURCES.md](CITY_BACKGROUND_SOURCES.md)。
- 夜景批量下载与映射：`powershell -File scripts/fetch-night-backgrounds.ps1 -Download`；来源和许可见 [CITY_NIGHT_SOURCES.md](CITY_NIGHT_SOURCES.md)。
- 图标来源和许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

## 状态测试

使用 DevEco 自带 Node 执行 `node --test scripts/test-weather-state.cjs scripts/test-news.cjs scripts/test-page-lifecycle.cjs scripts/test-instruments.cjs`。脚本通过
DevEco TypeScript 加载真实模型与 Service，只替换平台 I/O；这不等同于真实 API
联调。若使用外部 Node，请将 `DEVECO_STUDIO_HOME` 指向 DevEco 安装目录。
