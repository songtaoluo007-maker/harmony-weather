// ─── 生活指数网格 ─────────────────────────────────────
import { LifeIndex } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct LifeIndexGrid {
  @Prop lifeIndex: LifeIndex[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()

  build() {
    Column() {
      Text('生活指数')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 4, bottom: 10 })

      Flex({ wrap: FlexWrap.Wrap, space: { main: new LengthMetrics(10), cross: new LengthMetrics(10) } }) {
        ForEach(this.lifeIndex, (item: LifeIndex, index: number) => {
          Column() {
            Text(item.icon)
              .fontSize(24)

            Text(item.name)
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
              .margin({ top: 6 })

            Text(item.brief)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textColor)
              .margin({ top: 4 })
          }
          .width('31%')
          .padding({ top: 14, bottom: 14 })
          .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
          .backgroundColor(this.themeColors.cardBg)
          .borderRadius(16)
          .border({ width: 1, color: this.themeColors.cardBorder })
          .alignItems(HorizontalAlign.Center)
        }, (item: LifeIndex, index: number) => `${index}_${item.name}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}
