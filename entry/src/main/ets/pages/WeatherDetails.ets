import { DailyWeather, WeatherData } from '../models/WeatherModels'
import { WeatherService } from '../services/WeatherService'
import { WeatherIcon } from '../components/WeatherIcon'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct WeatherDetails {
  @State data: WeatherData = new WeatherData()
  @State unit: string = 'c'
  @State expandedDate: string = ''
  private service: WeatherService = WeatherService.getInstance()

  aboutToAppear(): void {
    const current: WeatherData | null = this.service.peekLatestData()
    if (current) this.data = current
    this.unit = this.service.getSettings().unit
  }

  private temperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private dateLabel(value: string): string {
    const parts: string[] = value.split('-')
    return parts.length === 3 ? `${Number(parts[1])}/${Number(parts[2])}` : value
  }

  private minTemp(): number { return Math.min(...this.data.daily.map((day: DailyWeather) => day.low)) }
  private maxTemp(): number { return Math.max(...this.data.daily.map((day: DailyWeather) => day.high)) }
  private barOffset(item: DailyWeather): string {
    return `${(item.low - this.minTemp()) / Math.max(1, this.maxTemp() - this.minTemp()) * 100}%`
  }
  private barWidth(item: DailyWeather): string {
    return `${Math.max(2, (item.high - item.low) / Math.max(1, this.maxTemp() - this.minTemp()) * 100)}%`
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.chevron_left')).width(23).height(23).fillColor(T.text)
        }.width(44).height(44).backgroundColor(Color.Transparent)
          .onClick(() => this.getUIContext().getRouter().back()).accessibilityText('返回天气')
        Text(this.data.city).fontSize(22).fontWeight(FontWeight.Medium).fontColor(T.text)
        Blank()
        Text(this.data.source === 'mock' ? '演示天气' : this.data.isOffline ? '离线缓存' : this.data.source === 'openmeteo' ? 'Open-Meteo' : '和风天气')
          .fontSize(11).fontColor(T.muted)
      }.width('100%').padding({ left: 12, right: 24, top: 42, bottom: 20 })
      Column({ space: 8 }) {
        Text(`未来${this.data.daily.length}天`).fontSize(30).fontWeight(300).fontColor(T.text)
        Text('看见天气的起伏，从容安排每一天').fontSize(12).fontColor(T.muted)
      }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 24, right: 24, bottom: 24 })
      if (this.data.daily.length === 0) {
        Text('暂时没有逐日预报').fontSize(15).fontColor(T.muted).layoutWeight(1)
      } else {
        List({ space: 2 }) {
          ForEach(this.data.daily, (item: DailyWeather, index: number) => {
            ListItem() {
              Column() {
                Row({ space: 8 }) {
                  Column({ space: 5 }) {
                    Text(index === 0 ? '今天' : index === 1 ? '明天' : item.week)
                      .fontSize(14).fontWeight(FontWeight.Medium).fontColor(T.text)
                    Text(this.dateLabel(item.date)).fontSize(11).fontColor(T.muted)
                  }.width(40).alignItems(HorizontalAlign.Start)
                  WeatherIcon({ text: item.textDay, iconSize: 26, fallbackColor: T.text })
                  Text(`${this.temperature(item.low)}°`).fontSize(14).fontColor(T.muted).width(32).textAlign(TextAlign.End)
                  Stack({ alignContent: Alignment.Start }) {
                    Row().width('100%').height(3).borderRadius(2).backgroundColor('#31495B')
                    Row().width(this.barWidth(item)).height(4).borderRadius(2)
                      .linearGradient({ direction: GradientDirection.Right, colors: [['#96D5E5', 0], ['#F0C88D', 1]] })
                      .position({ x: this.barOffset(item) })
                  }.layoutWeight(1).height(4)
                  Text(`${this.temperature(item.high)}°`).fontSize(15).fontColor(T.text).width(32)
                }.width('100%').constraintSize({ minHeight: 76 }).padding({ left: 14, right: 14 })
                if (this.expandedDate === item.date) {
                  Column({ space: 12 }) {
                    Text(`${this.data.source === 'openmeteo' ? '全天概况' : '白天'} · ${item.textDay}`)
                      .fontSize(12).fontColor(T.text).width('100%')
                    Text(`夜间 · ${item.textNight}`).fontSize(12).fontColor(T.text).width('100%').lineHeight(19)
                    if (item.nightSummarySource === 'hourly') {
                      Text(`${item.nightRange} · 逐小时汇总 ${item.nightHours}/${item.nightExpectedHours} 时段${item.nightHours < item.nightExpectedHours ? ' · 数据不完整' : ''}`)
                        .fontSize(10).fontColor(T.muted).width('100%').lineHeight(17)
                    }
                    Row() {
                      Text(`${item.windDir} ${item.windScale}`).fontSize(12).fontColor(T.muted)
                      Blank()
                      Text(item.humidity >= 0 ? `平均湿度 ${item.humidity}%` : '湿度暂无').fontSize(12).fontColor(T.muted)
                    }.width('100%')
                  }.width('100%').padding({ left: 16, right: 16, bottom: 20 })
                }
              }.width('100%').borderRadius(18)
                .backgroundColor(index === 0 || this.expandedDate === item.date ? T.surface : Color.Transparent)
                .onClick(() => { this.expandedDate = this.expandedDate === item.date ? '' : item.date })
                .accessibilityText(`${item.date}，${item.textDay}，最高${this.temperature(item.high)}度，最低${this.temperature(item.low)}度，点击展开详情`)
            }
          }, (item: DailyWeather) => item.date)
          ListItem() {
            Text('预报存在不确定性，较远日期仅供出行规划参考。')
              .fontSize(11).fontColor(T.muted).lineHeight(18).padding({ top: 24, bottom: 20 })
          }
        }.layoutWeight(1).width('100%').padding({ left: 16, right: 16, bottom: 24 }).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
