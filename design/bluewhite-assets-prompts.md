# 蓝白生活插画编辑记录

2026-09-09，使用内置 Image Gen 编辑项目已有插画，不是重制城市背景。
三个 PNG 均经读取确认具有真实 RGBA 透明通道（alpha 最小 0、最大 255），
尺寸 1254 × 1254；原版文件保留，新的组件引用 `*_cutout.png`。

| 原始项目资源 | 新输出（相对于 `entry/src/main/resources/base/media/`） |
| --- | --- |
| life_clothing.png | life_clothing_cutout.png |
| life_uv.png | life_uv_cutout.png |
| life_sport.png | life_sport_cutout.png |

## 完整提示词模板

三个独立编辑请求使用以下提示词，仅替换 `[subject]`。输出未做后续图像内容修饰。

```text
Edit this existing weather-app illustration as a production PNG cutout asset. Preserve the exact subject, composition, scale, soft premium realistic material texture and all object details: [subject]. Remove the entire dark teal background and floor; output GENUINE TRANSPARENT ALPHA background, NOT a checkerboard drawing, NOT white background. Keep a very subtle soft contact shadow only immediately below object, no colored backdrop, no border, no text. Square composition, entire object comfortably within the canvas with approximately 10 percent padding. This will be shown on both white and dark blue UI cards.
```

`[subject]` 的逐项内容：

- clothing: `folded light blue shirt on its small pale circular pedestal`
- uv: `unbranded pale sunscreen tube and small amber sun medallion`
- sport: `single textured running shoe, change its sage-green knit subtly to desaturated ice-blue / blue-gray with a white sole to suit a blue-white interface`

原生卡片上的底色、渐变及文字仍由 ArkUI 渲染，不烘焙到 PNG。
