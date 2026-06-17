// ─── 毛玻璃卡片：所有内容卡片的基类 ────────────────
// 使用 @BuilderParam 装饰器接收外部 Builder 内容
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct GlassCard {
  @Prop blurRadius: number = 20
  @Prop opacity: number = 0.12
  @Prop borderRadius: number = 24
  @Prop paddingH: number = 16
  @Prop paddingV: number = 16
  @Prop themeColors: ThemeColors = new ThemeColors()

  // 使用 @BuilderParam 装饰器接收外部传入的 Builder 内容
  @BuilderParam content: () => void = this.defaultContent

  // 默认空内容，调用方可通过 Builder 传入自定义内容
  @Builder
  defaultContent() {}

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding({ left: this.paddingH, right: this.paddingH, top: this.paddingV, bottom: this.paddingV })
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundColor(this.themeColors.cardBg)
    .borderRadius(this.borderRadius)
    .border({ width: 1, color: this.themeColors.cardBorder })
    .shadow({
      radius: 32,
      color: 'rgba(0,0,0,0.12)',
      offsetY: 8,
      shadowType: ShadowType.COLOR
    })
  }
}
