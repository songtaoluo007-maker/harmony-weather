import { AirQuality, CurrentWeather } from '../models/WeatherModels'
import { PollutantValue, WeatherPresentation } from '../models/WeatherPresentation'
import { WeatherInstruments } from '../models/WeatherInstruments'
import { ThemeColors } from '../theme/WeatherTheme'
import { AtmospherePalette, AtmosphereTokens as A } from '../theme/AtmosphereTokens'

@Component
export struct AirQualityCard {
  @Prop air: AirQuality = new AirQuality()
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop unit: string = 'c'
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop palette: AtmospherePalette = new AtmospherePalette()
  onInspect: () => void = () => {}
  @State meterWidth: number = 0
  private readonly colors: string[] = ['#9CC9AB', '#DBCC93', '#DEA77C', '#D88F89', '#B89BBC', '#A08099']

  private aqiColor(): string {
    const band: number = WeatherInstruments.aqiBand(this.air.aqi)
    const ink: string[] = ['#256641', '#756015', '#9A4B12', '#A73D38', '#78528C', '#78445E']
    return band < 0 ? this.themeColors.textSecondary : this.palette.isLight ? ink[band] : this.colors[band]
  }

  build() {
    Column({ space: 18 }) {
      Row() {
        Text('空气质量').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.palette.text)
        Blank()
        Text(this.air.standard).fontSize(11).fontColor(this.themeColors.textSecondary)
      }.width('100%')
      Button({ type: ButtonType.Normal }) {
        Column({ space: 16 }) {
        if (!this.air.available) {
          Text('空气质量暂不可用').fontSize(14).fontColor(this.themeColors.textSecondary)
            .width('100%').padding({ top: 12, bottom: 12 })
        } else {
          Row({ space: 12 }) {
            Row({ space: 10 }) {
              Text(`${this.air.aqi}`).fontSize(46).fontWeight(300).fontColor(this.palette.text)
                .maxLines(1).minFontSize(32).maxFontSize(46)
                .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
              Text(this.air.level).fontSize(12).fontColor(this.aqiColor()).maxLines(2)
                .padding({ left: 9, right: 9, top: 5, bottom: 5 })
                .borderRadius(9).backgroundColor(this.palette.wash)
            }.layoutWeight(1).alignItems(VerticalAlign.Center)
            Image($r('app.media.chevron_right')).width(18).height(18)
              .fillColor(this.themeColors.textSecondary).opacity(.7)
          }.width('100%')
          Column({ space: 4 }) {
            Stack({ alignContent: Alignment.TopStart }) {
              Row({ space: 3 }) {
                ForEach(this.colors, (color: string) => {
                  Row().height(3).layoutWeight(1).borderRadius(2).backgroundColor(color)
                })
              }.width('100%').margin({ top: 6.5 })
              if (WeatherInstruments.aqiPosition(this.air.aqi) >= 0) {
                Circle().width(8).height(8).fill(this.palette.text).stroke(this.palette.page).strokeWidth(1.5)
                  .position({ x: Math.max(0, this.meterWidth - 8) * WeatherInstruments.aqiPosition(this.air.aqi), y: 4 })
              }
            }.width('100%').height(16).onAreaChange((_old: Area, area: Area) => {
              this.meterWidth = Number(area.width)
            }).accessibilityLevel('no')
            Row() {
              Text('优').fontSize(9).fontColor(this.themeColors.textSecondary)
              Blank()
              Text('严重污染').fontSize(9).fontColor(this.themeColors.textSecondary)
            }.width('100%').accessibilityLevel('no-hide-descendants')
          }.width('100%')
          Divider().color(this.palette.border).strokeWidth(.5)
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(WeatherPresentation.pollutants(this.air), (item: PollutantValue) => {
              Column({ space: 5 }) {
                Text(item.label).fontSize(11).fontColor(this.themeColors.textSecondary)
                Text(item.value).fontSize(22).fontWeight(300).fontColor(this.palette.text)
                  .maxLines(1).minFontSize(16).maxFontSize(22)
                  .width('100%').textAlign(TextAlign.Start)
                  .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
                Text(item.unit).fontSize(10).fontColor(this.themeColors.textSecondary)
              }.width('33.33%').padding({ top: 8, bottom: 10, right: 8 }).alignItems(HorizontalAlign.Start)
                .accessibilityText(`${item.label}，${item.value} ${item.unit}`)
            }, (item: PollutantValue) => JSON.stringify(item))
          }.width('100%')
        }
        }.width('100%').padding(20)
      }.width('100%').padding(0).borderRadius(A.radius).clip(true).backgroundColor(Color.Transparent)
        .linearGradient({ angle: 125, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
        .border({ width: .7, color: this.palette.border, radius: A.radius })
        .onClick(() => this.onInspect())
        .accessibilityGroup(true)
        .accessibilityText(this.air.available ? `${this.air.standard} 空气质量指数${this.air.aqi}，${this.air.level}，点击查看污染物详情` : '空气质量暂不可用')
    }.width('100%').padding({ top: 26, bottom: 8 })
  }
}
