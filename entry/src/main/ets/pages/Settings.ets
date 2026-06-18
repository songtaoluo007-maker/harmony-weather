import { common } from '@kit.AbilityKit'
import { AppSettings, WeatherService } from '../services/WeatherService'

@Entry
@Component
struct SettingsPage {
  @State unit: string = 'c'
  @State motionEnabled: boolean = true
  @State refreshMinutes: number = 30
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    const settings: AppSettings = this.service.getSettings()
    this.unit = settings.unit
    this.motionEnabled = settings.motionEnabled
    this.refreshMinutes = settings.refreshMinutes
  }

  private async save(): Promise<void> {
    const value: AppSettings = new AppSettings()
    value.unit = this.unit
    value.motionEnabled = this.motionEnabled
    value.refreshMinutes = this.refreshMinutes
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.saveSettings(context, value)
  }

  build() {
    Stack() {
      Image($r('app.media.weather_bg_night'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(3,18,48,0.68)')

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
          Text('天气设置')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ left: 14 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 44, bottom: 26 })

        Scroll() {
          Column({ space: 16 }) {
            this.unitSection()
            this.motionSection()
            this.refreshSection()

            Column() {
              Text('数据与隐私')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .alignSelf(ItemAlign.Start)
              Text('天气数据由和风天气提供。开发环境密钥存放在本地忽略文件中，不提交到代码仓库。生产版本建议通过服务端代理访问。')
                .fontSize(13)
                .lineHeight(21)
                .fontColor('rgba(255,255,255,0.62)')
                .margin({ top: 12 })
            }
            .width('100%')
            .padding(20)
            .borderRadius(24)
            .backgroundColor('rgba(255,255,255,0.11)')
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 30 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  unitSection() {
    Column() {
      Text('温度单位')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .alignSelf(ItemAlign.Start)
      Row({ space: 10 }) {
        this.optionButton('摄氏度 °C', 'c', this.unit === 'c')
        this.optionButton('华氏度 °F', 'f', this.unit === 'f')
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor('rgba(255,255,255,0.11)')
  }

  @Builder
  optionButton(label: string, value: string, selected: boolean) {
    Text(label)
      .fontSize(14)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(selected ? '#082F52' : '#FFFFFF')
      .textAlign(TextAlign.Center)
      .height(44)
      .layoutWeight(1)
      .borderRadius(22)
      .backgroundColor(selected ? '#8CDEFF' : 'rgba(255,255,255,0.10)')
      .onClick(() => {
        this.unit = value
        this.save()
      })
      .accessibilityText(`${label}${selected ? '已选择' : ''}`)
  }

  @Builder
  motionSection() {
    Row() {
      Column() {
        Text('动态天气背景')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        Text('根据当地天气、昼夜和日出日落自动切换')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.56)')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.motionEnabled })
        .selectedColor('#62D2FF')
        .onChange((value: boolean) => {
          this.motionEnabled = value
          this.save()
        })
        .accessibilityText('动态天气背景开关')
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor('rgba(255,255,255,0.11)')
  }

  @Builder
  refreshSection() {
    Column() {
      Text('自动更新频率')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .alignSelf(ItemAlign.Start)
      Row({ space: 8 }) {
        this.refreshButton(15)
        this.refreshButton(30)
        this.refreshButton(60)
      }
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(20)
    .borderRadius(24)
    .backgroundColor('rgba(255,255,255,0.11)')
  }

  @Builder
  refreshButton(minutes: number) {
    Text(`${minutes}分钟`)
      .fontSize(13)
      .fontColor(this.refreshMinutes === minutes ? '#082F52' : '#FFFFFF')
      .textAlign(TextAlign.Center)
      .height(42)
      .layoutWeight(1)
      .borderRadius(21)
      .backgroundColor(this.refreshMinutes === minutes ? '#8CDEFF' : 'rgba(255,255,255,0.10)')
      .onClick(() => {
        this.refreshMinutes = minutes
        this.save()
      })
      .accessibilityText(`每${minutes}分钟更新${this.refreshMinutes === minutes ? '已选择' : ''}`)
  }
}
