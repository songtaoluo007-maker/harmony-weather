import { HourlyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { WeatherIcon } from './WeatherIcon'

@Component
export struct HourlyCapsules {
  @Prop @Watch('resetSelection') hourly: HourlyWeather[] = []
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop unit: string = 'c'
  @Prop currentNight: boolean = false
  @State selectedIndex: number = 0

  private resetSelection(): void { this.selectedIndex = 0 }

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private summary(): string {
    const item: HourlyWeather | undefined = this.hourly[this.selectedIndex]
    return item ? `${item.text} · ${item.pop >= 0 ? `降水 ${item.pop}%` : '降水概率暂无'}` : '暂无小时预报'
  }

  build() {
    Column({ space: 14 }) {
      Row() {
        Text('逐小时预报')
          .fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
        Blank().width(10)
        Text(this.summary()).fontSize(11).fontColor(this.themeColors.textSecondary)
          .layoutWeight(1).textAlign(TextAlign.End).maxLines(2)
      }
      .width('100%')
      Scroll() {
        Row({ space: 2 }) {
          ForEach(this.hourly, (item: HourlyWeather, index: number) => {
            Column({ space: 8 }) {
              Text(item.time).fontSize(11)
                .fontColor(index === this.selectedIndex ? '#FFFFFF' : this.themeColors.textSecondary).maxLines(1)
              WeatherIcon({ text: item.text, iconSize: 25, fallbackColor: this.themeColors.textColor,
                isNight: item.timestamp > 0 ? !item.isDay : this.isNightHour(item.time) })
              Text(`${this.temperature(item.temp)}°`)
                .fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
            }
            .width(51).height(99).justifyContent(FlexAlign.Center).borderRadius(18)
            .backgroundColor(index === this.selectedIndex ? 'rgba(255,255,255,0.11)' : Color.Transparent)
            .border({ width: 0.6, color: index === this.selectedIndex ? 'rgba(255,255,255,0.20)' : Color.Transparent })
            .onClick(() => { this.selectedIndex = index })
            .accessibilityText(`${item.time}，${item.text}，${this.temperature(item.temp)}度，${item.pop >= 0 ? `降水概率${item.pop}%` : '降水概率暂无'}，${index === this.selectedIndex ? '已选中' : '点击查看'}`)
          }, (item: HourlyWeather, index: number) => `${index}_${JSON.stringify(item)}`)
        }
      }
      .width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
    }
    .width('100%').padding({ top: 20, bottom: 18 })
    .border({ width: { bottom: 0.5 }, color: this.themeColors.divider })
  }

  private isNightHour(time: string): boolean {
    if (time === '现在') return this.currentNight
    const hour: number = Number.parseInt(time)
    return hour >= 19 || hour < 6
  }
}
