import { HourlyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { WeatherIcon } from './WeatherIcon'

@Component
export struct HourlyCapsules {
  @Prop hourly: HourlyWeather[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'
  @State selectedIndex: number = 0

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  build() {
    Column() {
      Row() {
        Text('逐小时预报')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textColor)
        Blank()
        Text(this.hourly.length > 0 && this.hourly[0].pop > 0 ? `降水 ${this.hourly[0].pop}%` : '降水概率较低')
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
      }
      .width('100%')
      .margin({ bottom: 10 })

      Scroll() {
        Row() {
          ForEach(this.hourly, (item: HourlyWeather, index: number) => {
            Column() {
              Text(index === 0 ? '现在' : item.time)
                .fontSize(12)
                .fontColor(this.themeColors.textSecondary)
                .maxLines(1)

              WeatherIcon({
                text: item.text,
                iconSize: 24,
                fallbackColor: this.themeColors.textColor
              })
                .margin({ top: 8 })

              Text(`${this.temperature(item.temp)}°`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.themeColors.textColor)
                .margin({ top: 7 })

              if (item.pop > 0) {
                Text(`${item.pop}%`)
                  .fontSize(10)
                  .fontColor(this.themeColors.accent)
                  .margin({ top: 4 })
              }
            }
            .width(58)
            .height(84)
            .justifyContent(FlexAlign.Center)
            .borderRadius(18)
            .backgroundColor(index === this.selectedIndex ? this.themeColors.strongTint : 'transparent')
            .onClick(() => {
              this.selectedIndex = index
            })
            .accessibilityText(`${item.time}${item.text}${item.temp}度`)
          }, (item: HourlyWeather, index: number) => `${index}_${item.time}`)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 14, bottom: 14 })
    .backgroundColor(this.themeColors.sectionTint)
    .borderRadius(24)
  }
}
