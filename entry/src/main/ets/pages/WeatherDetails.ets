import { DailyWeather, WeatherData } from '../models/WeatherModels'
import { WeatherService } from '../services/WeatherService'
import { WeatherIcon } from '../components/WeatherIcon'

@Entry
@Component
struct WeatherDetails {
  @State data: WeatherData = new WeatherData()
  @State unit: string = 'c'
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
    return parts.length === 3 ? `${Number(parts[1])}月${Number(parts[2])}日` : value
  }

  private barOffset(item: DailyWeather): number {
    let min: number = 100
    let max: number = -100
    this.data.daily.forEach((day: DailyWeather) => {
      min = Math.min(min, day.low)
      max = Math.max(max, day.high)
    })
    return max === min ? 0 : (item.low - min) / (max - min) * 54
  }

  private barWidth(item: DailyWeather): number {
    let min: number = 100
    let max: number = -100
    this.data.daily.forEach((day: DailyWeather) => {
      min = Math.min(min, day.low)
      max = Math.max(max, day.high)
    })
    return max === min ? 60 : Math.max(24, (item.high - item.low) / (max - min) * 72)
  }

  build() {
    Stack() {
      Image($r('app.media.weather_bg_day'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(4,48,82,0.62)')

      Column() {
        Row() {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.chevron_left'))
              .width(22)
              .height(22)
              .fillColor('#FFFFFF')
          }
          .width(44)
          .height(44)
          .backgroundColor('rgba(255,255,255,0.14)')
          .accessibilityText('返回')
          .onClick(() => this.getUIContext().getRouter().back())
          Column() {
            Text('15日天气')
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text(this.data.city)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.58)')
              .margin({ top: 3 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 14 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 44, bottom: 18 })

        List({ space: 8 }) {
          ForEach(this.data.daily, (item: DailyWeather, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Text(index === 0 ? '今天' : item.week)
                    .fontSize(16)
                    .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Normal)
                    .fontColor('#FFFFFF')
                  Text(this.dateLabel(item.date))
                    .fontSize(11)
                    .fontColor('rgba(255,255,255,0.52)')
                    .margin({ top: 4 })
                }
                .width(70)
                .alignItems(HorizontalAlign.Start)

                WeatherIcon({ text: item.textDay, iconSize: 30, fallbackColor: '#FFFFFF' })
                Text(`${this.temperature(item.low)}°`)
                  .fontSize(14)
                  .fontColor('rgba(255,255,255,0.66)')
                  .width(38)
                  .textAlign(TextAlign.End)
                  .margin({ left: 10 })

                Stack() {
                  Row()
                    .width('100%')
                    .height(3)
                    .borderRadius(2)
                    .backgroundColor('rgba(255,255,255,0.14)')
                  Row()
                    .width(this.barWidth(item))
                    .height(4)
                    .borderRadius(2)
                    .linearGradient({ direction: GradientDirection.Right, colors: [['#62D2FF', 0], ['#FFB63D', 1]] })
                    .margin({ left: this.barOffset(item) })
                }
                .layoutWeight(1)
                .margin({ left: 8, right: 8 })

                Text(`${this.temperature(item.high)}°`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                  .width(38)
              }
              .width('100%')
              .height(70)
              .padding({ left: 16, right: 16 })
              .borderRadius(20)
              .backgroundColor(index === 0 ? 'rgba(98,210,255,0.18)' : 'rgba(255,255,255,0.10)')
              .accessibilityText(`${index === 0 ? '今天' : item.week}${item.textDay}最高${item.high}度最低${item.low}度`)
            }
          }, (item: DailyWeather, index: number) => `${index}_${item.date}`)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 22 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
  }
}
