# 原境天气（HarmonyOS）

一款使用 ArkTS Stage 模型实现的现代动态天气应用。界面以沉浸式城市天气背景为核心，支持逐小时预报、15 日预报、空气质量、生活指数、城市管理、定位、离线缓存和显示设置。

背景由三部分实时合成：城市影像、天气/昼夜色彩层、动态天气层。晴天和多云时云层缓慢移动；雨天会叠加中远景下落雨线与前景玻璃水滴，关闭“动态效果”后所有位移动画停止。

## 本地天气配置

项目默认使用 `mock_weather.json`，因此没有 API 密钥也能完整运行。

如需接入和风天气：

1. 复制根目录的 `weather_config.local.example.json`。
2. 填入自己的和风天气 API Key。
3. 将文件放到 `entry/src/main/resources/rawfile/weather_config.local.json`。

该文件已加入 `.gitignore`。客户端密钥仍可能从安装包中提取，正式发布建议使用服务端代理。

## 构建

在 DevEco Studio 中选择 `entry > default` 并运行 `assembleHap`。当前验证 SDK：`6.1.1(24)`；生成的未签名 HAP 位于：

`entry/build/default/outputs/default/entry-default-unsigned.hap`

正式签名信息属于本机或 CI 环境配置，不应提交到仓库。

## 视觉与资源

- 选定视觉稿：[design/originos-weather-target.png](design/originos-weather-target.png)
- 深圳日间实现截图：[design/implementation-shenzhen-day-v2.jpeg](design/implementation-shenzhen-day-v2.jpeg)
- 北京切换截图：[design/implementation-beijing-dynamic.jpeg](design/implementation-beijing-dynamic.jpeg)
- 雨景动态预览：[design/rain-dynamic-preview.gif](design/rain-dynamic-preview.gif)
- 城市影像会按稳定城市 ID 自动切换；当前配置中的 15 个城市均已离线打包。
- 城市列表变化后，运行 `scripts/fetch_city_backgrounds.py` 可一次性更新全部城市影像和 ArkTS 映射，无需逐城制作。
- 城市影像来源见 [CITY_BACKGROUND_SOURCES.md](CITY_BACKGROUND_SOURCES.md)。
- 图标来源和许可证见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
