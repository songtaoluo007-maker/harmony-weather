import { common } from '@kit.AbilityKit'
import { AppSettings, WeatherService } from '../services/WeatherService'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct SettingsPage {
  @State unit: string = 'c'
  @State motionEnabled: boolean = true
  @State refreshMinutes: number = 30
  @State configured: boolean = false
  @State provider: string = 'mock'
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    this.restoreSettings()
    this.configured = this.service.hasLiveConfiguration()
    this.provider = this.service.getProvider()
  }

  private restoreSettings(): void {
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
    if (!await this.service.saveSettings(context, value)) {
      this.restoreSettings()
      this.getUIContext().showAlertDialog({ title: '设置未能保存', message: '请稍后重试。',
        confirm: { value: '知道了', action: () => {} } })
    }
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.chevron_left')).width(23).height(23).fillColor(T.text)
        }.width(T.touch).height(T.touch).backgroundColor(Color.Transparent)
          .onClick(() => this.getUIContext().getRouter().back()).accessibilityText('返回天气')
        Text('设置').fontSize(22).fontWeight(FontWeight.Medium).fontColor(T.text)
      }.width('100%').padding({ left: 12, right: 24, top: 42, bottom: 24 })

      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 6 }) {
            Text('让天气，合你心意').fontSize(26).fontWeight(300).fontColor(T.text)
            Text('调整显示与动态体验').fontSize(13).fontColor(T.muted)
          }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 16 })

          Column({ space: 18 }) {
            this.sectionTitle($r('app.media.thermometer'), '温度单位')
            Row({ space: 6 }) {
              this.unitOption('摄氏度 °C', 'c')
              this.unitOption('华氏度 °F', 'f')
            }.width('100%').padding(4).backgroundColor(T.page).borderRadius(16)
          }.width('100%').padding(20).backgroundColor(T.surface).borderRadius(T.radius)

          Column({ space: 18 }) {
            Row() {
              Column({ space: 6 }) {
                Text('动态天气').fontSize(16).fontWeight(FontWeight.Medium).fontColor(T.text)
                Text('流动的云、飘落的雪、远雨与窗上水滴').fontSize(12).fontColor(T.muted).lineHeight(18)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ right: 12 })
              Toggle({ type: ToggleType.Switch, isOn: this.motionEnabled }).selectedColor(T.accent)
                .onChange((value: boolean) => { this.motionEnabled = value; this.save() })
                .accessibilityText('动态天气开关')
            }.width('100%')
            Divider().color(T.border).strokeWidth(0.5)
            Text('预览天气场景').fontSize(12).fontColor(T.muted).alignSelf(ItemAlign.Start)
            Flex({ wrap: FlexWrap.Wrap }) {
              this.previewButton('晴昼', 'clear_day', $r('app.media.weather_sunny'))
              this.previewButton('晴夜', 'clear_night', $r('app.media.weather_night'))
              this.previewButton('白天雨', 'rain_day', $r('app.media.weather_rainy'))
              this.previewButton('夜间雨', 'rain_night', $r('app.media.weather_rainy'))
              this.previewButton('雾天', 'haze', $r('app.media.weather_fog'))
              this.previewButton('雪天', 'snow', $r('app.media.weather_snowy'))
            }.width('100%')
            Text('仅预览背景，不改变天气数据。').fontSize(11).fontColor(T.muted).alignSelf(ItemAlign.Start)
          }.width('100%').padding(20).backgroundColor(T.surface).borderRadius(T.radius)

          Column({ space: 18 }) {
            this.sectionTitle($r('app.media.refresh'), '更新频率')
            Row({ space: 6 }) {
              this.refreshButton(15)
              this.refreshButton(30)
              this.refreshButton(60)
            }.width('100%')
            Text('使用应用时自动更新，也可在首页下拉刷新。')
              .fontSize(11).fontColor(T.muted).lineHeight(18).alignSelf(ItemAlign.Start)
          }.width('100%').padding(20).backgroundColor(T.surface).borderRadius(T.radius)

          Column({ space: 12 }) {
            this.sectionTitle($r('app.media.information_outline'), '天气数据')
            Text(this.provider === 'openmeteo' ? 'Open-Meteo · 免费在线天气' : this.configured ? '和风天气服务已配置' : this.provider === 'mock' ? '当前为演示模式' : '和风配置不完整')
              .fontSize(14).fontColor(this.configured ? T.accent : '#EAD08A').alignSelf(ItemAlign.Start)
            Text(this.provider === 'openmeteo' ? '无需密钥，适用于非商业用途。天气和当地昼夜自动驱动背景；更新失败仅使用同来源历史缓存。' : this.configured ?
              '更新失败时会标记离线数据。预报时长与可用指标取决于天气服务。' : this.provider === 'mock' ?
              '示例天气用于体验界面，不代表当地实况。' : '请配置和风 API Key 与专属 API Host，或将 provider 改为 openmeteo。不会自动使用模拟数据。')
              .fontSize(12).fontColor(T.muted).lineHeight(20)
          }.width('100%').padding(20).backgroundColor(T.surface).borderRadius(T.radius)

          Text('城市天气 · 感知每一天').fontSize(11).fontColor(T.muted).margin({ top: 18, bottom: 16 })
        }.width('100%').padding({ left: 24, right: 24, bottom: 30 })
      }.layoutWeight(1).scrollBar(BarState.Off).width('100%')
    }.width('100%').height('100%').backgroundColor(T.page)
  }

  @Builder
  sectionTitle(icon: Resource, title: string) {
    Row({ space: 10 }) {
      Image(icon).width(19).height(19).fillColor(T.accent)
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(T.text)
    }.width('100%')
  }

  @Builder
  unitOption(label: string, value: string) {
    Button(label, { type: ButtonType.Normal }).fontSize(13)
      .fontColor(this.unit === value ? T.page : T.muted)
      .backgroundColor(this.unit === value ? T.accent : Color.Transparent)
      .height(44).layoutWeight(1).borderRadius(12)
      .onClick(() => { this.unit = value; this.save() })
      .accessibilityText(`${label}，${this.unit === value ? '已选择' : '未选择'}`)
  }

  @Builder
  previewButton(label: string, value: string, icon: Resource) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 8 }) {
        Image(icon).width(22).height(22).fillColor(T.accent)
        Text(label).fontSize(12).fontColor(T.text)
      }.padding({ top: 12, bottom: 12 })
    }.width('33.33%').backgroundColor(Color.Transparent).borderRadius(12)
      .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Index', params: { previewWeather: value } }))
      .accessibilityText(`预览${label}背景`)
  }

  @Builder
  refreshButton(minutes: number) {
    Button(`${minutes}分钟`, { type: ButtonType.Normal }).fontSize(12)
      .fontColor(this.refreshMinutes === minutes ? T.page : T.text)
      .backgroundColor(this.refreshMinutes === minutes ? T.accent : T.selected)
      .height(44).layoutWeight(1).borderRadius(12)
      .onClick(() => { this.refreshMinutes = minutes; this.save() })
      .accessibilityText(`每${minutes}分钟更新，${this.refreshMinutes === minutes ? '已选择' : '未选择'}`)
  }
}
