// ─── Hero 区：城市名 + 温度 + 天气状态 ──────────────
import { CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct HeroSection {
  @Prop city: string = '深圳'
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop themeColors: ThemeColors = new ThemeColors()
  @State showContent: boolean = false

  aboutToAppear(): void {
    setTimeout(() => {
      this.showContent = true
    }, 200)
  }

  build() {
    Column() {
      // 城市名
      Text(this.city)
        .fontSize(18)
        .fontColor(this.themeColors.textSecondary)
        .opacity(this.showContent ? 1 : 0)
        .translate({ y: this.showContent ? 0 : 20 })
        .animation({ duration: 600, curve: Curve.EaseOut })

      // 温度数字
      Text(`${this.current.temp}°`)
        .fontSize(96)
        .fontWeight(FontWeight.Thin)
        .fontColor(this.themeColors.textColor)
        .opacity(this.showContent ? 1 : 0)
        .scale({ x: this.showContent ? 1 : 0.8, y: this.showContent ? 1 : 0.8 })
        .animation({ duration: 800, curve: Curve.EaseOut, delay: 150 })

      // 天气描述
      Text(this.current.text)
        .fontSize(22)
        .fontColor(this.themeColors.textColor)
        .opacity(this.showContent ? 1 : 0)
        .translate({ y: this.showContent ? 0 : 15 })
        .animation({ duration: 600, curve: Curve.EaseOut, delay: 300 })

      // 体感 + 高低温
      Row() {
        Text(`体感 ${this.current.feelsLike}°`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)

        Text(' · ')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)

        Text(`最高 ${this.current.high}°`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)

        Text('  ')
          .fontSize(14)

        Text(`最低 ${this.current.low}°`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
      }
      .margin({ top: 8 })
      .opacity(this.showContent ? 1 : 0)
      .translate({ y: this.showContent ? 0 : 10 })
      .animation({ duration: 600, curve: Curve.EaseOut, delay: 450 })
    }
    .width('100%')
    .padding({ top: 80, bottom: 40 })
    .alignItems(HorizontalAlign.Center)
  }
}
