// ─── 逐小时胶囊：横向滚动天气预报 ────────────────────
import { HourlyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct HourlyCapsules {
  @Prop hourly: HourlyWeather[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()
  @State selectedIndex: number = 0

  build() {
    Column() {
      // 标题
      Text('逐时预报')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 4, bottom: 10 })

      // 横向滚动胶囊
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.hourly, (item: HourlyWeather, index: number) => {
            Column() {
              Text(index === 0 ? '现在' : item.time)
                .fontSize(12)
                .fontColor(index === 0 ? this.themeColors.textColor : this.themeColors.textSecondary)

              Text(item.icon)
                .fontSize(22)
                .margin({ top: 8 })

              Text(`${item.temp}°`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textColor)
                .margin({ top: 6 })
            }
            .width(64)
            .padding({ top: 14, bottom: 14 })
            .borderRadius(20)
            .backgroundColor(
              index === this.selectedIndex ? 'rgba(255,255,255,0.25)' : 'rgba(255,255,255,0.08)'
            )
            .border({
              width: index === this.selectedIndex ? 1 : 0,
              color: 'rgba(255,255,255,0.4)'
            })
            .onClick(() => {
              this.selectedIndex = index
            })
            .scale({ x: index === this.selectedIndex ? 1 : 0.95, y: index === this.selectedIndex ? 1 : 0.95 })
            .animation({ duration: 200, curve: Curve.EaseOut })
          }, (item: HourlyWeather, index: number) => `${index}_${item.time}_${item.temp}`)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundColor(this.themeColors.cardBg)
    .borderRadius(24)
    .border({ width: 1, color: this.themeColors.cardBorder })
    .margin({ left: 16, right: 16 })
  }
}
