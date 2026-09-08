import { DailyWeather } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'
import { WeatherIcon } from './WeatherIcon'

@Component
export struct WeeklyForecast {
  @Prop @Watch('drawChart') daily: DailyWeather[] = []
  @Prop @Watch('drawChart') themeColors: ThemeColors = new ThemeColors()
  @Prop @Watch('drawChart') unit: string = 'c'
  @State columnWidth: number = 52
  private chart: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private chartReady: boolean = false

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private drawChart(): void {
    if (!this.chartReady) return
    const days: DailyWeather[] = this.daily.slice(0, 7)
    const width: number = this.columnWidth * days.length
    const ctx: CanvasRenderingContext2D = this.chart
    ctx.clearRect(0, 0, width, 116)
    if (days.length === 0) return
    let min: number = Math.min(...days.map((day: DailyWeather) => day.low))
    let max: number = Math.max(...days.map((day: DailyWeather) => day.high))
    const range: number = Math.max(4, max - min)
    for (let series: number = 0; series < 2; series++) {
      ctx.strokeStyle = series === 0 ? this.themeColors.warmAccent : this.themeColors.accent
      ctx.fillStyle = series === 0 ? this.themeColors.warmAccent : this.themeColors.accent
      ctx.lineWidth = 1.6
      ctx.beginPath()
      days.forEach((day: DailyWeather, index: number) => {
        const value: number = series === 0 ? day.high : day.low
        const x: number = this.columnWidth * (index + 0.5)
        const y: number = 28 + (max - value) / range * 52
        if (index === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      })
      ctx.stroke()
      days.forEach((day: DailyWeather, index: number) => {
        const value: number = series === 0 ? day.high : day.low
        const x: number = this.columnWidth * (index + 0.5)
        const y: number = 28 + (max - value) / range * 52
        ctx.beginPath()
        ctx.arc(x, y, 3, 0, Math.PI * 2)
        ctx.fill()
        ctx.font = '14vp sans-serif'
        ctx.textAlign = 'center'
        ctx.fillText(`${this.temperature(value)}°`, x, series === 0 ? y - 13 : y + 23)
      })
    }
  }

  private dateLabel(date: string): string {
    const parts: string[] = date.split('-')
    return parts.length === 3 ? `${Number(parts[1])}/${Number(parts[2])}` : date
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('15日天气').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
        Blank()
        Button({ type: ButtonType.Normal }) {
          Row({ space: 2 }) {
            Text('完整预报').fontSize(11).fontColor(this.themeColors.textSecondary)
            Image($r('app.media.chevron_right')).width(14).height(14).fillColor(this.themeColors.textSecondary)
          }
        }
        .height(44).padding({ left: 10 }).backgroundColor(Color.Transparent)
        .accessibilityText('查看完整15日天气预报')
        .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/WeatherDetails' }))
      }
      .width('100%').height(28)
      if (this.daily.length === 0) {
        Text('暂无逐日预报').fontSize(13).fontColor(this.themeColors.textSecondary).padding(20)
      } else {
        Scroll() {
          Column() {
            Row() {
              ForEach(this.daily.slice(0, 7), (item: DailyWeather, index: number) => {
                Column({ space: 6 }) {
                  Text(index === 0 ? '今天' : index === 1 ? '明天' : item.week)
                    .fontSize(12).fontColor(this.themeColors.textColor)
                  Text(this.dateLabel(item.date)).fontSize(10).fontColor(this.themeColors.textTertiary)
                  WeatherIcon({ text: item.textDay, iconSize: 23, fallbackColor: this.themeColors.textColor })
                    .margin({ top: 4 })
                }
                .width(this.columnWidth)
                .accessibilityText(`${item.date}，${item.textDay}，最高${this.temperature(item.high)}度，最低${this.temperature(item.low)}度`)
              }, (item: DailyWeather) => item.date)
            }
            Canvas(this.chart)
              .width(this.columnWidth * Math.min(7, this.daily.length)).height(116)
              .onReady(() => { this.chartReady = true; this.drawChart() })
              .onAreaChange(() => this.drawChart())
              .accessibilityLevel('no')
          }
        }
        .width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .onAreaChange((_old: Area, area: Area) => {
          this.columnWidth = Math.max(48, Number(area.width) / Math.min(7, Math.max(1, this.daily.length)))
          this.drawChart()
        })
      }
    }
    .width('100%').padding({ top: 20, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: this.themeColors.divider })
  }
}
