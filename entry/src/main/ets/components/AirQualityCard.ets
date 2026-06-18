import { AirQuality, CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct AirQualityCard {
  @Prop air: AirQuality = new AirQuality()
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop unit: string = 'c'
  @Prop themeColors: ThemeColors = new ThemeColors()

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private aqiColor(): string {
    if (this.air.aqi <= 50) return this.themeColors.success
    if (this.air.aqi <= 100) return '#FFD052'
    if (this.air.aqi <= 150) return '#FF9F43'
    return this.themeColors.warning
  }

  build() {
    Scroll() {
      Row() {
        Column() {
          Row({ space: 7 }) {
            Image($r('app.media.air_filter'))
              .width(20)
              .height(20)
              .fillColor(this.aqiColor())
            Text('空气质量')
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
          }
          Row({ space: 7 }) {
            Text(`${this.air.aqi}`)
              .fontSize(32)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textColor)
            Text(this.air.level)
              .fontSize(14)
              .fontColor(this.aqiColor())
          }
          .margin({ top: 3 })
          Progress({ value: Math.min(this.air.aqi, 300), total: 300, type: ProgressType.Linear })
            .width(96)
            .height(4)
            .color(this.aqiColor())
            .backgroundColor(this.themeColors.divider)
        }
        .width(128)
        .height(92)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .border({ width: { right: 1 }, color: this.themeColors.divider })
        .accessibilityText(`空气质量${this.air.aqi}${this.air.level}`)

        this.metric($r('app.media.thermometer'), '体感温度', `${this.temperature(this.current.feelsLike)}°`, this.themeColors.warmAccent)
        this.metric($r('app.media.water_percent'), '湿度', `${this.current.humidity}%`, this.themeColors.accent)
        this.metric($r('app.media.weather_windy'), '风向风力', `${this.current.windDir}${this.current.windScale}`, this.themeColors.accent)
        this.metric($r('app.media.eye_outline'), '能见度', `${this.current.visibility}公里`, this.themeColors.accent)
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .padding({ left: 18, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.themeColors.sectionTint)
    .borderRadius(24)
    .onClick(() => {
      this.getUIContext().getPromptAction().showToast({
        message: `${this.air.advice}  PM2.5 ${this.air.pm25}，PM10 ${this.air.pm10}`,
        duration: 2400
      })
    })
  }

  @Builder
  metric(icon: Resource, label: string, value: string, color: string) {
    Column() {
      Image(icon)
        .width(21)
        .height(21)
        .fillColor(color)
      Text(label)
        .fontSize(10)
        .fontColor(this.themeColors.textTertiary)
        .margin({ top: 6 })
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textColor)
        .margin({ top: 3 })
        .maxLines(1)
    }
    .width(92)
    .height(92)
    .justifyContent(FlexAlign.Center)
    .border({ width: { right: 1 }, color: this.themeColors.divider })
    .accessibilityText(`${label}${value}`)
  }
}
