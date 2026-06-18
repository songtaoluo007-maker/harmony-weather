import { DailyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { WeatherIcon } from './WeatherIcon'

@Component
export struct WeeklyForecast {
  @Prop daily: DailyWeather[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private getGlobalMin(): number {
    let value: number = 100
    this.daily.forEach((item: DailyWeather) => {
      if (item.low < value) value = item.low
    })
    return value === 100 ? 0 : value
  }

  private getGlobalMax(): number {
    let value: number = -100
    this.daily.forEach((item: DailyWeather) => {
      if (item.high > value) value = item.high
    })
    return value === -100 ? 1 : value
  }

  private getBarWidth(item: DailyWeather): number {
    const range: number = Math.max(1, this.getGlobalMax() - this.getGlobalMin())
    return Math.max(18, (item.high - item.low) / range * 48)
  }

  private getDateLabel(dateValue: string): string {
    const parts: string[] = dateValue.split('-')
    return parts.length === 3 ? `${Number(parts[1])}/${Number(parts[2])}` : dateValue
  }

  build() {
    Column() {
      Row() {
        Text('15日天气')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textColor)
        Blank()
        Text('查看全部')
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
        Image($r('app.media.chevron_right'))
          .width(16)
          .height(16)
          .fillColor(this.themeColors.textSecondary)
          .margin({ left: 2 })
      }
      .width('100%')
      .margin({ bottom: 10 })

      Scroll() {
        Row() {
          ForEach(this.daily.slice(0, 7), (item: DailyWeather, index: number) => {
            Column() {
              Text(index === 0 ? '今天' : item.week)
                .fontSize(13)
                .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.themeColors.textColor)
              Text(this.getDateLabel(item.date))
                .fontSize(11)
                .fontColor(this.themeColors.textTertiary)
                .margin({ top: 3 })

              WeatherIcon({
                text: item.textDay,
                iconSize: 24,
                fallbackColor: this.themeColors.textColor
              })
                .margin({ top: 7 })

              Text(`${this.temperature(item.high)}°`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textColor)
                .margin({ top: 6 })

              Row()
                .width(this.getBarWidth(item))
                .height(3)
                .borderRadius(2)
                .linearGradient({
                  direction: GradientDirection.Right,
                  colors: [[this.themeColors.accent, 0], [this.themeColors.warmAccent, 1]]
                })
                .margin({ top: 6, bottom: 6 })

              Text(`${this.temperature(item.low)}°`)
                .fontSize(15)
                .fontColor(this.themeColors.textSecondary)
            }
            .width(54)
            .padding({ top: 2, bottom: 2 })
            .accessibilityText(`${index === 0 ? '今天' : item.week}${item.textDay}最高${item.high}度最低${item.low}度`)
          }, (item: DailyWeather, index: number) => `${index}_${item.date}`)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .backgroundColor(this.themeColors.sectionTint)
    .borderRadius(24)
  }
}
