import { bundleManager, common } from '@kit.AbilityKit'
import { CityInfo } from '../models/WeatherModels'
import { WeatherService } from '../services/WeatherService'
import { NightCityBackgrounds } from '../theme/NightCityBackgrounds'
import { PageHeader } from '../components/PageHeader'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct About {
  @State version: string = ''
  @State provider: string = ''
  @State cities: CityInfo[] = []
  @State selectedCity: string = ''
  @State allCredits: boolean = false

  async aboutToAppear(): Promise<void> {
    const service: WeatherService = WeatherService.getInstance()
    await service.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext)
    this.provider = service.getProvider()
    this.cities = service.getCityList()
    this.selectedCity = service.getCurrentCity().id
    try { this.version = (await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)).versionName }
    catch (error) { this.version = '' }
  }

  @Builder
  paragraph(title: string, body: string) {
    Column({ space: 9 }) {
      Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor(T.text)
      Text(body).fontSize(12).fontColor(T.muted).lineHeight(21)
    }.width('100%').alignItems(HorizontalAlign.Start).margin({ top: 24, bottom: 10 })
  }

  @Builder
  sourceLink(url: string, label: string) {
    Button(label, { type: ButtonType.Normal }).fontSize(12).fontColor(T.accent)
      .backgroundColor(Color.Transparent).constraintSize({ minHeight: 44 }).alignSelf(ItemAlign.Start)
      .onClick(() => this.openSource(url)).accessibilityText(`${label}，打开原网站`)
  }

  private async openSource(url: string): Promise<void> {
    try { await (this.getUIContext().getHostContext() as common.UIAbilityContext).openLink(url) }
    catch (error) {
      this.getUIContext().showAlertDialog({ title: '无法打开链接', message: '请检查网络或浏览器设置后重试。',
        confirm: { value: '知道了', action: () => {} } })
    }
  }

  @Builder
  photoCredit(city: CityInfo) {
    Column({ space: 7 }) {
      Text(city.name).fontSize(14).fontColor(T.text).fontWeight(FontWeight.Medium)
      this.sourceLink(`https://zh.wikipedia.org/wiki/${encodeURIComponent(city.name + '市')}`, '日景 · 维基百科原页面')
      if (NightCityBackgrounds.resolve(city.id)) {
        Text('夜景 · ' + NightCityBackgrounds.resolve(city.id)!.attribution).fontSize(12).fontColor(T.muted).lineHeight(20)
        this.sourceLink(NightCityBackgrounds.resolve(city.id)!.sourceUrl, '照片原始来源')
        if (NightCityBackgrounds.resolve(city.id)!.licenseUrl) {
          this.sourceLink(NightCityBackgrounds.resolve(city.id)!.licenseUrl, '使用许可')
        }
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(16).backgroundColor(T.surface).borderRadius(16).margin({ top: 10 })
  }

  build() {
    Column() {
      PageHeader({ heading: '关于' })
      Scroll() {
        Column() {
          Image($r('app.media.meteo_partly_cloudy_day')).width(80).height(80).objectFit(ImageFit.Contain)
          Text('原境天气').fontSize(25).fontWeight(FontWeight.Medium).fontColor(T.text).margin({ top: 8 })
          if (this.version) Text('版本 ' + this.version).fontSize(12).fontColor(T.muted).margin({ top: 6, bottom: 12 })
          this.paragraph('天气数据', this.provider === 'qweather' ? '天气数据由和风天气提供。具体指标以服务返回为准。' :
            this.provider === 'mock' ? '当前使用示例天气，不代表当地实况。' :
            '天气由 Open-Meteo 提供，空气质量来自 CAMS 模型，采用美国 AQI 标准。当前值为气象模型估算，不等同于中国站点实测。')
          if (this.provider === 'openmeteo') {
            this.sourceLink('https://open-meteo.com/', 'Open-Meteo')
            this.sourceLink('https://atmosphere.copernicus.eu/', 'Copernicus CAMS')
            this.sourceLink('https://creativecommons.org/licenses/by/4.0/', '天气数据许可 · CC BY 4.0')
          }
          if (this.provider === 'qweather') {
            this.sourceLink('https://www.qweather.com/', '和风天气')
          }
          this.paragraph('指标说明', '温度取整、能见度与 CO 换算单位，时间转换为城市当地时间。夜间预报按日落至次日日出的逐小时数据汇总。生活提示为本地规则参考，不是官方生活指数或个人健康评估。')
          this.paragraph('城市影像', '照片为城市风景资料，并非实时摄像头。显示中进行裁切、亮度调整并叠加天气动效；原照片保留各自许可。')
          ForEach(this.cities.filter((city: CityInfo) => this.allCredits || city.id === this.selectedCity), (city: CityInfo) => {
            this.photoCredit(city)
          }, (city: CityInfo) => city.id)
          Button(this.allCredits ? '收起其他城市' : '查看全部城市影像', { type: ButtonType.Normal })
            .width('100%').height(48).borderRadius(14).fontSize(13).fontColor(T.accent).backgroundColor(T.surface)
            .margin({ top: 12 }).onClick(() => { this.allCredits = !this.allCredits })
          this.paragraph('图标与插画', '天气图标：Bas Milius / Meteocons，MIT 许可。界面图标：Material Design Icons，Apache 2.0 许可。新闻线性图标、通用天气背景及生活插画为本项目原创素材。')
          this.sourceLink('https://github.com/basmilius/meteocons', 'Meteocons · 来源与许可')
          this.sourceLink('https://github.com/Templarian/MaterialDesign', 'Material Design Icons · 来源与许可')
          this.paragraph('天气资讯', '资讯通过官方网页在线阅读，内容及版权属于原发布方；本应用不转载文章。')
        }.width('100%').padding({ left: 24, right: 24, bottom: 40 })
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
