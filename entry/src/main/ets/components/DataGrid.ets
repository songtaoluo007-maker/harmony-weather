// ─── 数据网格：风速/湿度/能见度/气压 ─────────────────
// 使用文字图标替代 Unicode emoji，避免 ArkTS 渲染乱码
import { CurrentWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Builder
function DataItem(icon: string, label: string, value: string, unit: string, themeColors: ThemeColors) {
  Column() {
    Row() {
      Text(icon)
        .fontSize(14)
      Text(label)
        .fontSize(12)
        .fontColor(themeColors.textSecondary)
        .margin({ left: 4 })
    }
    .alignItems(VerticalAlign.Center)

    Text(value)
      .fontSize(28)
      .fontWeight(FontWeight.Medium)
      .fontColor(themeColors.textColor)
      .margin({ top: 8 })

    Text(unit)
      .fontSize(12)
      .fontColor(themeColors.textSecondary)
      .margin({ top: 2 })
  }
  .width('48%')
  .padding(16)
  .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
  .backgroundColor(themeColors.cardBg)
  .borderRadius(20)
  .border({ width: 1, color: themeColors.cardBorder })
  .alignItems(HorizontalAlign.Start)
}

@Component
export struct DataGrid {
  @Prop current: CurrentWeather = new CurrentWeather()
  @Prop themeColors: ThemeColors = new ThemeColors()

  build() {
    Column() {
      Row({ space: 12 }) {
        DataItem('风', '风速', `${this.current.windSpeed}`, `km/h ${this.current.windDir} ${this.current.windScale}`, this.themeColors)
        DataItem('水', '湿度', `${this.current.humidity}`, '%', this.themeColors)
      }
      .width('100%')

      Row({ space: 12 }) {
        DataItem('视', '能见度', `${this.current.visibility}`, 'km', this.themeColors)
        DataItem('压', '气压', `${this.current.pressure}`, 'hPa', this.themeColors)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}
