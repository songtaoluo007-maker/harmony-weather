import { CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct DataGrid {
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  build() {
    Scroll() {
      Row() {
        this.metric($r('app.media.gauge'), '气压', `${this.current.pressure}hPa`, this.themeColors.accent)
        this.metric($r('app.media.weather_sunset_up'), '日出', this.current.sunrise, this.themeColors.warmAccent)
        this.metric($r('app.media.weather_sunset_down'), '日落', this.current.sunset, this.themeColors.warmAccent)
        this.metric($r('app.media.weather_cloudy'), '云量', `${this.current.cloud}%`, this.themeColors.accent)
        this.metric($r('app.media.umbrella'), '降水量', `${this.current.precip}mm`, this.themeColors.accent)
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
  }

  @Builder
  metric(icon: Resource, label: string, value: string, color: string) {
    Column() {
      Image(icon)
        .width(23)
        .height(23)
        .fillColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.themeColors.textTertiary)
        .margin({ top: 8 })
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textColor)
        .margin({ top: 4 })
        .maxLines(1)
    }
    .width(96)
    .height(98)
    .justifyContent(FlexAlign.Center)
    .border({ width: { right: 1 }, color: this.themeColors.divider })
    .accessibilityText(`${label}${value}`)
  }
}
