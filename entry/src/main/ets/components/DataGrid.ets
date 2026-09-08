import { CurrentWeather } from '../models/WeatherModels'
import { WeatherPresentation } from '../models/WeatherPresentation'
import { ThemeColors } from '../theme/WeatherTheme'
import { SolarReading, WeatherInstruments } from '../models/WeatherInstruments'
import { AtmospherePalette, AtmosphereTokens as A } from '../theme/AtmosphereTokens'
import { InstrumentDial } from './InstrumentDial'

@Component
export struct DataGrid {
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'
  @Prop solar: SolarReading = new SolarReading()
  @Prop palette: AtmospherePalette = new AtmospherePalette()

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Column({ space: 12 }) {
          this.label($r('app.media.weather_windy'), '风向与风速', this.palette.accent)
          this.reading(WeatherPresentation.windSpeed(this.current.windSpeed).split(' ')[0], 'km/h', 34)
          Text(`${this.current.windDir} · ${this.current.windScale}`).fontSize(12)
            .fontColor(this.themeColors.textSecondary).maxLines(2)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        InstrumentDial({ kind: 'wind', value: WeatherInstruments.bearing(this.current.windDir), tint: this.palette.accent })
          .width(114).height(114)
      }.width('100%').padding(20).borderRadius(A.radius)
        .linearGradient({ angle: 125, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
        .border({ width: .7, color: this.palette.border })
        .accessibilityText(`${this.current.windDir}，${this.current.windScale}，${WeatherPresentation.windSpeed(this.current.windSpeed)}`)

      Column({ space: 4 }) {
        Row() {
          this.label($r('app.media.weather_sunset_up'), '日出与日落', this.palette.warm)
          Blank()
          Text(this.solar.valid ? `白昼 ${this.solar.duration}` : '轨迹暂不可用')
            .fontSize(10).fontColor(this.themeColors.textSecondary)
        }.width('100%')
        InstrumentDial({ kind: 'solar', value: this.solar.valid ? this.solar.progress : -1,
          active: this.solar.sunVisible }).width('100%').height(66).margin({ top: 14 })
        Row() {
          Column({ space: 4 }) {
            Text(this.solar.valid ? this.solar.rise : this.current.sunrise).fontSize(23).fontColor(A.ivory)
            Text('日出').fontSize(10).fontColor(this.themeColors.textSecondary)
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Column({ space: 4 }) {
            Text(this.solar.valid ? this.solar.set : this.current.sunset).fontSize(23).fontColor(A.ivory)
            Text('日落').fontSize(10).fontColor(this.themeColors.textSecondary)
          }.alignItems(HorizontalAlign.End)
        }.width('100%')
      }.width('100%').padding(20).borderRadius(A.radius)
        .linearGradient({ angle: 125, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
        .border({ width: .7, color: this.palette.border })
        .accessibilityText(`日出${this.solar.valid ? this.solar.rise : this.current.sunrise}，日落${this.solar.valid ? this.solar.set : this.current.sunset}${this.solar.valid ? '，白昼' + this.solar.duration + (this.solar.sunVisible ? '，当前日照时段' : '，当前非日照时段') : '，轨迹暂不可用'}`)

      Row({ space: 12 }) {
        Column({ space: 12 }) {
          this.label($r('app.media.water_percent'), '相对湿度', this.palette.accent)
          this.reading(`${this.current.humidity}`, '%', 32)
          InstrumentDial({ kind: 'scale', value: WeatherInstruments.fraction(this.current.humidity), tint: this.palette.accent })
            .width('100%').height(17)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1).padding(18).borderRadius(A.radius)
          .linearGradient({ angle: 140, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
          .border({ width: .7, color: this.palette.border }).accessibilityText(`相对湿度${this.current.humidity}%`)
        Column({ space: 12 }) {
          this.label($r('app.media.umbrella'), '降水量', this.palette.accent)
          this.reading(`${this.current.precip}`, 'mm', 32)
          Row({ space: 4 }) {
            Image($r('app.media.water_percent')).width(13).height(13).fillColor(this.palette.accent).opacity(.65)
            Text('当前时段').fontSize(10).fontColor(this.themeColors.textSecondary)
          }.height(17)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1).padding(18).borderRadius(A.radius)
          .linearGradient({ angle: 140, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
          .border({ width: .7, color: this.palette.border }).accessibilityText(`降水量${this.current.precip}毫米`)
      }.width('100%').alignItems(VerticalAlign.Top)

      Row() {
        this.compact('能见度', `${this.current.visibility}`, 'km', $r('app.media.eye_outline'))
        Divider().vertical(true).height(52).color(this.palette.border).strokeWidth(.5)
        this.compact('气压', `${this.current.pressure}`, 'hPa', $r('app.media.gauge'))
        Divider().vertical(true).height(52).color(this.palette.border).strokeWidth(.5)
        this.compact('云量', `${this.current.cloud}`, '%', $r('app.media.weather_cloudy'))
      }.width('100%').padding({ top: 20, bottom: 20 }).borderRadius(A.radius)
        .linearGradient({ angle: 125, colors: [[this.palette.panelTop, 0], [this.palette.panelBottom, 1]] })
        .border({ width: .7, color: this.palette.border })
    }.width('100%')
  }

  @Builder
  label(icon: Resource, label: string, color: string) {
    Row({ space: 6 }) {
      Image(icon).width(16).height(16).fillColor(color)
      Text(label).fontSize(12).fontColor(this.themeColors.textSecondary)
    }
  }

  @Builder
  reading(value: string, unit: string, size: number) {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.End }) {
      Text(value).fontSize(size).fontWeight(300).fontColor(A.ivory)
        .maxLines(1).minFontSize(20).maxFontSize(size).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        .constraintSize({ maxWidth: '100%' }).margin({ right: 5 })
      Text(unit).fontSize(11).fontColor(this.themeColors.textSecondary).margin({ bottom: 5 })
    }.width('100%')
  }

  @Builder
  compact(label: string, value: string, unit: string, icon: Resource) {
    Column({ space: 7 }) {
      Image(icon).width(17).height(17).fillColor(this.palette.accent).opacity(.8)
      Text(label).fontSize(10).fontColor(this.themeColors.textSecondary)
      Text(value).fontSize(21).fontWeight(300).fontColor(A.ivory)
        .maxLines(1).minFontSize(15).maxFontSize(21).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
      Text(unit).fontSize(10).fontColor(this.themeColors.textTertiary)
    }.layoutWeight(1).padding({ left: 5, right: 5 }).accessibilityText(`${label}${value} ${unit}`)
  }
}
