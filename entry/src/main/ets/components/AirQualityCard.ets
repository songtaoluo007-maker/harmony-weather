import { AirQuality, CurrentWeather } from '../models/WeatherModels'
import { PollutantValue, WeatherPresentation } from '../models/WeatherPresentation'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct AirQualityCard {
  @Prop air: AirQuality = new AirQuality()
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop unit: string = 'c'
  @Prop themeColors: ThemeColors = new ThemeColors()

  private aqiColor(): string {
    if (this.air.aqi <= 50) return '#9CDFB0'
    if (this.air.aqi <= 100) return '#EAD08A'
    if (this.air.aqi <= 150) return '#EEAF80'
    return '#F59291'
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('空气质量').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
        Blank()
        Text(this.air.standard).fontSize(11).fontColor(this.themeColors.textTertiary)
      }.width('100%')
      if (!this.air.available) {
        Text('空气质量暂不可用').fontSize(14).fontColor(this.themeColors.textSecondary)
          .width('100%').padding({ top: 12, bottom: 12 })
      } else {
      Row({ space: 16 }) {
        Row({ space: 9 }) {
          Text(`${this.air.aqi}`).fontSize(38).fontWeight(300).fontColor(this.themeColors.textColor)
          Text(this.air.level).fontSize(13).fontColor(this.aqiColor())
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(10).backgroundColor('rgba(156,223,176,0.12)')
        }
        Column({ space: 8 }) {
          Text(this.air.advice).fontSize(12).fontColor(this.themeColors.textSecondary)
            .maxLines(2).lineHeight(18)
          Row({ space: 3 }) {
            ForEach(['#9CDFB0', '#EAD08A', '#EEAF80', '#F59291', '#BF9AD2', '#946583'], (color: string) => {
              Row().height(4).layoutWeight(1).borderRadius(2).backgroundColor(color)
            })
          }.width('100%')
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(WeatherPresentation.pollutants(this.air), (item: PollutantValue) => {
          Column({ space: 5 }) {
            Text(item.label).fontSize(11).fontColor(this.themeColors.textSecondary)
            Text(item.value).fontSize(18).fontWeight(300).fontColor(this.themeColors.textColor)
            Text(item.unit).fontSize(10).fontColor(this.themeColors.textTertiary)
          }.width('33.33%').padding({ top: 12, bottom: 8 }).alignItems(HorizontalAlign.Start)
            .accessibilityText(`${item.label}，${item.value} ${item.unit}`)
        }, (item: PollutantValue) => JSON.stringify(item))
      }.width('100%')
      }
    }
    .width('100%').padding({ top: 22, bottom: 22 })
    .border({ width: { bottom: 0.5 }, color: this.themeColors.divider })
    .onClick(() => this.getUIContext().showAlertDialog({
      title: this.air.available ? `空气质量 · ${this.air.level}` : '空气质量暂不可用',
      message: this.air.available ? `${this.air.standard} · ${this.air.advice}\n\n${WeatherPresentation.pollutants(this.air).map((item: PollutantValue) => `${item.label}：${item.value} ${item.unit}`).join('\n')}` : '天气服务暂未返回空气质量，没有使用模拟数值替代。',
      confirm: { value: '知道了', action: () => {} }
    }))
    .accessibilityText(this.air.available ? `${this.air.standard} 空气质量指数${this.air.aqi}，${this.air.level}，点击查看污染物详情` : '空气质量暂不可用')
  }
}
