// ─── 空气质量卡片：环形进度 + AQI ────────────────────
// 修复 Unicode 下标字符乱码：NO₂→NO2, SO₂→SO2, O₃→O3
import { AirQuality } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

@Component
export struct AirQualityCard {
  @Prop air: AirQuality = new AirQuality()
  @Prop themeColors: ThemeColors = new ThemeColors()

  // 根据 AQI 返回对应颜色
  private getAqiColor(): string {
    const aqi: number = this.air.aqi
    if (aqi <= 50) return '#4CAF50'
    if (aqi <= 100) return '#FF9800'
    if (aqi <= 150) return '#FF5722'
    if (aqi <= 200) return '#F44336'
    if (aqi <= 300) return '#9C27B0'
    return '#7E0023'
  }

  // 计算 AQI 进度比例（0~1）
  private getAqiProgress(): number {
    return Math.min(this.air.aqi / 300, 1)
  }

  build() {
    Column() {
      // 标题
      Text('空气质量')
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .alignSelf(ItemAlign.Start)
        .margin({ left: 4, bottom: 12 })

      Row() {
        // 左侧：AQI 环形
        Stack() {
          // 背景环
          Circle({ width: 80, height: 80 })
            .fill('rgba(255,255,255,0.1)')
            .stroke('rgba(255,255,255,0.15)')
            .strokeWidth(6)

          // 进度环
          Circle({ width: 80, height: 80 })
            .fill('transparent')
            .stroke(this.getAqiColor())
            .strokeWidth(6)
            .strokeLineCap(LineCapStyle.Round)
            .strokeDashArray([this.getAqiProgress() * 245, 245])

          // 数字
          Column() {
            Text(`${this.air.aqi}`)
              .fontSize(28)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textColor)
            Text(this.air.level)
              .fontSize(12)
              .fontColor(this.getAqiColor())
          }
        }
        .width(80)
        .height(80)

        // 右侧：污染物详情（使用纯 ASCII 标签，避免 Unicode 下标乱码）
        Column({ space: 6 }) {
          Row({ space: 16 }) {
            PollutantItem('PM2.5', `${this.air.pm25}`, this.themeColors)
            PollutantItem('PM10', `${this.air.pm10}`, this.themeColors)
            PollutantItem('NO2', `${this.air.no2}`, this.themeColors)
          }
          Row({ space: 16 }) {
            PollutantItem('SO2', `${this.air.so2}`, this.themeColors)
            PollutantItem('CO', `${this.air.co}`, this.themeColors)
            PollutantItem('O3', `${this.air.o3}`, this.themeColors)
          }
        }
        .margin({ left: 24 })
        .layoutWeight(1)
      }

      // 建议
      Text(this.air.advice)
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .margin({ top: 12 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(20)
    .backgroundBlurStyle(BlurStyle.BACKGROUND_ULTRA_THICK)
    .backgroundColor(this.themeColors.cardBg)
    .borderRadius(24)
    .border({ width: 1, color: this.themeColors.cardBorder })
    .margin({ left: 16, right: 16 })
  }
}

@Builder
function PollutantItem(label: string, value: string, themeColors: ThemeColors) {
  Column() {
    Text(value)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(themeColors.textColor)
    Text(label)
      .fontSize(10)
      .fontColor(themeColors.textSecondary)
      .margin({ top: 2 })
  }
}
