import { CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct DataGrid {
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        this.metric($r('app.media.water_percent'), '湿度', `${this.current.humidity}%`)
        this.metric($r('app.media.weather_windy'), this.current.windDir, this.current.windScale)
      }
      Row({ space: 8 }) {
        this.metric($r('app.media.eye_outline'), '能见度', `${this.current.visibility} km`)
        this.metric($r('app.media.gauge'), '气压', `${this.current.pressure} hPa`)
      }
      Row({ space: 8 }) {
        this.metric($r('app.media.weather_sunset_up'), '日出', this.current.sunrise)
        this.metric($r('app.media.weather_sunset_down'), '日落', this.current.sunset)
      }
      Row({ space: 8 }) {
        this.metric($r('app.media.weather_cloudy'), '云量', `${this.current.cloud}%`)
        this.metric($r('app.media.umbrella'), '降水量', `${this.current.precip} mm`)
      }
    }.width('100%')
  }

  @Builder
  metric(icon: Resource, label: string, value: string) {
    Column({ space: 13 }) {
      Row({ space: 8 }) {
        Image(icon).width(19).height(19).fillColor(this.themeColors.accent)
        Text(label).fontSize(12).fontColor(this.themeColors.textSecondary).maxLines(2)
      }.width('100%')
      Text(value).fontSize(22).fontWeight(300).fontColor(this.themeColors.textColor)
        .maxLines(1).minFontSize(15).maxFontSize(22).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
    }
    .alignItems(HorizontalAlign.Start).layoutWeight(1)
    .padding(18).constraintSize({ minHeight: 104 })
    .backgroundColor('rgba(255,255,255,0.055)').borderRadius(20)
    .accessibilityText(`${label}，${value}`)
  }
}
