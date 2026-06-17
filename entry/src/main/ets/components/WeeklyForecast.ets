// ─── 7日预报：温度条渐变 + 毛玻璃卡片 ────────────────
import { DailyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { WeatherData } from '../models/WeatherModels'

@Component
export struct WeeklyForecast {
  @Prop daily: DailyWeather[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()

  private getGlobalMin(): number {
    let min = 100
    for (const d of this.daily) {
      if (d.low < min) min = d.low
    }
    return min
  }

  private getGlobalMax(): number {
    let max = -100
    for (const d of this.daily) {
      if (d.high > max) max = d.high
    }
    return max
  }

  build() {
    Column() {
      Text('7日预报')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 4, bottom: 10 })

      Column({ space: 0 }) {
        ForEach(this.daily, (item: DailyWeather, index: number) => {
          Row() {
            // 星期
            Text(index === 0 ? '今天' : item.week)
              .fontSize(14)
              .fontColor(this.themeColors.textColor)
              .width(48)

            // 天气图标
            Text(WeatherData.textToIcon(item.textDay))
              .fontSize(18)
              .width(30)

            // 低温数字
            Text(`${item.low}°`)
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .width(36)
              .textAlign(TextAlign.End)

            // 温度条
            Stack() {
              // 背景条
              Row()
                .width('100%')
                .height(4)
                .borderRadius(2)
                .backgroundColor('rgba(255,255,255,0.1)')

              // 温度条
              Row()
                .width(this.getBarWidth(item))
                .height(4)
                .borderRadius(2)
                .linearGradient({
                  direction: GradientDirection.Right,
                  colors: [['#5AC8FA', 0], ['#FF9500', 1]]
                })
                .margin({ left: this.getBarOffset(item) })
            }
            .layoutWeight(1)
            .margin({ left: 10, right: 10 })

            // 高温数字
            Text(`${item.high}°`)
              .fontSize(14)
              .fontColor(this.themeColors.textColor)
              .width(36)
          }
          .width('100%')
          .height(44)
          .alignItems(VerticalAlign.Center)
          .border({ width: { bottom: index < this.daily.length - 1 ? 0.5 : 0 }, color: 'rgba(255,255,255,0.06)' })
        }, (item: DailyWeather, index: number) => `${index}_${item.date}`)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 16 })
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundColor(this.themeColors.cardBg)
    .borderRadius(24)
    .border({ width: 1, color: this.themeColors.cardBorder })
    .margin({ left: 16, right: 16 })
  }

  private getBarOffset(item: DailyWeather): number {
    const min = this.getGlobalMin()
    const max = this.getGlobalMax()
    const range = max - min
    if (range === 0) return 0
    return (item.low - min) / range * 100
  }

  private getBarWidth(item: DailyWeather): string {
    const min = this.getGlobalMin()
    const max = this.getGlobalMax()
    const range = max - min
    if (range === 0) return '50%'
    return `${(item.high - item.low) / range * 100}%`
  }
}
