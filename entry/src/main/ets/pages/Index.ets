import { common } from '@kit.AbilityKit'
import {
  WeatherData,
  WeatherUiState,
  WeatherUiStatus,
  WeatherVisualState
} from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'
import { BundledCityBackground, BundledCityBackgrounds } from '../theme/BundledCityBackgrounds'
import { NightCityBackgrounds } from '../theme/NightCityBackgrounds'
import { AppSettings, WeatherService } from '../services/WeatherService'
import { CityBackground, CityBackgroundService } from '../services/CityBackgroundService'
import { DynamicWeatherBackground } from '../components/BreathingBackground'
import { WeatherSkeleton } from '../components/WeatherSkeleton'
import { HeroSection } from '../components/HeroSection'
import { HourlyCapsules } from '../components/HourlyCapsules'
import { WeeklyForecast } from '../components/WeeklyForecast'
import { DataGrid } from '../components/DataGrid'
import { AirQualityCard } from '../components/AirQualityCard'
import { LifeIndexGrid } from '../components/LifeIndexGrid'

import { BottomNavigation } from '../components/BottomNavigation'
import { WeatherPresentation } from '../models/WeatherPresentation'

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
  @State scrolled: boolean = false
  private requestVersion: number = 0
  private disposed: boolean = false
  private loading: boolean = false
  private scroller: Scroller = new Scroller()
  @State currentHour: number = new Date().getHours()
  @State isNight: boolean = false
  @State nightPhoto: boolean = false
  @State cityImageAspect: number = 1.5
  @State cityBackgroundResource: Resource = $r('app.media.weather_bg_day')
  @State hasBundledCityBackground: boolean = false
  @State cityBackgroundUrl: string = ''
  private service: WeatherService = WeatherService.getInstance()
  private backgroundService: CityBackgroundService = CityBackgroundService.getInstance()
  private loadedCityId: string = ''
  private backgroundKey: string = ''
  private timeTimerId: number = -1

  async aboutToAppear(): Promise<void> {
    await this.loadData(false)
    if (!this.disposed) this.startTimeObserver()
  }

  aboutToDisappear(): void {
    this.disposed = true
    this.pageActive = false
    this.requestVersion++
    if (this.timeTimerId >= 0) {
      clearInterval(this.timeTimerId)
      this.timeTimerId = -1
    }
  }

  onPageHide(): void { this.pageActive = false }

  async onPageShow(): Promise<void> {
    if (this.disposed) return
    this.pageActive = true
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    if (this.disposed || !this.pageActive) return
    const settings: AppSettings = this.service.getSettings()
    this.motionEnabled = settings.motionEnabled
    this.unit = settings.unit
    const selectedId: string = this.service.getCurrentCity().id
    if (this.loadedCityId && selectedId !== this.loadedCityId) await this.loadData(true)
    else if (this.weatherData.lastUpdate > 0) {
      this.updateScene()
      if (Date.now() - this.weatherData.lastUpdate > settings.refreshMinutes * 60000) await this.loadData(true)
    }
  }

  private async loadData(forceRefresh: boolean): Promise<void> {
    if (this.disposed) return
    if (this.loading && !forceRefresh) return
    this.loading = true
    const version: number = ++this.requestVersion
    const previous: WeatherData | undefined = this.weatherData.lastUpdate > 0 ? this.weatherData : undefined
    if (!forceRefresh && !previous) this.uiState = WeatherUiState.loading()
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      await this.service.initialize(context)
      if (this.disposed || version !== this.requestVersion) return
      const settings: AppSettings = this.service.getSettings()
      this.motionEnabled = settings.motionEnabled
      this.unit = settings.unit
      const data: WeatherData = await this.service.loadWeather(context, undefined, forceRefresh)
      if (version !== this.requestVersion) return
      this.weatherData = data
      this.updateScene(false)
      this.uiState = WeatherUiState.ready(data)
      if (this.loadedCityId !== data.cityId) {
        this.hasBundledCityBackground = false
        this.cityBackgroundUrl = ''
      }
      this.loadedCityId = data.cityId
      this.updateCityBackground(context, data.cityId)
    } catch (error) {
      if (version !== this.requestVersion) return
      this.uiState = WeatherUiState.error('天气更新失败，请检查网络后重试', previous)
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
    if (this.disposed) return
    const city = this.service.getCityList().find(item => item.id === cityId) ?? this.service.getCurrentCity()
    const key: string = `${cityId}_${this.isNight}`
    if (this.backgroundKey === key) return
    this.backgroundKey = key
    const bundled: BundledCityBackground | null = this.isNight ? NightCityBackgrounds.resolve(cityId) : BundledCityBackgrounds.resolve(cityId)
    if (bundled) {
      if (this.weatherData.cityId !== cityId) return
      this.cityBackgroundResource = bundled.resource
      this.hasBundledCityBackground = true
      this.cityBackgroundUrl = ''
      this.nightPhoto = bundled.isNightPhoto
      this.cityImageAspect = bundled.aspectRatio
      return
    }
    this.nightPhoto = false
    if (this.isNight) {
      this.hasBundledCityBackground = false
      this.cityBackgroundUrl = ''
      return
    }
    const result: CityBackground = await this.backgroundService.resolve(context, city)
    if (this.disposed || this.weatherData.cityId !== cityId || this.backgroundKey !== key) return
    this.hasBundledCityBackground = false
    this.cityBackgroundUrl = result.imageUrl
  }

  private displayTemperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private startTimeObserver(): void {
    if (this.disposed) return
    if (this.timeTimerId >= 0) clearInterval(this.timeTimerId)
    this.timeTimerId = setInterval(() => {
      if (this.disposed || !this.pageActive) return
      const settings: AppSettings = this.service.getSettings()
      if (!this.loading && Date.now() - this.weatherData.lastUpdate > settings.refreshMinutes * 60000) {
        this.loadData(true)
      }
      this.updateScene()
    }, 60000)
  }

  private dateText(): string {
    const now: Date = WeatherData.localDate(Date.now(), this.weatherData.utcOffsetSeconds)
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return `${now.getUTCMonth() + 1}月${now.getUTCDate()}日 ${weeks[now.getUTCDay()]} · ${WeatherData.localTime(Date.now(), this.weatherData.utcOffsetSeconds)}`
  }

  private updateText(): string {
    if (!this.weatherData.lastUpdate) return ''
    return `${WeatherData.localTime(this.weatherData.observedAt || this.weatherData.lastUpdate, this.weatherData.utcOffsetSeconds)} 天气 · ${WeatherData.localTime(this.weatherData.lastUpdate, this.weatherData.utcOffsetSeconds)} 更新`
  }


  private sourceLabel(): string {
    return WeatherPresentation.status(this.weatherData)
  }

  private updateScene(updateBackground: boolean = true): void {
    const scene = WeatherData.sceneAt(this.weatherData)
    this.currentHour = scene.hour
    this.isNight = scene.isNight
    this.visualState = scene.visualState
    this.themeColors = WeatherTheme.getColors(this.visualState, this.isNight)
    if (updateBackground) {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      this.updateCityBackground(context, this.weatherData.cityId)
    }
  }

  build() {
    Column() {
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
      .width('100%').layoutWeight(1).backgroundColor(this.themeColors.pageBackground)
      .onAreaChange((_old: Area, area: Area) => {
        this.sceneHeight = Math.min(700, Math.max(470, Number(area.width) * 1.55))
      })
      BottomNavigation({ selected: 'weather' })
    }.width('100%').height('100%').backgroundColor(this.themeColors.pageBackground)
  }

  @Builder
  skeletonBuilder() {
    WeatherSkeleton()
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
            isNight: this.isNight, nightPhoto: this.nightPhoto, cityImageAspect: this.cityImageAspect,
            motionEnabled: this.motionEnabled, active: this.pageActive && this.sceneVisible,
            themeColors: this.themeColors, cityBackgroundResource: this.cityBackgroundResource,
            hasBundledCityBackground: this.hasBundledCityBackground, cityBackgroundUrl: this.cityBackgroundUrl
          }).height(this.sceneHeight)
          Column() {
            this.topBar()
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
              HourlyCapsules({ hourly: this.weatherData.hourly, themeColors: this.themeColors, unit: this.unit,
                currentNight: this.isNight })
              WeeklyForecast({ daily: this.weatherData.daily, themeColors: this.themeColors, unit: this.unit })
              AirQualityCard({ air: this.weatherData.air, current: this.weatherData.current,
                unit: this.unit, themeColors: this.themeColors })
              LifeIndexGrid({ lifeIndex: this.weatherData.lifeIndex, themeColors: this.themeColors })
              Text('天气详情').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.themeColors.textColor)
                .alignSelf(ItemAlign.Start).margin({ top: 24, bottom: 16 })
              DataGrid({ current: this.weatherData.current, themeColors: this.themeColors, unit: this.unit })
              Column({ space: 6 }) {
                Text(this.updateText()).fontSize(11).fontColor(this.themeColors.textSecondary)
                Button('关于与数据来源', { type: ButtonType.Normal }).height(44).fontSize(11)
                  .fontColor(this.themeColors.textTertiary).backgroundColor(Color.Transparent)
                  .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/About' }))
              }.width('100%').margin({ top: 24, bottom: 16 })
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
        .onClick(() => this.getUIContext().getRouter().replaceUrl({ url: 'pages/Settings' }))
      }.width('100%')
      Row() {
        Text(this.dateText()).fontSize(12).fontColor(this.themeColors.textSecondary)
        Blank()
        if (this.sourceLabel()) {
          Text(this.sourceLabel()).fontSize(10)
            .fontColor(this.weatherData.source === 'mock' ? '#FFE1B0' : '#C7E8F0')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8)
            .backgroundColor('rgba(0,22,43,0.28)')
        }
      }.width('100%')
    }
    .width('100%').padding({ left: 26, right: 18, top: 42, bottom: 10 })
  }
}
