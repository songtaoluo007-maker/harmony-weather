import { CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct HeroSection {
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop displayTemp: number = 26
  @Prop displayFeels: number = 27
  @Prop displayHigh: number = 29
  @Prop displayLow: number = 23
  @Prop unitLabel: string = '°'
  @Prop themeColors: ThemeColors = new ThemeColors()
  @State visible: boolean = false

  aboutToAppear(): void {
    setTimeout(() => {
      this.visible = true
    }, 120)
  }

  build() {
    Column() {
      Text(`${this.displayTemp}${this.unitLabel}`)
        .fontSize(96)
        .fontWeight(FontWeight.Lighter)
        .fontColor(this.themeColors.textColor)
        .letterSpacing(-5)
        .opacity(this.visible ? 1 : 0)
        .translate({ y: this.visible ? 0 : 18 })
        .animation({ duration: 620, curve: Curve.EaseOut })
        .accessibilityText(`当前温度${this.displayTemp}度`)

      Text(this.current.text)
        .fontSize(23)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textColor)
        .margin({ top: -5 })

      Row({ space: 16 }) {
        Text(`体感 ${this.displayFeels}°`)
          .fontSize(15)
          .fontColor(this.themeColors.textSecondary)
        Text(`最高 ${this.displayHigh}°`)
          .fontSize(15)
          .fontColor(this.themeColors.textSecondary)
        Text(`最低 ${this.displayLow}°`)
          .fontSize(15)
          .fontColor(this.themeColors.textSecondary)
      }
        .margin({ top: 7 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 20 })
    .alignItems(HorizontalAlign.Start)
  }
}
