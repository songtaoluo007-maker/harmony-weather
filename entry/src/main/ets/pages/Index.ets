import { common } from '@kit.AbilityKit'
import {
  WeatherData,
  WeatherUiState,
  WeatherUiStatus,
  WeatherVisualState
} from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'
import { BundledCityBackground, BundledCityBackgrounds } from '../theme/BundledCityBackgrounds'
import { AppSettings, WeatherService } from '../services/WeatherService'
import { CityBackground, CityBackgroundService } from '../services/CityBackgroundService'
import { DynamicWeatherBackground } from '../components/BreathingBackground'
import { HeroSection } from '../components/HeroSection'
import { HourlyCapsules } from '../components/HourlyCapsules'
import { WeeklyForecast } from '../components/WeeklyForecast'
import { DataGrid } from '../components/DataGrid'
import { AirQualityCard } from '../components/AirQualityCard'
import { LifeIndexGrid } from '../components/LifeIndexGrid'

interface WeatherPreviewParams { previewWeather?: string }

@Entry
@Component
struct Index {
  @State uiState: WeatherUiState = new WeatherUiState()
  @State weatherData: WeatherData = new WeatherData()
  @State visualState: WeatherVisualState = WeatherVisualState.CLEAR_DAY
  @State themeColors: ThemeColors = new ThemeColors()
  @State refreshing: boolean = false
  @State motionEnabled: boolean = true
  @State unit: string = 'c'
  @State pageActive: boolean = true
  @State sceneVisible: boolean = true
  @State sceneHeight: number = 620
  @State previewWeather: string = ''
  @State scrolled: boolean = false
  private requestVersion: number = 0
  private loading: boolean = false
  private scroller: Scroller = new Scroller()
  @State currentHour: number = new Date().getHours()
  @State cityBackgroundResource: Resource = $r('app.media.weather_bg_day')
  @State hasBundledCityBackground: boolean = false
  @State cityBackgroundUrl: string = ''
  @State cityBackgroundAttribution: string = ''
  private service: WeatherService = WeatherService.getInstance()
  private backgroundService: CityBackgroundService = CityBackgroundService.getInstance()
  private loadedCityId: string = ''
  private timeTimerId: number = -1

  async aboutToAppear(): Promise<void> {
    const params: WeatherPreviewParams = this.getUIContext().getRouter().getParams() as WeatherPreviewParams
    this.previewWeather = params?.previewWeather ?? ''
    await this.loadData(false)
    this.startTimeObserver()
  }

  aboutToDisappear(): void {
    if (this.timeTimerId >= 0) {
      clearInterval(this.timeTimerId)
      this.timeTimerId = -1
    }
  }

  onPageHide(): void { this.pageActive = false }

  async onPageShow(): Promise<void> {
    this.pageActive = true
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    const settings: AppSettings = this.service.getSettings()
    this.motionEnabled = settings.motionEnabled
    this.unit = settings.unit
    const selectedId: string = this.service.getCurrentCity().id
    if (this.loadedCityId && selectedId !== this.loadedCityId) await this.loadData(true)
  }

  private async loadData(forceRefresh: boolean): Promise<void> {
    if (this.loading && !forceRefresh) return
    this.loading = true
    const version: number = ++this.requestVersion
    const previous: WeatherData | undefined = this.weatherData.lastUpdate > 0 ? this.weatherData : undefined
    if (!forceRefresh && !previous) this.uiState = WeatherUiState.loading()
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      await this.service.initialize(context)
      const settings: AppSettings = this.service.getSettings()
      this.motionEnabled = settings.motionEnabled
      this.unit = settings.unit
      const data: WeatherData = await this.service.loadWeather(context, undefined, forceRefresh)
      if (version !== this.requestVersion) return
      this.weatherData = data
      this.currentHour = new Date().getHours() + new Date().getMinutes() / 60
      this.visualState = WeatherData.resolveVisualState(
        data.current.text,
        this.currentHour,
        data.current.sunrise,
        data.current.sunset
      )
      this.themeColors = WeatherTheme.getColors(this.visualState)
      this.applyPreview()
      this.uiState = WeatherUiState.ready(data)
      if (this.loadedCityId !== data.cityId) {
        this.hasBundledCityBackground = false
        this.cityBackgroundUrl = ''
        this.cityBackgroundAttribution = ''
      }
      this.loadedCityId = data.cityId
      this.updateCityBackground(context, data.cityId)
    } catch (error) {
      if (version !== this.requestVersion) return
      this.uiState = WeatherUiState.error('天气更新失败，请检查网络或天气服务配置后重试', previous)
    } finally {
      if (version === this.requestVersion) {
        this.refreshing = false
        this.loading = false
      }
    }
  }

  private async updateCityBackground(
    context: common.UIAbilityContext,
    cityId: string
  ): Promise<void> {
    const city = this.service.getCityList().find(item => item.id === cityId) ?? this.service.getCurrentCity()
    const bundled: BundledCityBackground | null = BundledCityBackgrounds.resolve(cityId)
    if (bundled) {
      if (this.weatherData.cityId !== cityId) return
      this.cityBackgroundResource = bundled.resource
      this.hasBundledCityBackground = true
      this.cityBackgroundUrl = ''
      this.cityBackgroundAttribution = bundled.attribution
      return
    }
    const result: CityBackground = await this.backgroundService.resolve(context, city)
    if (this.weatherData.cityId !== cityId) return
    this.hasBundledCityBackground = false
    this.cityBackgroundUrl = result.imageUrl
    this.cityBackgroundAttribution = result.attribution
  }

  private displayTemperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private startTimeObserver(): void {
    if (this.timeTimerId >= 0) clearInterval(this.timeTimerId)
    this.timeTimerId = setInterval(() => {
      if (!this.pageActive) return
      const settings: AppSettings = this.service.getSettings()
      if (!this.loading && Date.now() - this.weatherData.lastUpdate > settings.refreshMinutes * 60000) {
        this.loadData(true)
      }
      const hour: number = new Date().getHours() + new Date().getMinutes() / 60
      if (hour !== this.currentHour) {
        this.currentHour = hour
        this.visualState = WeatherData.resolveVisualState(
          this.weatherData.current.text,
          hour,
          this.weatherData.current.sunrise,
          this.weatherData.current.sunset
        )
        this.themeColors = WeatherTheme.getColors(this.visualState)
        this.applyPreview()
      }
    }, 60000)
  }

  private dateText(): string {
    const now: Date = new Date()
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return `${now.getMonth() + 1}月${now.getDate()}日 ${weeks[now.getDay()]}`
  }

  private updateText(): string {
    if (!this.weatherData.lastUpdate) return ''
    const date: Date = new Date(this.weatherData.lastUpdate)
    const minute: string = date.getMinutes().toString().padStart(2, '0')
    return `${date.getHours()}:${minute} 更新`
  }


  private sourceLabel(): string {
    if (this.weatherData.source === 'mock') return '演示天气'
    if (this.weatherData.isOffline) return '离线缓存'
    if (this.weatherData.source === 'qweather') return '和风天气'
    return '历史数据'
  }

  private applyPreview(): void {
    if (!this.previewWeather) return
    if (this.previewWeather === 'clear_day') { this.visualState = WeatherVisualState.CLEAR_DAY; this.currentHour = 12 }
    if (this.previewWeather === 'clear_night') { this.visualState = WeatherVisualState.CLEAR_NIGHT; this.currentHour = 22 }
    if (this.previewWeather === 'rain') this.visualState = WeatherVisualState.RAIN
    if (this.previewWeather === 'haze') this.visualState = WeatherVisualState.HAZE
    this.themeColors = WeatherTheme.getColors(this.visualState)
  }

  private sourceDetail(): string {
    if (this.weatherData.source === 'mock') return '当前展示示例天气，非当地实况。'
    if (this.weatherData.isOffline) return '暂时无法更新，显示上次保存的天气。'
    return this.updateText()
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.uiState.status === WeatherUiStatus.LOADING && this.weatherData.lastUpdate === 0) {
        this.skeletonBuilder()
      } else if (this.uiState.status === WeatherUiStatus.ERROR) {
        this.errorBuilder()
      } else {
        this.contentBuilder()
      }
      if (this.scrolled) {
        Column().width('100%').height(38).backgroundColor(this.themeColors.pageBackground)
          .hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
      }
    }
    .width('100%').height('100%').backgroundColor(this.themeColors.pageBackground)
    .onAreaChange((_old: Area, area: Area) => {
      this.sceneHeight = Math.min(700, Math.max(470, Number(area.width) * 1.55))
    })
  }

  @Builder
  skeletonBuilder() {
    Column({ space: 18 }) {
      LoadingProgress().width(36).height(36).color('#AADCE9')
      Text('正在寻找这座城市的天气').fontSize(15).fontColor('#D5E1E9')
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  errorBuilder() {
    Column({ space: 14 }) {
      Image($r('app.media.weather_cloudy')).width(60).height(60).fillColor('#AADCE9')
      Text('天气暂时失联').fontSize(24).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
      Text(this.uiState.message).fontSize(14).fontColor('#B9CAD6').textAlign(TextAlign.Center).lineHeight(22)
      Button('再试一次').height(48).padding({ left: 32, right: 32 })
        .fontColor('#102D40').backgroundColor('#AADCE9').borderRadius(24)
        .margin({ top: 12 }).onClick(() => this.loadData(true))
      Button('切换城市').height(44).backgroundColor(Color.Transparent).fontColor('#D5E1E9')
        .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))
    }
    .width('100%').height('100%').padding(32).justifyContent(FlexAlign.Center)
  }

  @Builder
  contentBuilder() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll(this.scroller) {
        Stack({ alignContent: Alignment.Top }) {
          DynamicWeatherBackground({
            visualState: this.visualState, hour: this.currentHour,
            motionEnabled: this.motionEnabled, active: this.pageActive && this.sceneVisible,
            themeColors: this.themeColors, cityBackgroundResource: this.cityBackgroundResource,
            hasBundledCityBackground: this.hasBundledCityBackground, cityBackgroundUrl: this.cityBackgroundUrl
          }).height(this.sceneHeight)
          Column() {
            this.topBar()
            if (this.previewWeather) {
              Row() {
                Text('背景预览 · 天气数据未更改').fontSize(11).fontColor('#FFFFFF').layoutWeight(1)
                Button('退出预览').height(44).fontSize(12).fontColor('#AADCE9')
                  .backgroundColor(Color.Transparent).onClick(() => this.getUIContext().getRouter().back())
              }.width('100%').padding({ left: 24, right: 18 }).backgroundColor('rgba(0,20,40,0.40)')
            }
            HeroSection({
              current: this.weatherData.current,
              displayTemp: this.displayTemperature(this.weatherData.current.temp),
              displayFeels: this.displayTemperature(this.weatherData.current.feelsLike),
              displayHigh: this.displayTemperature(this.weatherData.current.high),
              displayLow: this.displayTemperature(this.weatherData.current.low),
              themeColors: this.themeColors
            })
            if (this.weatherData.alerts.length > 0) {
              this.alertBanner()
            }
            Column().height(56).width('100%').accessibilityLevel('no')
            Column() {
              HourlyCapsules({ hourly: this.weatherData.hourly, themeColors: this.themeColors, unit: this.unit })
              WeeklyForecast({ daily: this.weatherData.daily, themeColors: this.themeColors, unit: this.unit })
              AirQualityCard({ air: this.weatherData.air, current: this.weatherData.current,
                unit: this.unit, themeColors: this.themeColors })
              LifeIndexGrid({ lifeIndex: this.weatherData.lifeIndex, themeColors: this.themeColors })
              Text('天气详情').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
                .alignSelf(ItemAlign.Start).margin({ top: 24, bottom: 16 })
              DataGrid({ current: this.weatherData.current, themeColors: this.themeColors, unit: this.unit })
              Column({ space: 6 }) {
                Text(this.sourceDetail()).fontSize(11).fontColor(this.themeColors.textSecondary)
                Text(this.weatherData.source === 'qweather' ? '天气数据由和风天气提供' : this.sourceLabel())
                  .fontSize(10).fontColor(this.themeColors.textTertiary)
                if (this.cityBackgroundAttribution) {
                  Text(this.cityBackgroundAttribution).fontSize(10).fontColor(this.themeColors.textTertiary)
                    .textAlign(TextAlign.Center)
                }
              }.width('100%').margin({ top: 28, bottom: 44 })
            }
            .width('100%').padding({ left: 24, right: 24 })
          }.width('100%')
        }.width('100%')
      }
      .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring).width('100%').height('100%')
      .onDidScroll(() => {
        // Stop expensive scene work once it has scrolled off screen.
        this.sceneVisible = this.scroller.currentOffset().yOffset < this.sceneHeight
        this.scrolled = this.scroller.currentOffset().yOffset > 16
      })
    }
    .width('100%').height('100%')
    .onRefreshing(() => { this.refreshing = true; this.loadData(true) })
  }

  @Builder
  alertBanner() {
    Row() {
      Row({ space: 6 }) {
        Image($r('app.media.alert')).width(14).height(14).fillColor('#FFE0B9')
        Text(this.weatherData.alerts[0].title).fontSize(11).fontColor('#FFF0DC')
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).constraintSize({ maxWidth: 225 })
        Image($r('app.media.chevron_right')).width(12).height(12).fillColor('#FFE0B9')
      }.padding({ left: 10, right: 8, top: 6, bottom: 6 }).borderRadius(16)
        .backgroundColor('rgba(111,61,36,0.62)')
    }
    .width('100%').constraintSize({ minHeight: 44 }).padding({ left: 24, right: 24 })
    .onClick(() => this.getUIContext().showAlertDialog({
      title: this.weatherData.alerts[0].title, message: this.weatherData.alerts[0].detail,
      confirm: { value: '知道了', action: () => {} }
    }))
    .accessibilityText(`${this.weatherData.alerts[0].title}，点击查看预警详情`)
  }

  @Builder
  topBar() {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 6 }) {
          Text(this.weatherData.city).fontSize(23).fontWeight(FontWeight.Medium)
            .fontColor(this.themeColors.textColor).maxLines(1)
          Image($r('app.media.chevron_right')).width(17).height(17)
            .fillColor(this.themeColors.textSecondary).rotate({ angle: 90 })
        }
        .constraintSize({ minHeight: 44 }).layoutWeight(1)
        .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))
        .accessibilityText(`当前城市${this.weatherData.city}，点击切换城市`)
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.plus')).width(22).height(22).fillColor(this.themeColors.textColor)
        }
        .width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('城市管理')
        .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.cog')).width(22).height(22).fillColor(this.themeColors.textColor)
        }
        .width(44).height(44).backgroundColor(Color.Transparent).margin({ left: 4 }).accessibilityText('天气设置')
        .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Settings' }))
      }.width('100%')
      Row() {
        Text(this.dateText()).fontSize(12).fontColor(this.themeColors.textSecondary)
        Blank()
        Text(this.sourceLabel()).fontSize(10)
          .fontColor(this.weatherData.source === 'mock' ? '#FFE1B0' : '#C7E8F0')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8)
          .backgroundColor('rgba(0,22,43,0.28)')
          .onClick(() => this.getUIContext().showAlertDialog({
            title: this.sourceLabel(), message: this.sourceDetail(),
            confirm: { value: '知道了', action: () => {} }
          }))
      }.width('100%')
    }
    .width('100%').padding({ left: 26, right: 18, top: 42, bottom: 10 })
  }
}
