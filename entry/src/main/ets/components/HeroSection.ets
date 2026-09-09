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

  build() {
    Column({ space: 6 }) {
      Row({ space: 0 }) {
        Text(`${this.displayTemp}`)
          .fontSize(112).minFontScale(1).maxFontScale(1.15)
          .fontWeight(FontWeight.Lighter).fontColor(this.themeColors.textColor).letterSpacing(-6)
        Text(this.unitLabel)
          .fontSize(52).fontWeight(300).fontColor(this.themeColors.textColor)
          .alignSelf(ItemAlign.Start).margin({ top: 18, left: 4 })
      }
      .accessibilityText(`当前温度${this.displayTemp}度`)
      Row({ space: 12 }) {
        Text(this.current.text)
          .fontSize(22).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
        Text(`体感 ${this.displayFeels}°`).fontSize(14).fontColor(this.themeColors.textSecondary)
      }
      Row({ space: 16 }) {
        Text(`最高 ${this.displayHigh}°`).fontSize(13).fontColor(this.themeColors.textSecondary)
        Text(`最低 ${this.displayLow}°`).fontSize(13).fontColor(this.themeColors.textSecondary)
      }
      .margin({ top: 4 })
    }
    .width('100%').padding({ left: 26, right: 24, top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Start)
  }
}
